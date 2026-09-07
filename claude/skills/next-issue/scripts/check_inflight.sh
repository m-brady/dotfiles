#!/usr/bin/env bash
# Cross-reference the OPEN issue backlog against work that has already started or
# already landed, for the next-issue skill.
#
# Why this exists: a backlog lies in two directions. An issue may already have a PR
# open against it — recommending it sends you to redo work that is already in flight.
# And an issue may already be fixed but never closed — recommending it wastes a
# session, while *closing* it is a free win. Neither is visible from `gh issue list`
# alone, and reconstructing it by hand costs several round-trips every run.
#
# Only issues that are currently OPEN are reported; a closed issue needs no comment.
#
# Two signals, deliberately kept apart because they carry very different weight:
#
#   linkedPRs   — GitHub's own resolved closing links (`closedByPullRequestsReferences`).
#                 A PR is formally committed to closing this issue. Authoritative.
#
#   references  — issue numbers appearing in PR/commit *text*. A lead, never a verdict.
#                 Prose lies about intent in both directions: "would also close #1443"
#                 describes work explicitly NOT done, and plenty of real fixes never
#                 name the issue at all. Each item carries `closingLanguage` so you can
#                 see whether a closing keyword was used, but treat even those as
#                 something to verify against the code before saying an issue is done.
#
# Output: one JSON object on stdout:
#   {
#     "meta": { days, defaultBranch, openIssueCount, scanned:{openPRs,mergedPRs,commits},
#               referencedTruncated },
#     "issuesWithOpenPR":  [ { issue, linked, prs:[{number,title,isDraft,url}] } ],
#     "issuesReferencedByLandedWork":
#                          [ { issue, closingLanguage, evidence:[{type,ref,title,at}] } ],
#     "openPRs":           [ {number,title,isDraft,updatedAt,headRefName,url,refs} ]
#   }
#
# `openPRs` is returned whole because in-flight PRs also matter for *batching*: an
# issue touching files a live PR is rewriting is worth sequencing after it, even when
# the PR never mentions the issue.
#
# Usage:
#   check_inflight.sh                     # current repo, last 21 days of landed work
#   check_inflight.sh --days 45           # widen the "already landed" window
#   check_inflight.sh --repo owner/name   # target a specific repo (skips local commits)
#
# Requires: gh (authenticated), jq. Git history is read only when run inside a
# checkout of the target repo; everything else works from the GitHub API alone.

set -euo pipefail

DAYS=21
MAX_REFERENCED=20
REPO_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:?--days needs a number}"; shift 2 ;;
    --repo) REPO_ARGS=(--repo "${2:?--repo needs owner/name}"); shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Cutoff timestamp, portable across BSD (macOS) and GNU date.
if CUTOFF="$(date -u -v-"${DAYS}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then :
else CUTOFF="$(date -u -d "${DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)"; fi

# closedByPullRequestsReferences is GitHub's own resolution of closing keywords —
# it already discounts the hedged prose a regex would fall for.
OPEN_ISSUES="$(gh issue list ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
  --state open --limit 500 --json number,closedByPullRequestsReferences)"

OPEN_PRS="$(gh pr list ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
  --state open --limit 100 \
  --json number,title,body,isDraft,updatedAt,headRefName,url)"

MERGED_PRS="$(gh pr list ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
  --state merged --limit 400 --search "merged:>=${CUTOFF%%T*}" \
  --json number,title,body,mergedAt,url)"

DEFAULT_BRANCH="$(gh repo view ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
  --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || true)"

# Local commits on the default branch — catches fixes that landed without a PR, or
# whose PR body never named the issue. Only meaningful when the cwd is the repo.
COMMITS='[]'
if [ ${#REPO_ARGS[@]} -eq 0 ] && [ -n "$DEFAULT_BRANCH" ] \
   && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REF="$(git rev-parse --verify --quiet "origin/${DEFAULT_BRANCH}" \
      || git rev-parse --verify --quiet "${DEFAULT_BRANCH}" || true)"
  if [ -n "$REF" ]; then
    RAW="$(git log "$REF" --since="${DAYS} days ago" \
             --format='%H%x1f%s%x1f%b%x1e' 2>/dev/null || true)"
    COMMITS="$(printf '%s' "$RAW" | jq -Rs '
      split("\u001e")
      | map(select(test("[^[:space:]]")))
      | map(split("\u001f"))
      | map({ sha: (.[0] | gsub("^\\s+"; "")), title: (.[1] // ""), body: (.[2] // "") })
    ')"
  fi
fi

jq -n \
  --argjson openIssues "$OPEN_ISSUES" \
  --argjson openPRs "$OPEN_PRS" \
  --argjson mergedPRs "$MERGED_PRS" \
  --argjson commits "$COMMITS" \
  --arg cutoff "$CUTOFF" \
  --arg branch "${DEFAULT_BRANCH:-}" \
  --argjson days "$DAYS" \
  --argjson cap "$MAX_REFERENCED" '

  # Every "#123" mentioned anywhere in the text.
  def refs($t): [ ($t // "") | scan("#([0-9]+)") ] | flatten | map(tonumber) | unique;

  # Whether a closing keyword sits in front of "#123". Reported, not trusted —
  # "would also close #123" matches this and means the opposite.
  def closes($t):
    [ ($t // "")
      | scan("(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)[[:space:]]*:?[[:space:]]*#([0-9]+)"; "i")
    ] | flatten | map(tonumber) | unique;

  def annotate: . + { refs:   refs(.title + " " + (.body // "")),
                      closes: closes(.title + " " + (.body // "")) };

  ($openIssues | map(.number))                                        as $open
  | ($openIssues | map({ key: (.number|tostring),
                         value: [ (.closedByPullRequestsReferences // [])[] | .number ] })
                 | from_entries)                                      as $linked
  | ($openPRs   | map(annotate))                                      as $prs
  | ($mergedPRs | map(select(.mergedAt >= $cutoff)) | map(annotate))  as $merged
  | ($commits   | map(annotate))                                      as $cmts

  | [ $open[] as $i
      | ( ($merged | map(select(.refs | index($i)))
            | map({ type: "merged-pr", ref: ("#" + (.number|tostring)), title,
                    at: .mergedAt, closing: (.closes | index($i) != null) }))
        + ($cmts   | map(select(.refs | index($i)))
            | map({ type: "commit", ref: (.sha[0:9]), title,
                    at: null, closing: (.closes | index($i) != null) }))
        ) as $ev
      | select($ev | length > 0)
      | { issue: $i,
          closingLanguage: ([$ev[].closing] | any),
          evidence: ($ev | sort_by(.closing) | reverse | .[0:3]) }
    ]
    # Closing-language leads first — they are the ones worth spending a check on.
    | sort_by([(if .closingLanguage then 0 else 1 end), (.issue * -1)])   as $referenced

  | {
      meta: {
        days: $days,
        defaultBranch: (if $branch == "" then null else $branch end),
        openIssueCount: ($open | length),
        scanned: { openPRs: ($prs | length), mergedPRs: ($merged | length), commits: ($cmts | length) },
        referencedTruncated: ([($referenced | length) - $cap, 0] | max)
      },

      issuesWithOpenPR: [
        $open[] as $i
        | ($linked[$i|tostring] // [])                          as $formal
        | ($prs | map(. as $p | select(($p.refs | index($i)) or ($formal | index($p.number))))) as $hits
        | select($hits | length > 0)
        | { issue: $i,
            linked: (($formal | length) > 0),
            prs: ($hits | map({ number, title, isDraft, url })) }
      ],

      issuesReferencedByLandedWork: ($referenced | .[0:$cap]),

      openPRs: ($prs | map({ number, title, isDraft, updatedAt, headRefName, url, refs }))
    }
'

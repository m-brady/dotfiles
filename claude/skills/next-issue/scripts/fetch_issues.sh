#!/usr/bin/env bash
# Fetch open GitHub issues from the current repo as a normalized JSON array,
# for the next-issue skill. Repo-agnostic: gh auto-detects the repo from the cwd.
#
# By default it drops issues that are non-actionable by their label — the labels
# a triager would never "pick up next": the "won't do" family (wontfix, duplicate,
# invalid, not planned, anti-goal), the "parked" family (deferred, on-hold, blocked,
# icebox, backlog, stale), and the container family (tracking, epic, umbrella), which
# hold no work of their own and crowd out real items if ranked as if they did.
# Matching is case-insensitive and substring-based so "status: deferred",
# "Deferred", "on hold", "[tracking]", "blocked:design" etc. all match.
# Everything else stays in.
#
# Keeps the body so the skill can read cited file paths, checklists, and
# cross-references (e.g. "blocked by #x", "split from #y") that drive effort +
# batching judgments.
#
# Output: one JSON array on stdout. Each element:
#   number, title, url, createdAt, updatedAt, comments (count),
#   labels (array of names), milestone (title or null), assignees (array), body
#
# Usage:
#   fetch_issues.sh                       # open issues, non-actionable labels dropped
#   fetch_issues.sh --all                 # keep everything (no label filtering)
#   fetch_issues.sh --also-exclude a,b    # ADD to the drop-list (the usual case)
#   fetch_issues.sh --exclude a,b,c       # REPLACE the drop-list wholesale
#   fetch_issues.sh --repo owner/name     # target a specific repo
#
# Prefer --also-exclude when you have discovered one project-specific "won't do"
# label. --exclude replaces the entire default list, so using it to add a single
# needle silently re-admits every parked and wontfix issue.
#
# Requires: gh (authenticated), jq.

set -euo pipefail

EXCLUDE="wontfix,duplicate,invalid,not planned,anti-goal,deferred,on-hold,on hold,blocked,icebox,backlog,parked,stale,tracking,epic,umbrella"
REPO_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --all) EXCLUDE=""; shift ;;
    --exclude) EXCLUDE="${2:-}"; shift 2 ;;
    --also-exclude)
      EXCLUDE="${EXCLUDE:+$EXCLUDE,}${2:?--also-exclude needs a comma-separated list}"
      shift 2 ;;
    --repo) REPO_ARGS=(--repo "${2:?--repo needs owner/name}"); shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

RAW="$(gh issue list ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
  --state open \
  --limit 500 \
  --json number,title,url,createdAt,updatedAt,comments,labels,milestone,assignees,body)"

# Normalize shape, then drop issues carrying any excluded label (case-insensitive
# substring match). Pass the exclude list as a JSON array of lowercased needles.
if [ -z "$EXCLUDE" ]; then
  EXCLUDE_JSON="[]"
else
  EXCLUDE_JSON="$(printf '%s' "$EXCLUDE" \
    | jq -R 'split(",") | map(ascii_downcase | gsub("^\\s+|\\s+$";"")) | map(select(length>0))')"
fi

echo "$RAW" | jq --argjson drop "$EXCLUDE_JSON" '
  def excluded($labels):
    ($labels | map(ascii_downcase)) as $ll
    | any($drop[]; . as $needle | any($ll[]; contains($needle)));
  map({
    number,
    title,
    url,
    createdAt,
    updatedAt,
    comments:  (.comments  | length),
    labels:    (.labels    | map(.name)),
    milestone: (.milestone.title // null),
    assignees: (.assignees | map(.login)),
    body
  })
  | map(select(excluded(.labels) | not))
  | sort_by(.number) | reverse
'

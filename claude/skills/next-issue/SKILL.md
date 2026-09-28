---
name: next-issue
description: >
  Recommend what to work on next from a GitHub repository: a ranked shortlist of
  individual issues or coherent batches, grounded in impact, cost of delay,
  effort, readiness, repository priorities, and work already in flight or landed.
  Use for next-work, backlog prioritization, quick-win, tech-debt, release-focus,
  or `/next-issue` requests, including natural-language label and milestone filters.
---

# Next Issue

Produce a decision-ready shortlist from the repository's real backlog. A work item
may be one issue or a coherent batch suitable for one review. Labels inform the
decision; they do not replace reading issue bodies and comments.

## Capture once, inspect locally

From the target repository, collect one reusable snapshot:

```bash
snapshot_path="$(mktemp -t next-issue.XXXXXX.json)"
<skill-dir>/scripts/backlog_snapshot.sh collect --output "$snapshot_path"
<skill-dir>/scripts/backlog_snapshot.sh summary "$snapshot_path"
<skill-dir>/scripts/backlog_snapshot.sh show "$snapshot_path" 123 456
```

The snapshot retains issue bodies, comment records, normalized label strings, PR
bodies, exclusion reasons, in-flight links, and recent landed-work leads. `summary`
returns compact candidate and PR metadata; `show` returns full stored records for one or more
shortlisted issues. Do not call `gh issue view` for issues already in the snapshot.
Pass `--prs 7 8` to `show` when full cached bodies for particular open or merged
PRs are needed; issue-linked open PR bodies are included automatically.

Collection defaults to excluding won't-do, parked, and container label families.
After reading the repository's taxonomy, reclassify the saved snapshot locally:

```bash
<skill-dir>/scripts/backlog_snapshot.sh summary "$snapshot_path" --also-exclude status:waiting
```

Use `--exclude` to replace the saved list or `--all` to remove label exclusions.
This changes the summary only and never refetches GitHub. Report exclusion counts
and categories. Treat `blocked`, `needs-repro`, `needs-design`, and similar labels
as readiness signals when the repository uses them that way; valuable but gated
work belongs under **Not a coding session**.

The snapshot reports `meta.possiblyTruncated` when a GitHub list reaches its cap
(500 issues, 100 open PRs, or 400 merged PRs). State that limitation rather than
presenting capped counts as complete. Independent GitHub connections paginate
independently; do not claim one GraphQL request made a capped snapshot complete.

For issue numbers discovered only in plans or cross-references, batch the targeted
read in one GraphQL request using aliases and request state, body, labels, closing
reason, and the last comments needed for the decision. Store that response beside
the snapshot. Do not loop over `gh issue view`. If an issue's comment connection is
truncated, disclose it or paginate that issue only.

The old `fetch_issues.sh` and `check_inflight.sh` remain compatibility wrappers.
New runs use the snapshot entry point; `check_inflight.sh --snapshot FILE` reads
existing data without another collection.

## Establish the decision context

Read the project's instructions first. Then make one focused pass over its label
taxonomy, active milestone or release focus, and live backlog material: README,
roadmap, current plans, audits, and explicit triage rules. Skip archived,
superseded, and old-plan directories. Fixtures or authoritative project rules outrank
prose when the repository says so.

Stop expanding discovery once you can explain the current focus, interpret the
labels, and assess the strongest candidates. Do not turn prioritization into a
general repository audit. Search additional documents only when the shortlist has
a concrete ambiguity they can resolve.

Apply any user filter before ranking: quick wins means ready, low-effort work; bugs
means the repository's defect taxonomy; tech debt ranks by what it unblocks or
de-risks; a release or cutover ranks deadline-shaped cost first; a named document
scopes the answer to its claims.

## Rank a shortlist

Assess **Impact**, **Cost of delay**, and **Effort** independently as High, Medium,
or Low (use a range only for real uncertainty). Read the issue body and relevant
comments before scoring a shortlisted item.

- Impact favors correctness, durability, primary user flows, current release work,
  and changes that unblock several others.
- Cost of delay distinguishes compounding, deadline-shaped, ongoing, and static
  costs. Explain when the bill arrives.
- Effort includes concrete files and checklist scope, migration or API risk,
  cross-cutting work, and continuing maintenance.
- Readiness is a gate. Unanswered decisions, missing evidence, absent repros, and
  external administration keep an item out of the coding shortlist.

Batch issues only when shared files, setup, subsystem, or dependency order makes a
single review cheaper and coherent. Keep release boundaries separate, isolate risky
migrations and APIs, avoid a live PR's blast radius, and split giant batches.
Prerequisites rank first or appear first within a batch.

Remove issues with authoritative open closing links from the ranking. Plain PR text
references affect sequencing but are not proof of coverage. Recent merged PR or
commit references are leads only: inspect the diff or code before recommending that
an issue be closed. Preserve this evidence-before-closure safeguard even when the
closing language looks explicit.

Verify deeply only the likely six-to-ten rows and any claim that work is already
done. For the wider backlog, classification metadata and issue summaries are enough.
Stop when further reading would not change membership, order, batching, readiness,
or a closure claim.

## Present the choice

Open with one sentence covering eligible and excluded counts, in-flight removals,
the focus and filter used, live backlog docs consulted, and any truncation.

| # | Work item | Issues | Impact | Effort | Why now, and what deferring costs |
|---|-----------|--------|--------|--------|-----------------------------------|
| 1 | Short description | #123, #456 | High | Medium | Concrete value, timing, and batch synergy |

Use six to ten rows when the backlog supports them. Rank roughly by impact per unit
of effort, with cost of delay breaking ties; high-impact compounding work outranks
a pile of cheap polish.

Add only sections that carry real information: **If you'd rather…** for a useful
alternate; **Dependencies / ordering**; **Housekeeping** for fixes verified in code;
**Not yet filed** for unverified live-doc claims; **Not a coding session** for gated
work; and **Where I disagree with the labels**. Keep unfiled claims out of the ranked
table until verified.

When a live document points to a closed issue, read the closure explanation before
calling the document stale. Completed work can be removed; work closed because it
was parked must remain recorded, with its dead issue reference corrected.

End with the concrete first move for the top item and whether it needs planning.

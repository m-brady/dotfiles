---
name: next-issue
description: >
  Recommend what to work on next from a GitHub repo's open issue backlog — a
  ranked list of work items, where each item is a single issue OR a batch of
  related issues worth tackling together, scored on impact, what it costs to keep
  deferring, and effort, cross-checked against work that is already in flight or
  already landed. Reads the repo's own backlog, roadmap, plan, and audit documents
  alongside the issue tracker, so work that was written down but never filed still
  surfaces. Works in any repo with a GitHub remote; discovers the project's
  own labels, milestones, and priorities rather than assuming a fixed scheme. Use
  whenever the user asks what to work on, what's next, the next best issue, what to
  pick up, how to prioritize the backlog, "triage the issues," "what should I do
  now," "any quick wins," "any low-hanging fruit," "more tech debt to chew on,"
  what's worth doing before a cutover / launch / release, or which issues to batch
  into one PR. Also triggers on "/next-issue". Honors natural-language filters in
  the request (e.g. "just bugs", "quick wins", "tech debt only", "self-contained
  things", a milestone or label name).
---

# Next Issue — pick the next best work item

Decide what to work on next, grounded in the repo's _actual_ open backlog and its
own sense of priority. The deliverable is a **ranked list of work items**. A work
item is either **one issue** or a **batch** of related issues that belong in one
PR/session. Reassess each issue on the merits — labels are a signal, not the
verdict — because priorities go stale and issues get mislabeled.

Two framing points that shape everything below:

- **Batching is first-class.** Grouping adjacent issues (same area, same files, one
  unlocks another) is often the highest-leverage move. Don't collapse the answer to
  a single issue.
- **You are producing a decision aid, not a verdict.** The reader knows things the
  backlog doesn't — what they just shipped, what they have energy for, what they're
  deliberately avoiding this week. Expect them to take row 4, and build the list so
  that's easy rather than a rejection of your work. Rank honestly, make the
  reasoning legible, and give them the alternates.

This skill assumes nothing about the project. Discover its conventions from the data
(§1–3) instead of hardcoding them.

## Workflow

Anything the user passes alongside the invocation — `/next-issue tech debt`, a trailing
sentence, an argument string — is a **scope filter**, not a topic change. Read it before
you start, apply it in §7, and let it narrow what you fetch and rank rather than treating
it as a separate question. If both an argument and conversational context are present,
they compose: the argument narrows, the conversation supplies the reason.

### 1. Fetch the backlog

Run the bundled script from inside the repo (gh auto-detects it):

```bash
<skill-dir>/scripts/fetch_issues.sh
```

Returns a JSON array of open issues: `number, title, url, createdAt, updatedAt,
comments, labels[], milestone, assignees[], body`. By default it drops issues that
are non-actionable _by label_ — the "won't do" family (`wontfix`, `duplicate`,
`invalid`, `not planned`, `anti-goal`), the "parked" family (`deferred`, `on-hold`,
`blocked`, `icebox`, `backlog`, `stale`), and the container family (`tracking`,
`epic`, `umbrella`), which hold no work of their own.

Matching is substring-based, so a compound label like `blocked:design` is dropped by
the `blocked` needle. That's usually right — but it means a chunk of the backlog can
disappear on a readiness signal rather than a value one. Report the count, and if it's
large, name what kind of work it was.

The **body matters** — it carries the file paths, checklists, and cross-references
that drive effort and batching judgments. Read bodies; don't score off titles.

Adjust as the request demands:

- `--all` — keep everything, including parked/wontfix (use if the user says
  "include the parked stuff" or "everything").
- `--also-exclude a,b` — **add** this project's own "not now" labels to the defaults.
  This is the flag you want once §3 turns up a local won't-do or container label.
- `--exclude a,b,c` — **replace** the drop-list wholesale. Reach for this only when
  the defaults are actively wrong for the project; using it to add one needle
  silently re-admits every parked and wontfix issue.

### 2. Check what's already in flight or already landed

```bash
<skill-dir>/scripts/check_inflight.sh          # add --days N to widen the landed-work window
```

A backlog lies in two directions, and both failures are expensive in the same way —
they spend a whole session on work that didn't need doing:

- **Already in flight.** An open PR is addressing the issue. Recommending it means
  redoing live work or colliding with it.
- **Already fixed, never closed.** The fix landed; only the bookkeeping is
  outstanding. This is worth surfacing precisely _because_ it's cheap — closing a
  stale issue is a free win, and it's the kind of thing a backlog never
  self-corrects.

The script returns three things:

- `issuesWithOpenPR` — each carries `linked: true` when GitHub itself resolved the
  PR as closing the issue (authoritative), or `linked: false` when the PR text
  merely references it (adjacent work — relevant to sequencing, not proof of
  coverage). Drop the `linked: true` ones from the ranking and say so; sequence
  around the others.
- `issuesReferencedByLandedWork` — leads, **not findings**. `closingLanguage: true`
  means someone wrote "fixes #N" in merged work, which is worth a check, but prose
  cuts both ways: "would also close #N" describes work explicitly _not_ done, and
  "closing #N as accepted truncation" is a decision, not a fix. Before you put
  "already fixed — close it" in the output, confirm it against the code or the PR
  diff. An unverified close recommendation is worse than no recommendation, because
  acting on it destroys the record of real outstanding work.
- `openPRs` — the full open set, because in-flight PRs matter for batching even when
  they name no issue. An issue whose files a live PR is rewriting is worth
  sequencing after it.

### 3. Read the project's own conventions, focus, and backlog docs

Two things live outside `gh issue list` and change the answer: what the project is
trying to do right now, and work it wrote down but never filed. One pass gets both.

- **Label taxonomy** — `gh label list`. Identify which labels encode _priority_
  (e.g. `priority:high`, `P0`, `critical`), _type_ (`bug`, `enhancement`,
  `docs`), _area/component_ (anything that clusters issues by subsystem), and
  _readiness_ (below). Every repo names these differently; read what's there.
- **Milestones** — `gh api repos/{owner}/{repo}/milestones --jq '.[].title'` or the
  `milestone` field in the fetched JSON. An issue in the active/nearest milestone is
  usually higher-priority than one with none.
- **Project intent** — skim whatever the repo uses to state direction: `README`,
  `CONTRIBUTING`, `ROADMAP`, `CLAUDE.md` / `AGENTS.md`, a `docs/` folder, or pinned
  issues. Look for the current phase, release focus, or "help wanted" / "good first
  issue" signals. If nothing states a direction, infer it from what's shipping
  (recent commits, recently closed issues) and say you inferred it.

**Readiness is a separate axis from value.** Many projects mark issues that aren't
codeable yet: `needs-repro`, `needs-design`, `blocked:design`, `needs-evidence`,
`question`, or an evidence-grade scheme. "You can't start this today" is a different
claim from "this isn't worth doing" — a High-impact issue gated on an unanswered
question still can't be picked up this session. Treat readiness as a gate in §4, and
route what it gates to "Not a coding session" rather than dropping it silently.

**Backlog documents.** Skim for markdown that _carries_ work rather than describing
architecture — filenames and headings like `backlog`, `roadmap`, `TODO`, `plan`,
`audit`, `follow-ups`, `opportunities`, and any `docs/plans/`-style folder.

**Skip `archive/`, `superseded/`, `old/` and the like.** Those record past decisions,
not outstanding work, and they are usually the largest pile of backlog-shaped markdown
in the repo — a project that archives its finished plans is telling you the unarchived
ones are the live set. Recommending work out of an archive is the worst failure this
step has, because the doc reads exactly like a live plan.

Pull three different things out of what's left, and use each differently:

- **Triage rules the project wrote for itself** — the highest-value find and the
  easiest to miss. A doc saying "filter tracking issues out of any what-should-I-work-on
  query" or "every issue carries an evidence grade" is telling you how to rank _this_
  backlog. Follow it, and say that you did.
- **Status claims** — a doc asserting something shipped or is obsolete. Same epistemics
  as §2: a lead, not a finding. Docs rot faster than code, and these often carry their
  own "unverified — check before acting" warning. Confirm against the code first.
- **Unfiled work** — items with no issue number behind them. This is real backlog that
  `gh issue list` cannot see, but it hasn't been triaged the way issues have, so keep it
  out of the ranked table and surface it separately (see Output format).
- **Items whose issue is already closed** — a doc item that says "tracked in #N" for a
  closed `#N` is usually dead text, and reporting it as deletable is a free win the
  backlog never self-corrects. **Read the closing comment before you say that.** An issue
  can be closed as completed while the work was parked, and then the doc item is the only
  surviving record of it — deleting that loses the work. Closed-and-done means delete;
  closed-and-parked means keep the item and correct it to say the issue is gone.

Check dates. A doc that reconciled the backlog last month and one from a year ago will
disagree; the recent one wins. If a doc's checkboxes are stale enough that acting on any
of them means verifying each first, say that rather than ranking off them.

Use this context as a _factor_, not a hard filter. If the project is mid-release,
correctness and release-scoped work outranks nice-to-haves of equal size — say so
in the reasoning rather than silently dropping anything.

### 4. Score each item: impact, cost of delay, effort

Judge these independently and explain each call in a few words rather than asserting
it. Use **High / Medium / Low**, with honest ranges (`Low–Med`) where the estimate is
genuinely fuzzy. Keep this vocabulary for both axes — switching to S/M/L or points
mid-table makes rows incomparable, which defeats the purpose of a ranking.

**Impact — how much does shipping this matter now?**

- Correctness & durability rank highest: `bug`, data-loss/corruption, security,
  anything that breaks a core user flow.
- User-facing on the primary product surface > peripheral or internal.
- Refactor / dead-code / cleanup issues are real but usually lower user-impact —
  unless they unblock or de-risk something bigger.
- Fit with the current focus (§3): milestone-scoped or release-scoped work counts
  for more while that's the active push.
- Unblocking value: an issue that clears the path for several others punches above
  its size.

**Cost of delay — what happens if this keeps not getting done?**

This is the axis that usually decides the argument, and it's the one a bare priority
label never captures. "Why this is good to do" doesn't help someone choose; "here's
what it costs you to skip it, and when that bill arrives" does. For each item, know
which of these it is:

- **Compounding** — the cost grows: data keeps being written in the bad shape, more
  code gets built on the wrong abstraction, the migration gets harder every week.
- **Deadline-shaped** — cheap now, expensive after a specific event (a cutover, a
  launch, a release, an external deadline). Something that's a config change today
  and a user-visible regression the day after the cutover belongs at the top _now_
  and nowhere in particular later.
- **Bleeding** — a steady ongoing loss while it's open: every user hitting a broken
  flow, every run burning CI minutes, every alert training someone to ignore alerts.
- **Static** — genuinely costs nothing to defer. Say so plainly. This is useful
  information, not a failure to find urgency, and it's what makes the items above
  legible as urgent by contrast.

**Effort — how much work / risk to land it?**

- Count the concrete surface: bodies often cite exact files/line ranges, or a
  checklist of sub-tasks. More cited files/checkboxes → more effort.
- Schema/DB/migration or public-API changes carry risk — score higher-effort even
  when the diff looks small.
- New feature/UI > mechanical refactor or copy tweak of equal size.
- Cross-cutting change (many modules) > localized change.
- Ongoing upkeep is part of the cost. A change that adds a moving part someone has
  to maintain is more expensive than its diff suggests — especially in a small or
  single-maintainer project, where every new surface competes for the same attention.

**Readiness — can this actually be started today?**

Not a fourth score; a gate applied after the three above. An item is not ready when
something has to happen first that isn't coding: an unanswered product question, a
measurement nobody has taken, a repro nobody has produced, a decision only the
maintainer can make (§3, readiness labels — or the issue body saying so). Keep the
impact/effort read you already made, then say what's blocking and put it under
"Not a coding session" instead of a table row. Ranking a blocked item at #1 is the
most expensive kind of wrong answer here: the session starts, discovers the gate, and
ends with nothing shipped.

Priority labels and milestones are _inputs_. If your read disagrees with the label,
trust your read and note the discrepancy — a stale `priority:low` on a real
correctness bug is exactly what this skill should catch.

### 5. Find the batches

Look for issues cheaper or better done together. Signals:

- **Shared area/component label** — several issues in the same subsystem at once.
- **Overlapping files** — bodies cite the same or adjacent source files. One PR
  avoids rework and conflicting churn.
- **Cross-reference chains** — "split from #x", "part of #y", "follow-up to #z".
  Explicit grouping hints.
- **Same milestone + same theme.**

Batching rules:

- **Don't batch across deployment/release boundaries** — things that ship
  separately (e.g. two different apps/packages/services in a monorepo) stay in
  separate items.
- **Don't fold a risky change (schema/migration/API) into unrelated cleanup** —
  keep risky changes isolated and reviewable.
- **Don't batch into a live PR's blast radius** (§2) — if an open PR is already
  rewriting those files, either sequence after it or say the batch depends on it
  landing.
- Keep a batch to a coherent, reviewable size. If a "batch" would be a giant PR,
  split it and say so.
- A batch's impact/effort is the combined estimate; its synergy (shared
  files/setup) is _why_ it beats doing the pieces separately — state that.

### 6. Resolve ordering & dependencies

If issue A is blocked by B ("blocked by #x", "after #x", "depends on #x", or B is a
prerequisite refactor), B ranks ahead of A — or they batch with B done first. Call
out any "do this before that" relationships explicitly. Treat issues that
self-declare as blocking/gating as prerequisites for their group.

### 7. Honor request filters

If the request narrows scope, apply it before ranking and say what you filtered. The
common shapes, and what each is really asking for:

- **"quick wins" / "low-hanging fruit"** → Low-effort only, impact-ranked.
- **"just bugs" / "correctness"** → the project's bug/defect labels.
- **"high impact"** → lead with High-impact regardless of effort.
- **"tech debt" / "cleanup"** → refactors, dead code, dependency and config hygiene,
  test/CI health. Rank these by what they unblock or de-risk, since their direct
  user impact is low by definition — otherwise every row reads "Med / Med".
- **"self-contained" / "interesting" / "something I can just start"** → things one
  person can finish in a sitting without a decision from someone else or a design
  round-trip. This is the §4 readiness gate applied hard rather than as a factor:
  filter out anything gated on an unanswered question, and say that's why.
- **"before the <cutover / launch / release>"** → rank by the deadline-shaped cost
  in §4: what does that event make harder, more expensive, or newly visible to real
  users? Work that's cheap before and painful after goes first, even at modest
  impact. Say explicitly which items the event doesn't affect at all.
- **"what's left in \<doc\>" / a named backlog or audit document** → scope to the work
  items that document tracks, issues and unfiled entries alike, and lead with how much
  of it you could verify. A doc-scoped ask is usually really asking "is this document
  still true?" — answer that too.
- A named label, milestone, area, or `good first issue` → filter to it.

## Output format

Lead with a one-line read of the backlog: how many eligible issues, how many dropped
and why (including anything dropped for having a PR in flight), the current focus
you're ranking against, which backlog docs you read (or that there were none), and any
filter applied. Then the ranked table.

```markdown
**Backlog:** 35 eligible open issues (6 parked, 3 tracking, 2 already have open PRs), plus `docs/frontend-backlog.md` (last reconciled May). Ranking against the current release milestone.

| #   | Work item                       | Issues     | Impact | Effort | Why now, and what deferring costs                          |
| --- | ------------------------------- | ---------- | ------ | ------ | ---------------------------------------------------------- |
| 1   | <short description of the item> | #452, #446 | Med    | Low    | same area, adjacent files; one review. Cheap now — after the cutover both are user-visible regressions |
| 2   | <…>                             | #531       | High   | Med    | data-loss risk on the submit path; compounding — every day writes more rows in the bad shape |
| 3   | <…>                             | #376       | Low    | Low    | self-contained, clear user value. Costs nothing to defer    |
```

Six to ten rows is usually right. Resist trimming to three: the reader's own pick is
often in the tail, and a short list forces them to re-ask rather than choose.

After the table, add these — each only when there's something real to say:

- **If you'd rather…** — one line pointing at the best alternate for a different
  mood or constraint: the cheapest row, the one that needs no decisions, the one
  that's pure cleanup. This is what makes overriding you cheap.
- **Dependencies / ordering** — "do X before Y", blockers, gating items.
- **Housekeeping** — issues you _verified_ are already fixed and should just be
  closed (§2), with the commit or PR that did it. Zero-effort wins, worth their own
  line rather than a table row competing on impact.
- **Not yet filed** — work found only in a backlog doc, with no issue behind it (§3).
  Give the doc path and, where the doc dates itself, how stale the claim is. Say
  plainly that these are unverified — the doc asserts the work is outstanding, and you
  haven't checked the code. Keeping them out of the table isn't a demotion: it's the
  same authoritative-vs-lead split as §2, and it's what lets the reader trust the rows
  that _are_ in the table. Offer to verify one or file it as an issue.
- **Not a coding session** — backlog items that need a different kind of time:
  legal/admin, clickops in a third-party console, a decision only the maintainer can
  make, or anything the §4 readiness gate caught — a measurement to take, a repro to
  produce, a design question to answer. These are real work and often urgent, but
  ranking them beside code
  implies they're interchangeable with it, and they aren't. Name them, say what kind
  of time they need, and keep them out of the main table.
- **Where I disagree with the labels** — where your read differs from the priority
  label or milestone, and why. This is a feature, not noise.

Keep it tight. The user wants a decision aid, not an essay per issue.

Rank roughly by impact-per-unit-effort, letting cost of delay break ties — genuinely
high-impact or compounding work outranks a pile of cheap polish even when the polish
is "efficient."

## Hand it off

Most of the time the next question is "OK, start that one" — so close by naming the
concrete next step for the top pick rather than stopping at the table. One line is
enough: what the first move is (plan it, verify it, or just do it), and whether it's
big enough to be worth planning before touching code.

If the user's setup has a handoff or planning skill, offer it by name and let them
take it in one word. If they pick a different row than you ranked first — which is
common and usually well-founded — carry the same offer to their choice without
relitigating the ranking.

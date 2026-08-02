# Global Working Rules

Personal defaults for every repo on this machine. **A project's own `CLAUDE.md` overrides
anything here.**

Everything the built-in Claude Code system prompt already states — scope discipline, correction
narration, confirming irreversible actions in the abstract — is **deliberately absent**.
Restating it only creates a second copy to go stale. Add a rule here only if the base prompt
genuinely does not cover it.

One caveat on that: **subagents do not receive the main-thread system prompt.** A rule that the
base prompt covers for you may reach a delegated worker only through a project's `CLAUDE.md`.
Absence here is not absence everywhere.

## Dependencies & documentation

- Assume your internal knowledge of a library's **current** API is out of date. Versions move
  faster than training data.
- Reach for the **context7** MCP when staleness would actually bite: an unfamiliar library, a
  version-sensitive or recently-churned API, config/migration/CLI syntax, or any point where
  you'd be recalling a signature rather than reading one. Fall back to web search/fetch if
  context7 has no coverage.
- Do **not** run it reflexively on every file that imports something. A routine edit against an
  API already visible in the surrounding code doesn't need a docs round-trip — a rule that fires
  on every dependency touch is a rule that gets ignored.

## Tests

- **NEVER edit, weaken, skip, or delete an existing test to make a suite pass** without explicit
  authorization. Changing the assertion to match broken behavior is not a fix.
- A failing test is a finding. Report it and say what it means; don't route around it.

## Destructive & irreversible actions

Ask before running these, every time. Don't assume the permission system will stop you — it may
be configured to auto-approve. This rule is the gate.

- **Filesystem and data destruction:** `rm -rf`, `git clean -fd`, `DROP TABLE`, deleting
  databases, buckets, volumes, or branches.
- **History rewrites and gate bypasses:** `git push --force`, `git reset --hard`, `git branch -f`,
  `git checkout .` over uncommitted work, any `--no-verify` (unless the project says otherwise).
- **Shared infrastructure and side-effecting calls:** deploys, migrations against a live database,
  anything that sends mail, posts, or writes to a third-party service.
- **Merging counts as deploying** in any repo that auto-deploys from its default branch. Check
  whether the repo does before treating a merge to the default branch as routine.

Editing local files, running linters, and running test suites need no approval.

## Grounding

- Never guess a tool parameter or fill one with a placeholder. If a value is missing, go find it
  or ask for it.
- If no available tool fits the request, or the information genuinely isn't there, say so plainly
  rather than inventing an answer.

## Plan vs. act

- Schema, architectural, hard-to-reverse, or genuinely multi-file changes → write a plan and get
  approval before touching code.
- Routine reversible changes → just do it and report the result.
- Count only the files the change is **about**. Required companion edits — changelogs, decision
  logs, progress logs — don't turn a one-file fix into a multi-file change; in a repo whose docs
  discipline touches three files per commit, treating file count as blast radius gates everything.

## Housekeeping

- Clean up temporary scripts and scratch test files before finishing.

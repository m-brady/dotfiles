---
name: pr-flow
description: >-
  Take finished work from the working tree to a merged PR: verify the branch, run the repo's own
  gate, commit, push, open the PR, read CI correctly, and — only when told to in the same turn —
  merge, close the linked issue, and clean up. Use this skill whenever the user says "push it",
  "push", "push our changes", "ok push it", "create a pr", "pr pls", "open a PR", "merge it",
  "ok merge it", "lets merge", "safe to merge?", "is it green", "ship it", or otherwise asks to
  get the current change onto a branch, into a PR, or into main. Also use it when asked to check
  whether a PR is ready, or to clean up after a merge. It carries the per-repo gates, the CI
  output traps that make a healthy PR look failed, and the worktree merge traps that corrupt git
  config or close a stacked PR for good.
---

# PR flow

Six steps. Stop after step 5 unless the user asked to merge **in the current turn**.

A merge to `main` is a production deploy in both repos. Never merge because CI is green.

## 1. Verify the branch before you stage anything

```bash
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

Two checks, both cheap, both cost a cleanup when skipped:

- **Not `main`.** If HEAD is `main`, branch first: `git checkout -b <type>/<slug>`.
- **The right branch.** A worktree's directory name is not its branch name, and a session-start
  snapshot goes stale. Read the parent commit. If it is unrelated parked work, your commit does
  not belong on top of it — branch off `origin/main` instead.

## 2. Stage explicit paths, never `git add -A`

```bash
git status --short
git add <path> <path>
```

`git add -A` swept an unrelated skill directory into gymlog PR #502, and it merged on a PR that
never mentioned it. Read `git status` and name the files.

## 3. Run the repo's gate before pushing

| Repo | Gate | Notes |
| --- | --- | --- |
| franticfanfic | `pnpm run knip`, then the matching `pnpm run verify:*` | `verify:frontend` for `apps/frontend-next`, `verify:worker` for the workers and packages, `verify:all` for wire types. A `.claude/hooks/knip-push-gate.sh` runs knip on push anyway; running it first turns a blocked push into a fixed one. |
| gymlog | `.githooks/pre-push` runs the four CI checks on push | Do not re-run them by hand first. If the hook is not armed, `pnpm install` or `git config core.hooksPath .githooks`. Never `--no-verify` onto `main`. |

Any other repo: read its `CLAUDE.md` for the named gates. Run those, not extras.

## 4. Commit and push

End the commit message with the attribution lines the session's system prompt gives. Then:

```bash
git push -u origin <branch>
```

Push the branch you are on. `git push -u origin <name>` resolves `<name>` as a local ref, so a
wrong name silently pushes a different branch.

## 5. Open the PR, then read CI properly

```bash
gh pr create --title "..." --body "..."
gh pr checks <N> --json name,bucket,state --jq '.[] | "\(.name): \(.bucket) (\(.state))"'
```

**Always the `--json` form.** Plain `gh pr checks` prints a cancelled job in the `fail` column.

| Repo | What healthy looks like | What a real failure looks like |
| --- | --- | --- |
| gymlog | `MERGEABLE / UNSTABLE`, one `CI backstop (push)` at `bucket=cancel` beside a green `Lint, Type Check, and Test` | `bucket=fail` / `state=FAILURE` |
| franticfanfic | All checks pass, including `Workers Builds: next-dev` when the PR touches `apps/frontend-next/**` | A red integration shard — but read the shard summary first |

**Do not call a red franticfanfic integration shard a regression before reading the summary.** A
watchdog verdict saying the worker pair stopped responding is #1258. An alarm-stall line in the
harness report is the same thing seen from inside the Durable Object (#1542), and the HTTP
watchdog can stay green right through one.

Report the state and stop here. The user decides whether to merge.

## 6. Merge — only on an explicit instruction this turn

```bash
gh pr merge <N> --squash
```

**Never pass `--delete-branch` from inside a worktree.** Two separate failures:

- franticfanfic: `gh` tries to check out the base branch first and fails, because `main` is held
  by the primary checkout. The merge already landed — do not re-run it. Confirm with
  `gh pr view <N> --json state,mergeCommit` (`merged` is not a valid field; `state` reads `MERGED`).
- gymlog: it flips `core.bare` to `true` in the shared `.git/config`, and then every work-tree
  command in the main checkout fails with `fatal: this operation must be run in a work tree`.
  Fix with `git config core.bare false` **before** removing the worktree.

Delete the remote branch yourself instead: `git push origin --delete <branch>`.

**Stacked PRs: retarget the child first.** `gh pr edit <child> --base main` while it is still
open, and only then merge the parent. Deleting a base branch closes the child permanently, and a
closed PR cannot be retargeted or reopened.

### After the merge

1. **Close the linked issue, checking state first.** GitHub auto-closes only on the literal
   keywords `close`/`closes`/`closed`/`fix`/`fixes`/`fixed`/`resolve`/`resolves`/`resolved`.
   "closing #526" is not one of them, and gymlog #526 stayed open silently.

   ```bash
   gh issue view <N> --json state,closedAt
   ```

   Open → `gh issue close <N> --comment "<what shipped>"`.
   Already closed → `gh issue comment <N> --body "<what shipped>"`. `gh issue close --comment` on
   an already-closed issue prints a warning, exits 0, and throws the comment away.

2. **gymlog only:** `git config --get core.bare`. `true` on a repo with real files is the bug.

3. Return to the base: `git checkout main && git pull`.

## Worktree note

Inside a `.claude/worktrees/` checkout the Bash sandbox rejects commands it cannot statically
prove stay inside the worktree — compound commands with `$(...)`, process substitution, or loops
come back as "too complex to verify". Resolve an id in one call, use the literal in the next.

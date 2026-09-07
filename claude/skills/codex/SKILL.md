---
name: codex
description: "Run OpenAI's Codex CLI (`codex exec`) as a second coding agent from inside Claude Code — to plan a task, implement it, or review a diff with a different model's eyes. Use this skill whenever the user says codex, gpt-6, astra, sol, terra, luna, `codex exec`, 'ask codex', 'get codex to do it', 'what does codex think', 'second opinion', 'have another model look at this', 'let codex plan it', 'run this past gpt', or asks to compare two models on the same task. Also use it before running any `codex` command by hand: it carries the model table, the exact non-interactive command shapes, and five traps that each waste a run — `codex exec` writes to your files by default, codex reads AGENTS.md and never sees CLAUDE.md, a real run outlasts the default Bash timeout, the `review` subcommand rejects both a trailing `-s` and a prompt alongside `--uncommitted`, and a piped stdin gets silently appended to the prompt."
---

# Codex CLI

Codex is a separate coding agent with its own models. It is worth reaching for in
three situations, and not otherwise:

- **A second opinion.** A different model family sees different problems. This is the
  strongest use — an adversarial review of a plan or a diff you already wrote.
- **Parallel work.** Codex runs in its own process. Hand it a self-contained job and
  keep working while it runs.
- **The user asked for it by name.** Then just run it.

If the task is something you can do directly, do it directly. Shelling out to another
agent costs minutes and subscription quota, and it starts with none of your context.

## The three modes

Every mode uses `codex exec`, the non-interactive entry point. Always pass a model, an
effort, a sandbox, and an output file, so nothing depends on the user's `config.toml`
drifting.

**Plan — codex thinks, you implement.** Read-only, so codex cannot touch the tree:

```bash
codex exec -s read-only \
  -m gpt-6-astra -c model_reasoning_effort="high" \
  -o /tmp/codex-plan.md \
  "Read apps/worker/src/game-do.ts and propose how to add X. Do not write code. \
List the files to change and the risk in each." < /dev/null
```

**Implement — codex edits the tree.** Confirm with the user first; codex runs with
`approval: never` and will not ask before it writes:

```bash
codex exec -s workspace-write \
  -m gpt-5.6-terra -c model_reasoning_effort="medium" \
  -o /tmp/codex-out.md \
  "<the task, plus the constraints codex cannot infer>" < /dev/null
```

Afterwards, read `git diff` yourself. Do not report the work as done on codex's word.

**Review — codex reads a diff.** The `review` subcommand knows how to find the changes:

```bash
codex exec -s read-only \
  -m gpt-6-astra -c model_reasoning_effort="high" \
  -o /tmp/codex-review.md \
  review --uncommitted < /dev/null
```

Swap `--uncommitted` for `--base main` or `--commit <sha>` to pick a different target.
`--uncommitted` covers staged, unstaged **and untracked** files, so a new file that git
has never seen still gets reviewed.

`review` takes a target flag **or** a custom prompt, never both — see trap 4. So when
you want to steer the review, drop the target flag and say what to look at in the
prompt instead:

```bash
codex exec -s read-only \
  -m gpt-6-astra -c model_reasoning_effort="high" \
  -o /tmp/codex-review.md \
  review "Review the uncommitted changes. Focus on correctness during live game \
sessions; ignore style." < /dev/null
```

Both forms need every global flag ahead of the word `review`.

**Follow up** on any of these without rebuilding the context:

```bash
codex exec resume --last -o /tmp/codex-followup.md "<follow-up question>" < /dev/null
```

## Which model

Pick by how hard the task is, not by habit. Effort matters as much as the model — an
`xhigh` run takes several times as long as a `low` one.

| Slug | Good for | Efforts | Default |
| --- | --- | --- | --- |
| `gpt-6-astra` | hard planning, adversarial review, anything you want a real second opinion on | low, medium, high, xhigh, max, ultra | low |
| `gpt-5.6-sol` | everyday agentic work; the user's own config default | low, medium, high, xhigh, max, ultra | low |
| `gpt-5.6-terra` | normal implementation work | low, medium, high, xhigh, max, ultra | medium |
| `gpt-5.6-luna` | fast, cheap runs — lookups, summaries, a quick sanity check | low, medium, high, xhigh, max | medium |
| `gpt-5.5` | previous generation; use only to compare against it | low, medium, high, xhigh | medium |
| `gpt-5.4-mini` | small mechanical jobs | low, medium, high, xhigh | medium |

Sensible defaults: `gpt-6-astra` at `high` to plan or review, `gpt-5.6-terra` at
`medium` to implement, `gpt-5.6-luna` at `low` to look something up.

This table was read on 2026-09-06 and it goes stale. The live list is a JSON file —
print it when a slug is rejected or when you want to check for a new model:

```bash
python3 -c "import json;d=json.load(open('$HOME/.codex/models_cache.json'));\
[print(m['slug'],'|',m.get('display_name'),'|',m.get('visibility'),'|',m.get('description')) for m in d['models']]"
```

Slugs marked `hide` are internal. Do not offer them.

## Reading the result

`-o FILE` writes **only codex's final message**. That is the answer — read it with
`cat`. Everything else, including each command codex ran, goes to stdout; read that
when you need to know what it actually did, not just what it concluded. `--json` gives
the same events as JSONL if you want to parse them.

Summarize the result for the user in your own words. Do not paste a long codex
transcript into the conversation.

## Traps

Each of these costs a whole run to rediscover.

1. **`codex exec` defaults to `workspace-write`, not read-only.** A "just have a look at
   this" run will edit files. Pass `-s read-only` on every plan and every review. Check
   the `sandbox:` line codex prints at startup — it tells you which mode you got.
2. **Codex reads `AGENTS.md` and never reads `CLAUDE.md`.** Most repos here have a
   detailed `CLAUDE.md` and no root `AGENTS.md`, so codex starts blind: it does not know
   the deploy rules, the test commands, or which client is live. Put the facts it needs
   in the prompt, or tell it to read the `CLAUDE.md` path first. A codex plan that
   ignores a documented constraint is usually this, not a bad model.
3. **A real run outlasts the default Bash timeout.** Planning at `high` takes minutes.
   Pass `timeout: 600000`, or run it in the background and pick the result up later.
   A killed run wastes the whole call.
4. **The `review` subcommand rejects two things the usage string appears to allow.**
   Its help prints `Usage: codex exec review [OPTIONS] [PROMPT]`, which is misleading in
   two ways, and both fail at argument parsing before any work starts:
   - **Global flags must come before `review`.** `codex exec review --uncommitted -s read-only`
     dies with `unexpected argument '-s' found`. Only the parent `exec` takes `-s`. `-m`
     and `-o` happen to work in either position; `-s` does not.
   - **A target flag and a prompt are mutually exclusive.** `review --uncommitted "focus
     on X"` dies with `the argument '--uncommitted' cannot be used with '[PROMPT]'`. Same
     for `--base` and `--commit`. Pick one: the target flag for codex's own review of that
     diff, or a bare prompt that names what to look at.
5. **A piped stdin is appended to the prompt.** When stdin is not a terminal, codex
   reads it and adds it as a `<stdin>` block — you get "Reading additional input from
   stdin..." and a polluted prompt. End every command with `< /dev/null` unless you are
   piping something on purpose.

Two more things worth knowing:

- **Auth is the user's ChatGPT subscription** (`auth_mode: chatgpt`), not an API key.
  There is no per-token bill, but there is a quota. Do not spend `astra` at `max` on a
  question `luna` at `low` answers.
- **Worktrees.** Codex prints its `workdir:` on startup. Confirm that line points at the
  worktree you are in, not the main checkout. Pass `-C "$PWD"` if it does not. Add
  `--skip-git-repo-check` only when the directory genuinely is not a git repo.

## Writing the prompt

Codex has none of your conversation. A prompt that works reads like a work order: what
to read, what to produce, what not to do. Name the files. State the constraint that is
not visible in the code. Say what the output should look like — "list the files to
change and the risk in each" gets a usable answer where "help me with X" gets an essay.

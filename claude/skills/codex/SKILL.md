---
name: codex
description: "Run OpenAI's Codex CLI (`codex exec`) as a second coding agent from Claude Code, to plan a task, implement it, or review a diff with a different model. Use it when the user says codex, gpt, astra, sol, terra, luna, 'ask codex', 'second opinion' or 'have another model look at this', when they ask to compare two models on one task, and before you run any `codex` command by hand. It has the command shapes, the model table and cost defaults, and six traps that each waste a run."
---

# Codex CLI

Codex is a separate coding agent with its own models. It is worth reaching for in
three situations, and not otherwise:

- **A second opinion.** A different model family sees different problems. This is the
  strongest use — an adversarial review of a plan or a diff you already wrote.
- **Parallel work.** Codex runs in its own process. Hand it a self-contained job and
  keep working while it runs.
- **The user asked for it by name.** Then run it, after you confirm the model and
  effort (see below).

If the task is something you can do directly, do it directly. Shelling out to another
agent costs minutes and subscription quota, and it starts with none of your context.

## The three modes

Every mode uses `codex exec`, the non-interactive entry point. Always pass a model, an
effort, a sandbox, and an output file, so nothing depends on the user's `config.toml`
drifting.

**Before every run, tell the user the model, the effort and the scope, and wait
for a yes.** Runs spend the user's ChatGPT plan quota. A yes for one run does not
cover the next one.

**Plan — codex thinks, you implement.** Read-only, so codex cannot touch the tree:

```bash
codex exec -s read-only \
  -m gpt-6-sol -c model_reasoning_effort="medium" \
  -o /tmp/codex-plan.md \
  "Read apps/worker/src/game-do.ts and propose how to add X. Do not write code. \
List the files to change and the risk in each." < /dev/null
```

**Implement — codex edits the tree.** Confirm with the user first; codex runs with
`approval: never` and will not ask before it writes:

```bash
codex exec -s workspace-write \
  -m gpt-6-sol -c model_reasoning_effort="medium" \
  -o /tmp/codex-out.md \
  "<the task, plus the constraints codex cannot infer>" < /dev/null
```

Afterwards, read `git diff` yourself. Do not report the work as done on codex's word.

**Review — codex reads a diff.** The `review` subcommand knows how to find the changes:

```bash
codex exec -s read-only \
  -m gpt-6-sol -c model_reasoning_effort="medium" \
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
  -m gpt-6-sol -c model_reasoning_effort="medium" \
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

GPT-6 (Sol and Luna from 2026-09-22, Astra from about 2026-09-01) replaces the GPT-5.6
models. Codex itself now labels GPT-5.6 "Older" and GPT-5.5 "Legacy". **Cost** is
the credit rate per 1M output tokens, relative to `gpt-6-sol`, from OpenAI's pricing
page.

| Slug | Good for | Efforts | Start at | Cost |
| --- | --- | --- | --- | --- |
| `gpt-6-astra` | the hardest end-to-end work. Only when the user asks for it by name. **Never at `high` or above**: it costs too much on the user's plan | low … max, ultra | low | 5× |
| `gpt-6-sol` | the default for all real work: planning, review, implementation, complex coding | low … max, ultra | medium | 1× |
| `gpt-6-luna` | focused, repeatable jobs: lookups, extraction, summaries, small scoped edits. The user's own `config.toml` default (at `high`) | low … max (no ultra) | low for a lookup, high for focused coding | 0.05× |
| `gpt-5.6-sol` | only to compare against GPT-6 | low … max, ultra | low | 2× |
| `gpt-5.6-terra` | only to compare against GPT-6. There is no `gpt-6-terra`; use `gpt-6-sol`, which costs less | low … max, ultra | medium | 1.2× |
| `gpt-5.6-luna` | only to compare against GPT-6 | low … max | medium | 0.12× |
| `gpt-5.5` | nothing. **Retires from Codex on 2026-10-14** | low … xhigh | medium | 3× |

`gpt-5.4` and `gpt-5.4-mini` retired from Codex on 2026-08-31. Do not offer them.

Defaults: `gpt-6-sol` at `medium` to plan, review or implement, and `gpt-6-luna` at
`low` to look something up. Keep a review to one or two focus areas, and do not tell
codex to read `node_modules`.

**Which effort.** OpenAI's guidance, in short:

- `low` — quick, well-scoped tasks.
- `medium` — tasks that need some planning. The right start for Sol.
- `high`, `xhigh` — hard work with many steps, sources or tradeoffs. OpenAI suggests
  Sol at `xhigh` for "careful review of ... code". Offer it for a large or risky diff,
  but say that it costs more and confirm first.
- `max` — more time on one hard problem. "Most tasks do not need Max or Ultra."
- `ultra` — codex splits the task into parallel subagents. Use it only when the work
  divides into separate parts, and never without the user's explicit request: it
  multiplies the quota spend.

Effort levels do not map one-to-one between GPT-5.6 and GPT-6. A GPT-5.6 setting that
worked is not proof that the same effort on GPT-6 is right.

**Fast mode** (`service_tier = "fast"`, or `/fast on` in the TUI) costs 2.5× the
normal credit rate on GPT-6. Do not turn it on. Leave it to the user.

Sources, read on 2026-09-28 (the old `developers.openai.com/codex/...` links now
redirect here):

- https://learn.chatgpt.com/docs/models — what each model is for, efforts, retirements
- https://learn.chatgpt.com/docs/model-selection — which model and effort for which task
- https://learn.chatgpt.com/docs/pricing — message limits and credit rates for each plan

This table goes stale. The live list is a JSON file — print it when a slug is rejected
or when you want to check for a new model:

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
2. **Codex reads `AGENTS.md` and never reads `CLAUDE.md`.** Check which you have before
   assuming codex has any context:

   ```bash
   find . -name AGENTS.md -not -path './node_modules/*' -not -path './.git/*'
   ```

   Where a repo pairs each `CLAUDE.md` with an `AGENTS.md` symlink beside it, codex gets
   the same layered context you do and nothing more is needed. `franticfanfic` does this
   in all nine directories that have a `CLAUDE.md`. Where a repo does not, codex starts
   blind — it will not know the deploy rules, the test commands, or which client is
   live. Then either state those facts in the prompt, or add the symlinks yourself, one
   per directory that has a `CLAUDE.md`:

   ```bash
   (cd <dir> && ln -s CLAUDE.md AGENTS.md)
   ```

   A symlink is better than a second file, which only goes stale. A codex plan that
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
6. **The `codex` on your PATH can be older than the model list.** Codex fetches the
   model list from the server into `~/.codex/models_cache.json`, so a slug can appear
   there before the installed CLI knows it. OpenAI's changelog lists GPT-6 Sol and Luna
   under CLI 0.157.0. The Homebrew cask (`/opt/homebrew/bin/codex`) does not update
   itself; the ChatGPT desktop app has its own separate copy. Check before the first
   GPT-6 run:

   ```bash
   codex --version   # want 0.157.0 or later for gpt-6-sol / gpt-6-luna
   brew outdated --cask codex
   ```

   If it is older, ask the user to run `brew upgrade --cask codex`. Do not fall back
   to a GPT-5.6 model without telling the user.

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

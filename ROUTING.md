# Routing

How work is split across models. This file is generic. A project keeps its own adapted copy.

## Principles

- Route by what the work is: the kind of work, the file paths it touches, the review pass type.
  Never route by a guess at how hard the work is.
- Two effort levels only. `high` for flow work. `xhigh` where a mistake is expensive or taste
  matters. There is no `low` or `medium`.
- The main session is the orchestrator. It talks to the owner and owns commits and merges.
- One task per session. A long session re-reads its whole context every turn, and that is the
  biggest quota cost. Finish or hand off the task, then start a new session.
- The routing table is the instruction that sets the Agent tool's `model` and `effort`.

## Roles

| Work                                                                                      | Worker                                 | Model, effort      | Why                                                    |
| ----------------------------------------------------------------------------------------- | -------------------------------------- | ------------------ | ------------------------------------------------------ |
| Dialog, criteria, brief, small edits, commits, merge                                      | the main session (orchestrator)        | Sonnet, high       | Needs the owner's context and runs all the time        |
| A plan for a structural change: data shape, routing, build or CI config, design tokens    | `planner` agent, read-only             | Opus, xhigh        | A wrong structure is costly to undo                    |
| Work that depends on taste: visual, copy, UX                                              | `crafter` agent                        | Sonnet, xhigh      | Taste needs care, and Claude holds the project's voice |
| Code with no taste in it: tests, data, scripts, accessibility, performance, an exact plan | Codex, `workspace-write`               | gpt-6.1-sol, xhigh | Has a check that passes or fails, and a second vendor  |
| Review, first pass or delta                                                               | `reviewer` agent                       | Opus, high         | A context that did not write the code                  |
| Review when the change touches a high-risk path                                           | `reviewer` agent, `effort: xhigh`      | Opus, xhigh        | A miss on a risky path is expensive                    |
| Review, trivial re-pass or comment-only pass                                              | general-purpose agent, `model: sonnet` | Sonnet, high       | Little to find, so the cheaper model is enough         |
| Fix loop and QA after review                                                              | general-purpose agent, `model: sonnet` | Sonnet, high       | Follows concrete findings                              |
| Review lenses: bug hunt and second opinion                                                | Codex, `read-only`                     | gpt-6.1-sol, xhigh | A different model finds different bugs                 |
| Objective audits: accessibility, performance, security scans                              | Codex, `read-only`                     | gpt-6.1-sol, xhigh | The result is measurable                               |
| Run check, build and test commands; search; count; summarise long output                  | `runner` agent, read-only              | Haiku, high        | Cheap, and keeps long output out of the session        |

The owner can override any row: `/model opus` in a session, or a word in chat.

## Rules

- **A small edit stays in the orchestrator.** Handing a one-line change to another model costs
  more than making it. A brief is for larger work, work for another model, or work that may
  outlive the session.
- **Codex never decides how something looks or reads.** It gets work with a check that passes or
  fails. Visual and copy work stays with Claude.
- **Codex never commits.** The orchestrator reads its diff, runs the checks and commits.
- **If Codex is missing or fails**, say so and route the work to the Claude equivalent: code to
  the orchestrator, a bug lens to `/code-review`, and record the second opinion as not run.
- **Review runs in a context that did not write the code.** Use a fresh subagent or a new session.
- **Every delegated prompt repeats the limits** in the prompt text: read-only unless the step owns
  the edits, never push, never upgrade tools, never edit the agent docs unless the task is that.
  A skill's own preamble does not know the project's rules.
- **Hand-off files.** Codex and Claude cannot see each other's conversations, and a quota limit or
  an account switch can end a session. See "Brief and status" below.

## Codex command

Run Codex from the working tree, with the report written to a file:

```bash
codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh -s read-only -C <worktree> \
  -o <report.md> "<prompt>"
```

Use `-s workspace-write` instead of `read-only` when Codex implements. The prompt carries the
limits above and points at `BRIEF.md`. Check that `codex --version` works first.

## Brief and status

When work goes to a worker, or may outlive the session, two files sit at the root of the working
tree. Both are gitignored and never committed. Fill them from `templates/BRIEF.md` and
`templates/STATUS.md`.

- **`BRIEF.md`**, written once by the orchestrator: the goal; the acceptance criteria the owner
  confirmed, word for word; what is out of scope; the project rules that apply; the files to
  start from; how to verify, with commands and expected output; the limits.
- **`STATUS.md`**, updated by the worker after every step: done, with commit shas; in progress;
  the next step; check results with numbers; blockers and questions for the owner.

Any worker, or a new session on another account, reads both before anything else. A worker never
edits `BRIEF.md`. A change of scope goes back to the owner, who confirms a new brief.

## Claude Code facts this kit relies on

- Project `.claude/settings.json` keys `model` and `effortLevel` override the user's
  `~/.claude/settings.json`.
- Agent frontmatter supports `model` (`sonnet`, `opus`, `haiku`, `fable`, a full model id, or
  `inherit`), `effort` (`low`, `medium`, `high`, `xhigh`, `max`), `tools` and `disallowedTools`.
- The environment variable `CLAUDE_CODE_EFFORT_LEVEL` overrides an agent's `effort`. Unset it
  if an agent seems to run at the wrong level.
- Subagents can invoke skills and spawn subagents, up to three layers deep.

## Why not a difficulty classifier

Some setups label each task EASY, MEDIUM or HARD and pick a model from the label. This kit does
not.

- Handing a tiny edit to a cheaper model costs more than doing it: the brief, the wait and the
  review of the result outweigh the saving.
- A guessed label misfires. The model that guesses is the one that does not yet know the task.
- The signals used here can be read off the work: what kind of work it is, which paths it touches,
  which review pass it is. They give the same answer every time.

# Routing

How work is split across Claude models. This file is generic. A project keeps its own adapted copy.

## Principles

- Route by what the work is: the kind of work, the file paths it touches, the review pass type.
  Never route by a guess at how hard the work is.
- Two effort levels only. `high` for flow work. `xhigh` where a mistake is expensive or taste
  matters. There is no `low` or `medium`.
- The main session is the orchestrator. It talks to the owner and owns the commits.
- One task per session. A long session re-reads its whole context every turn, and that is the
  biggest quota cost. Finish or hand off the task, then start a new session.
- The routing table is the instruction that sets the Agent tool's `model` and `effort`.

## Roles

| Work                                                                                      | Worker                                            | Model, effort  | Why                                                    |
| ----------------------------------------------------------------------------------------- | ------------------------------------------------- | -------------- | ------------------------------------------------------ |
| Dialog, criteria, brief, status, small edits, commits                                     | the main session (orchestrator)                   | Sonnet, high   | Needs the owner's context and runs all the time        |
| A plan for a structural change: data shape, routing, build or CI config, design tokens    | `planner` agent, read-only                        | Opus, xhigh    | A wrong structure is costly to undo                    |
| Work that depends on taste: visual, copy, UX                                              | `crafter` agent                                   | Sonnet, xhigh  | Taste needs care, and Claude holds the project's voice |
| Code with no taste in it: tests, data, scripts, accessibility, performance, an exact plan | the main session (orchestrator)                   | Sonnet, high   | Has a check that passes or fails                       |
| Review, first pass or delta                                                               | `reviewer` agent                                  | Opus, high     | A context that did not write the code                  |
| Review when the change touches a high-risk path                                           | `reviewer` agent, `effort: xhigh`                 | Opus, xhigh    | A miss on a risky path is expensive                    |
| Review, trivial re-pass or comment-only pass                                              | general-purpose agent, `model: sonnet`            | Sonnet, high   | Little to find, so the cheaper model is enough         |
| Fix loop and QA after review                                                              | general-purpose agent, `model: sonnet`            | Sonnet, high   | Follows concrete findings                              |
| Review lens: bug hunt (`/code-review`), every pass but comment-only, not only risky ones  | general-purpose agent, `model: sonnet`, read-only | Sonnet, xhigh  | A missed bug costs more than the lens                  |
| Merge, once the review passes and CI is green                                             | the step the project assigns (below)              | the step's own | Who merges is project-specific                         |
| Objective audits: accessibility, performance, security scans                              | general-purpose agent, `model: sonnet`, read-only | Sonnet, high   | The result is measurable                               |
| Run check, build and test commands; search; count; summarise long output                  | `runner` agent, read-only                         | Haiku, high    | Cheap, and keeps long output out of the session        |

The owner can override any row: `/model opus` in a session, or a word in chat.

Who merges is project-specific. The merge happens after the review passes and CI is green, and
the project assigns it to one step. In the worked example the review step merges, never the
orchestrator's own session. Write the project's choice into its copy of this table.

## Rules

- **A small edit stays in the orchestrator.** Handing a one-line change to another model costs
  more than making it. A brief is for larger work, work for another worker, or work that may
  outlive the session.
- **Review runs in a context that did not write the code.** Use a fresh subagent or a new session.
- **Every delegated prompt repeats the limits** in the prompt text: read-only unless the step owns
  the edits, never push, never upgrade tools, never edit the agent docs unless the task is that.
  A skill's own preamble does not know the project's rules.
- **Read-only workers cannot write `STATUS.md`.** The planner, the runner and the read-only
  workers report progress in their reply. The orchestrator records it in `STATUS.md`.
- **Hand-off files.** A worker cannot see the orchestrator's conversation, and a quota limit or
  an account switch can end a session. See "Brief and status" below.

## Brief and status

When work goes to a worker, or may outlive the session, two files sit at the root of the working
tree. Both are gitignored and never committed. Fill them from `templates/BRIEF.md` and
`templates/STATUS.md`. Both belong to one task.

- **`BRIEF.md`**: the goal; the acceptance criteria the owner confirmed, word for word; what is
  out of scope; the project rules that apply; the files to start from; how to verify, with
  commands and expected output; the limits.
- **`STATUS.md`**: done, with commit shas; in progress; the next step; check results with
  numbers; blockers and questions for the owner.

Lifecycle:

1. The orchestrator writes both when the owner confirms the criteria.
2. `BRIEF.md` is written once. A worker never edits it. A change of scope goes back to the owner,
   who confirms a new brief.
3. `STATUS.md` is updated after every step. A worker with write access updates it. A read-only
   worker reports in its reply, and the orchestrator records it.
4. A new session on the same task, on any account, reads both before anything else and continues.
   It does not rewrite them.
5. A worker in a different worktree, such as the reviewer's own, does not see these gitignored
   files. The caller passes both by absolute path.
6. **Final step: delete both files** when the task ends: the pull request merged, the pull request
   closed, or the task ended without one. The next session then never picks up a finished task.

## Working model

One session, one task, one working copy. There are no parallel tasks in the same folder and no
per-task worktrees, because each worktree needs its own dependency install. If `BRIEF.md` for
another unfinished task is present, finish or close that task first.

- Task sessions start on Sonnet at `high`. The project `settings.json` sets that.
- A process or architecture discussion starts on Opus, chosen explicitly, and stays short.
- Implementation after such a discussion goes to a new Sonnet session. Do not switch models
  mid-session: a switch re-reads the whole context without the cache.

## Claude Code facts this kit relies on

- Project `.claude/settings.json` keys `model` and `effortLevel` override the user's
  `~/.claude/settings.json`.
- Agent frontmatter supports `model` (`sonnet`, `opus`, `haiku`, `fable`, a full model id, or
  `inherit`), `effort` (`low`, `medium`, `high`, `xhigh`, `max`), `tools` and `disallowedTools`.
- The environment variable `CLAUDE_CODE_EFFORT_LEVEL` overrides an agent's `effort`. Unset it
  if an agent seems to run at the wrong level.
- Subagents can invoke skills and spawn subagents, up to three layers deep.

## Why route by kind of work

Routing does not use a difficulty label such as EASY, MEDIUM or HARD.

- Handing a tiny edit to a cheaper model costs more than doing it: the brief, the wait and the
  review of the result outweigh the saving.
- A guessed label misfires. The model that guesses is the one that does not yet know the task.
- The signals used here can be read off the work: what kind of work it is, which paths it touches,
  which review pass it is. They give the same answer every time.

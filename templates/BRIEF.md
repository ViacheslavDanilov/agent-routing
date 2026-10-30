# Brief: <task name>

<!-- Belongs to ONE task. Written once by the orchestrator, when the owner confirms the criteria.
     Gitignored, never committed. Workers never edit it.
     A change of scope goes back to the owner, who confirms a new brief.
     A new session on the same task reads it and continues. It does not rewrite it.
     A worker in another worktree does not see it: the caller passes its absolute path.
     DELETE it, with STATUS.md, when the task ends: PR merged, PR closed, or no PR. -->

## Goal

<!-- One or two sentences. What changes and why. -->

## Acceptance criteria

<!-- The criteria the owner confirmed, word for word. Do not paraphrase. -->

- <criterion>

## Out of scope

<!-- What the worker must not touch, even if it looks related. -->

- <item>

## Project rules that apply

<!-- Name the sections of <conventions file> that matter here, not the whole file. -->

- <conventions file>: <section>

## Files to start from

- <path>

## How to verify

<!-- Commands and the output that means success. Use real numbers. -->

| Command           | Expected output                               |
| ----------------- | --------------------------------------------- |
| `<check command>` | <passes, no new errors>                       |
| `<test command>`  | <N passed, M pre-existing failures unchanged> |

## Limits

<!-- Repeat the delegation limits from the routing section. -->

- No push. No merge. No upgrade of any tool.
- Do not edit <agent docs file>, and do not create a `CLAUDE.md`.
- Codex does not commit. The orchestrator commits.
- Read `STATUS.md` first. Update it after every step, unless you are read-only: then report
  progress in your reply and the orchestrator records it.

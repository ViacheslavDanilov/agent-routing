# Status: <task name>

<!-- Belongs to ONE task. Written when the owner confirms the criteria, updated after every step.
     Gitignored, never committed.
     A worker with write access updates it. A read-only worker (planner, runner, a read-only worker)
     reports progress in its reply, and the orchestrator records it here.
     Read BRIEF.md first. Never edit it.
     A new session on the same task, on any account, reads both files and continues from "Next".
     It does not rewrite them.
     A worker in another worktree does not see this file: the caller passes its absolute path.
     DELETE it, with BRIEF.md, when the task ends: PR merged, PR closed, or no PR. -->

Last updated: <date, time>
Worker: <Crafter | orchestrator | other>

## Done

<!-- One line per step, newest last, with the commit sha. -->

- <step> (`<sha>`)

## In progress

- <what is open right now, and what state the working tree is in>

## Next

- <the single next step, specific enough for someone else to start it>

## Check results

<!-- Real numbers from the last run. Say which command and when. -->

| Command   | Result         |
| --------- | -------------- |
| `<check>` | <pass or fail> |

## Blockers and questions

<!-- For the owner. Empty if none. -->

- <question>

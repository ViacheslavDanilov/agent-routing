# Adopt the routing kit in this project

You are an agent. Adapt this kit to the project you were started in. The kit lives in this
directory. Read `ROUTING.md` first, then follow the steps below in order.

Rules for the whole task:

- Do not change the user's global settings (`~/.claude/`). Read them, never write.
- Do not edit the kit directory. Copy from it.
- Write nothing in the project until step 7 is confirmed by the owner.
- Never use an em dash in anything you write. Keep sentences short and plain.

## 1. Inspect the project

Find and note:

- Language and framework, and the package or build tool.
- The commands to check (lint, format), build and test. Run each once if it is cheap, and note
  what a pass looks like (exit code, counts).
- CI: where it is defined, and which commands it runs.
- Existing agent docs: `AGENTS.md`, `CLAUDE.md`, a conventions file, `.agents/skills/`,
  `.claude/skills/`, `.claude/agents/`, `.claude/settings.json`. Note what already exists. Do
  not duplicate it.
- Whether the owner uses the Antigravity CLI (`agy`). A second model family is optional; see
  "Optional: a second model family" in `ROUTING.md`.
- Git conventions: branch rules, commit format, pull request format, and which step merges (after
  the review passes and CI is green). Do not assume the orchestrator merges.

## 2. Check the environment

Run `echo $CLAUDE_CODE_EFFORT_LEVEL`. If it is set, tell the owner it overrides agent effort.

## 3. Check the authorship rules

Read the project's rules for commit messages and pull request text. Some projects forbid naming AI
tools or models there. If so, every commit and pull request that sets up routing must describe it
neutrally, for example "model tiers". The config files themselves keep the real model names. Keep the rule in mind for step 8 and for any commit you make.

## 4. Map the project's work onto the roles

For each row of the role table in `ROUTING.md`, name what it means here. Examples of questions:

- What work depends on taste in this project? Visual, copy, UX, API naming, docs prose? That is
  the crafter's work. If the project has none, drop the crafter row.
- What work has a check that passes or fails? Tests, data migrations, scripts, accessibility,
  performance? The orchestrator does it, and the check is the proof. Audits whose result is
  measurable go to a read-only general-purpose agent.
- What counts as a structural change? Data shape, routing, build or CI config, design tokens,
  public API? That goes to the planner.
- Which review skill does the project use? If none, the reviewer agent follows the repository's
  review rules, or `/code-review`.

Keep the two effort levels and the models from the kit unless the owner says otherwise.

## 5. Decide the high-risk paths

List the paths where a missed bug is expensive: auth, payments, data migrations, build and CI
config, secrets handling, public API, infrastructure. Use real paths or globs from the project.
These paths send a review to Opus at `xhigh`. Propose the list. Do not invent paths that do not
exist.

## 6. Draft the files

Draft in your head or in the scratchpad, not in the project:

- `.claude/settings.json` from `templates/settings.json`. If the file exists, add only the
  `model` and `effortLevel` keys and keep everything else.
- `.claude/agents/planner.md`, `crafter.md`, `reviewer.md`, `runner.md` from `templates/agents/`.
  Fill every `<placeholder>`: project name, conventions file, review skill, commands, high-risk
  paths. Drop an agent when its row is dropped. Prefix the names with the project if the owner
  likes it (for example `site-runner`).
- A routing section for the project's agent docs. Put it where the project keeps agent rules:
  `AGENTS.md` or its conventions file. Never create `CLAUDE.md` if the project uses `AGENTS.md`.
  The section holds the adapted role table, the rules, and the "Brief and status" protocol. Link
  to nothing in the kit directory: the project copy must stand alone. The rules it carries:
  - The bug-hunt lens (`/code-review`) runs on every review pass except a comment-only pass.
  - The merge happens after the review passes and CI is green, done by the one step the project
    assigns. Name that step. Never write "the orchestrator merges" unless the project says so.
  - `BRIEF.md` and `STATUS.md` belong to one task. Both are written when the owner confirms the
    criteria. `BRIEF.md` is written once and never edited by a worker. `STATUS.md` is updated
    after every step. A new session on the same task reads both and continues.
  - A read-only worker (planner, runner, read-only audits) reports progress in its reply, and the
    orchestrator records it in `STATUS.md`.
  - A worker in another worktree, such as the reviewer's, does not see the gitignored files. The
    caller passes both by absolute path.
  - Final step: delete `BRIEF.md` and `STATUS.md` when the task ends (pull request merged or
    closed, or no pull request), so the next session never picks up a finished task.
  - One session, one task, one working copy. If `BRIEF.md` for another unfinished task is
    present, finish or close that task first.
  - Task sessions start on Sonnet at `high`. Process or architecture talks start on Opus and stay
    short. Implementation after them goes to a new Sonnet session.
- Skills in `.agents/skills/`, with `.claude/skills` a symlink to them, as "Where skills
  live" in `ROUTING.md` says. Move existing skills with `git mv` so their history stays.
- `.gitignore` entries: `BRIEF.md` and `STATUS.md`. Do not duplicate existing lines.

## 7. Ask the owner, then wait

Show the owner, in one message:

1. The adapted role table (work, worker, model and effort).
2. The high-risk paths.
3. The list of files you will create or change, with one line on each.
4. What you could not map, and what you assumed.

Then stop. Do not write a file until the owner confirms in plain words. If the owner changes a
row, redraw the table and ask again.

## 8. Write and verify

After confirmation:

1. Write the files from step 6.
2. Run the project's check command. It must pass.
3. Check that agent frontmatter is valid: `name`, `description`, `model`, `effort`, and
   `disallowedTools` where the template has it.
4. Check there is no em dash in what you wrote: `grep -rnP "\x{2014}" .claude <agent docs file>`.
5. Check `git status` shows `BRIEF.md` and `STATUS.md` ignored, and nothing outside the planned
   list changed.
6. Do not commit unless the project's rules and the owner say so. Follow the project's own
   commit and branch rules if you do, and the authorship rule from step 3: neutral wording, no AI
   tool or model vendor named in a commit message or pull request text.

## 9. Report

Tell the owner, in under 150 words: the files created or changed, what the check printed, what
you dropped or assumed, and one line on how to start: one task per session, and the orchestrator
writes `BRIEF.md` and `STATUS.md` before it hands work to a worker, and deletes both when the
task ends.

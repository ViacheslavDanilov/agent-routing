# Adopt the routing kit in this project

You are an agent. Adapt this kit to the project you were started in. The kit lives in this
directory. Read `ROUTING.md` first, then follow the steps below in order.

Rules for the whole task:

- Do not change the user's global settings (`~/.claude/`, `~/.codex/`). Read them, never write.
- Do not edit the kit directory. Copy from it.
- Write nothing in the project until step 6 is confirmed by the owner.
- Never use an em dash in anything you write. Keep sentences short and plain.

## 1. Inspect the project

Find and note:

- Language and framework, and the package or build tool.
- The commands to check (lint, format), build and test. Run each once if it is cheap, and note
  what a pass looks like (exit code, counts).
- CI: where it is defined, and which commands it runs.
- Existing agent docs: `AGENTS.md`, `CLAUDE.md`, a conventions file, `.claude/skills/`,
  `.claude/agents/`, `.claude/settings.json`. Note what already exists. Do not duplicate it.
- Git conventions: branch rules, commit format, pull request format, who may merge.

## 2. Check the tools

- Run `codex --version`. If it fails, Codex is missing: say so, and plan the Codex rows on the
  Claude equivalent (see "If Codex is missing" in `ROUTING.md`).
- If Codex is present, read `~/.codex/config.toml` for `model` and `model_reasoning_effort`. Use
  the configured model in the command template. The kit assumes `gpt-6.1-sol` at `xhigh`.
- Run `echo $CLAUDE_CODE_EFFORT_LEVEL`. If it is set, tell the owner it overrides agent effort.

## 3. Map the project's work onto the roles

For each row of the role table in `ROUTING.md`, name what it means here. Examples of questions:

- What work depends on taste in this project? Visual, copy, UX, API naming, docs prose? That is
  the crafter's work. If the project has none, drop the crafter row.
- What work has a check that passes or fails? Tests, data migrations, scripts, accessibility,
  performance? That is Codex's work.
- What counts as a structural change? Data shape, routing, build or CI config, design tokens,
  public API? That goes to the planner.
- Which review skill does the project use? If none, the reviewer agent follows the repository's
  review rules, or `/code-review`.

Keep the two effort levels and the models from the kit unless the owner says otherwise.

## 4. Decide the high-risk paths

List the paths where a missed bug is expensive: auth, payments, data migrations, build and CI
config, secrets handling, public API, infrastructure. Use real paths or globs from the project.
These paths send a review to Opus at `xhigh`. Propose the list. Do not invent paths that do not
exist.

## 5. Draft the files

Draft in your head or in the scratchpad, not in the project:

- `.claude/settings.json` from `templates/settings.json`. If the file exists, add only the
  `model` and `effortLevel` keys and keep everything else.
- `.claude/agents/planner.md`, `crafter.md`, `reviewer.md`, `runner.md` from `templates/agents/`.
  Fill every `<placeholder>`: project name, conventions file, review skill, commands, high-risk
  paths. Drop an agent when its row is dropped. Prefix the names with the project if the owner
  likes it (for example `site-runner`).
- A routing section for the project's agent docs. Put it where the project keeps agent rules:
  `AGENTS.md` or its conventions file. Never create `CLAUDE.md` if the project uses `AGENTS.md`.
  The section holds the adapted role table, the rules, the Codex command with the project's
  worktree, and the "Brief and status" protocol. Link to nothing in the kit directory: the project
  copy must stand alone.
- `.gitignore` entries: `BRIEF.md` and `STATUS.md`. Do not duplicate existing lines.

## 6. Ask the owner, then wait

Show the owner, in one message:

1. The adapted role table (work, worker, model and effort).
2. The high-risk paths.
3. The list of files you will create or change, with one line on each.
4. What you could not map, and what you assumed.
5. Whether Codex is present, and the model it will use.

Then stop. Do not write a file until the owner confirms in plain words. If the owner changes a
row, redraw the table and ask again.

## 7. Write and verify

After confirmation:

1. Write the files from step 5.
2. Run the project's check command. It must pass.
3. Check that agent frontmatter is valid: `name`, `description`, `model`, `effort`, and
   `disallowedTools` where the template has it.
4. Check there is no em dash in what you wrote: `grep -rnP "\x{2014}" .claude <agent docs file>`.
5. Check `git status` shows `BRIEF.md` and `STATUS.md` ignored, and nothing outside the planned
   list changed.
6. Do not commit unless the project's rules and the owner say so. Follow the project's own
   commit and branch rules if you do.

## 8. Report

Tell the owner, in under 150 words: the files created or changed, what the check printed, what
you dropped or assumed, and one line on how to start: one task per session, and the orchestrator
writes `BRIEF.md` before it hands work to another model.

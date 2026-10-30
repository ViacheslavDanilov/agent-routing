# Agent routing kit

A small, project-agnostic template for routing work across Claude and Codex models. A Claude Code
session in any project reads it and adapts it into that project's own `.claude/` setup.

The kit gives you:

- A role table: which model and effort handles which kind of work.
- Agent templates (planner, crafter, reviewer, runner) with the model and effort pinned.
- A hand-off protocol (`BRIEF.md` and `STATUS.md`) so a quota limit or an account switch loses
  nothing.
- Instructions written for an agent that adapts all of this to a new project.

Work is routed by what it is, never by a guess at how hard it is. See `ROUTING.md`.

## Adopt it in a new project

Start a new session in the project and send:

```text
Read /Users/viacheslav/projects/personal/agent-routing/ADOPT.md and adapt the routing to this project
```

The agent inspects the project, shows an adapted table, and waits for your confirmation before it
writes anything. It never changes your global settings.

## Flow

```mermaid
sequenceDiagram
    autonumber
    actor Owner
    participant Orch as Orchestrator<br/>main session<br/>Sonnet, high
    participant Plan as Planner<br/>Opus, xhigh<br/>read-only
    participant Work as Worker<br/>Codex gpt-6.1-sol, xhigh (no taste)<br/>or Crafter Sonnet, xhigh (taste)
    participant Run as Runner<br/>Haiku, high<br/>read-only
    participant Rev as Reviewer<br/>Opus, high (xhigh on risky paths)<br/>+ Codex lenses, xhigh
    participant Fix as Fix loop and QA<br/>Sonnet, high

    Owner->>Orch: task, decisions
    Orch->>Owner: questions, acceptance criteria
    Owner-->>Orch: criteria confirmed
    Note over Orch: Small edits stay in the orchestrator.<br/>No brief, no hand-off.
    opt Structural change only (data shape, routing, build or CI config, tokens)
        Orch->>Plan: goal and criteria
        Plan-->>Orch: plan, steps with checks, risks
    end
    Orch->>Orch: write BRIEF.md (once, gitignored)
    rect rgba(120, 140, 200, 0.15)
        Note over Orch,Work: Worker box: reads BRIEF.md first, never edits it
        Orch->>Work: delegate by kind of work
        Work->>Work: commits and STATUS.md after every step
        Work-->>Orch: report, questions
    end
    Orch->>Run: run check, build, tests
    Run-->>Orch: pass or fail, counts, first error lines
    Orch->>Orch: read diff, commit, open PR
    rect rgba(200, 140, 120, 0.15)
        Note over Orch,Rev: Review in a context that did not write the code
        Orch->>Rev: PR number and brief
        Rev-->>Orch: findings by severity
    end
    loop Until no must-fix is open
        Orch->>Fix: fix findings, one commit per fix
        Fix-->>Orch: fixes pushed
        Orch->>Rev: delta pass (trivial passes on Sonnet, high)
        Rev-->>Orch: findings by severity
    end
    Orch->>Orch: merge (owner confirmed, CI green, review ready)
    Orch->>Owner: summary, open questions
    Note over Orch,Work: Quota out: another account reads<br/>BRIEF.md and STATUS.md and continues.
```

<img src="diagram/routing.svg" alt="Sequence diagram of the routing flow from owner to orchestrator, planner, worker, runner, reviewer, fix loop and merge" width="100%">

## Routing table

| Work                                                                                      | Worker                                 | Model, effort      |
| ----------------------------------------------------------------------------------------- | -------------------------------------- | ------------------ |
| Dialog, criteria, brief, small edits, commits, merge                                      | the main session (orchestrator)        | Sonnet, high       |
| A plan for a structural change: data shape, routing, build or CI config, design tokens    | `planner` agent, read-only             | Opus, xhigh        |
| Work that depends on taste: visual, copy, UX                                              | `crafter` agent                        | Sonnet, xhigh      |
| Code with no taste in it: tests, data, scripts, accessibility, performance, an exact plan | Codex, `workspace-write`               | gpt-6.1-sol, xhigh |
| Review, first pass or delta                                                               | `reviewer` agent                       | Opus, high         |
| Review when the change touches a high-risk path                                           | `reviewer` agent, `effort: xhigh`      | Opus, xhigh        |
| Review, trivial re-pass or comment-only pass                                              | general-purpose agent, `model: sonnet` | Sonnet, high       |
| Fix loop and QA after review                                                              | general-purpose agent, `model: sonnet` | Sonnet, high       |
| Review lenses (bug hunt, second opinion) and objective audits                             | Codex, `read-only`                     | gpt-6.1-sol, xhigh |
| Run check, build and test commands; search; count; summarise long output                  | `runner` agent, read-only              | Haiku, high        |

## Files

| Path                            | Purpose                                                      |
| ------------------------------- | ------------------------------------------------------------ |
| `ADOPT.md`                      | Steps for an agent adapting the kit to a project             |
| `ROUTING.md`                    | Principles, role table, rules, Codex command, hand-off files |
| `templates/settings.json`       | Project `model` and `effortLevel`                            |
| `templates/BRIEF.md`            | Skeleton the orchestrator fills once per task                |
| `templates/STATUS.md`           | Skeleton the worker updates after every step                 |
| `templates/agents/*.md`         | Planner, crafter, reviewer and runner with placeholders      |
| `diagram/routing.{mmd,svg,png}` | The flow diagram, source and renders                         |

## Worked example

A project-specific instance of this kit lives in `/Users/viacheslav/projects/personal/vdanilov`
(a Next.js portfolio site):

- `.claude/skills/shared/site-conventions.md`, sections "Model routing" and "Brief and status"
- `.claude/agents/site-planner.md`, `site-crafter.md`, `site-reviewer.md`, `site-runner.md`
- `.claude/settings.json`

## Keeping the kit and the copies in sync

- The kit is the template. Each project owns its adapted copy and may change it freely.
- A project never reads the kit at run time. The copy must stand alone.
- When you find an improvement in a project, bring it back here by hand. Strip the project's names
  and paths first, then update the templates and `ROUTING.md`.
- When the kit improves, existing projects do not change on their own. Ask a session to compare the
  project copy with the kit and propose the differences.

# Agent routing kit

A small, project-agnostic template for routing work across Claude models. A Claude Code
session in any project reads it and adapts it into that project's own `.claude/` setup.

The kit gives you:

- A role table (in `ROUTING.md`): which model and effort handles which kind of work.
- Agent templates (planner, crafter, reviewer, runner) with the model and effort pinned.
- A hand-off protocol (`BRIEF.md` and `STATUS.md`) so a quota limit or an account switch loses
  nothing.
- Instructions written for an agent that adapts all of this to a new project.

Work is routed by what it is, never by a guess at how hard it is. The role table, the rules and
the working model (one session, one task) are in `ROUTING.md`.

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
    participant Craft as Crafter<br/>Sonnet, xhigh<br/>(taste work)
    participant Run as Runner<br/>Haiku, high<br/>read-only
    participant Rev as Reviewer<br/>Opus, high (xhigh on risky paths)
    participant Fix as Fix loop and QA<br/>Sonnet, high

    Owner->>Orch: task, decisions
    Orch->>Owner: questions, acceptance criteria
    Owner-->>Orch: criteria confirmed
    Note over Orch: Small edits stay in the orchestrator.<br/>No brief, no hand-off.
    opt Structural change only (data shape, routing, build or CI config, tokens)
        Orch->>Plan: goal and criteria
        Plan-->>Orch: plan, steps with checks, risks<br/>(read-only: Orch records STATUS.md)
    end
    Orch->>Orch: write BRIEF.md and STATUS.md (gitignored, one task)
    opt Taste work only (visual, copy, UX)
        rect rgba(120, 140, 200, 0.15)
            Note over Orch,Craft: Crafter: reads BRIEF.md first, never edits it
            Orch->>Craft: delegate the work
            Craft->>Craft: commits, STATUS.md after every step
            Craft-->>Orch: report, questions
        end
    end
    Orch->>Run: run check, build, tests
    Run-->>Orch: pass or fail, counts, first error lines<br/>(read-only: Orch records STATUS.md)
    Orch->>Orch: read diff, commit, open PR
    rect rgba(200, 140, 120, 0.15)
        Note over Orch,Rev: Review in a context that did not write the code.<br/>The bug-hunt lens (/code-review) runs on every pass except comment-only.
        Orch->>Rev: PR number, BRIEF.md and STATUS.md paths
        Rev-->>Orch: findings by severity
    end
    loop Until no must-fix is open
        Orch->>Fix: fix findings, one commit per fix
        Fix-->>Orch: fixes pushed
        Orch->>Rev: delta pass (trivial passes on Sonnet, high)
        Rev-->>Orch: findings by severity
    end
    Note over Rev: Merge once the review passes and CI is green,<br/>by the step the project assigns
    Rev-->>Orch: verdict, merged or not
    Note over Orch: Final step: delete BRIEF.md and STATUS.md<br/>(PR merged, PR closed, or no PR)
    Orch->>Owner: summary, open questions
    Note over Orch,Craft: Quota out: another account reads<br/>BRIEF.md and STATUS.md and continues, no rewrite.
```

## Files

| Path                               | Purpose                                                           |
| ---------------------------------- | ----------------------------------------------------------------- |
| `ADOPT.md`                         | Steps for an agent adapting the kit to a project                  |
| `ROUTING.md`                       | Principles, role table, rules, hand-off files                     |
| `templates/settings.json`          | Project `model` and `effortLevel`                                 |
| `templates/BRIEF.md`               | Skeleton the orchestrator fills once per task, then deletes       |
| `templates/STATUS.md`              | Skeleton updated after every step, then deleted with the brief    |
| `templates/agents/*.md`            | Planner, crafter, reviewer and runner with placeholders           |
| `GITHUB-SETTINGS.md`               | GitHub repository standard (merging, protection, Actions, labels) |
| `scripts/apply-github-standard.sh` | Applies that standard to one repository                           |

## Worked example

A project-specific instance of this kit lives in `/Users/viacheslav/projects/personal/vdanilov`
(a Next.js portfolio site):

- `.agents/skills/shared/site-conventions.md`, sections "Model routing" and "Brief and status"
- `.agents/agents/site-planner.md`, `site-crafter.md`, `site-reviewer.md`, `site-runner.md`
- `.claude/settings.json`

`.claude/skills` and `.claude/agents` are symlinks into `.agents/`.

## Keeping the kit and the copies in sync

- The kit is the template. Each project owns its adapted copy and may change it freely.
- A project never reads the kit at run time. The copy must stand alone.
- When you find an improvement in a project, bring it back here by hand. Strip the project's names
  and paths first, then update the templates and `ROUTING.md`.
- When the kit improves, existing projects do not change on their own. Ask a session to compare the
  project copy with the kit and propose the differences.

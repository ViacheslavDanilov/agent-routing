# GitHub repository standard

One set of GitHub settings for every repository the owner runs. It matches how the agents work:
every change lands through a pull request, the pull request title becomes the commit on `main`,
and an agent merges only after CI is green and the review passes.

Apply it with:

```bash
scripts/apply-github-standard.sh OWNER/REPO --dry-run   # print what would change
scripts/apply-github-standard.sh OWNER/REPO             # apply
```

The script reads the required checks from the repository's current protection. For a new
repository with none yet, pass each CI job name with `--check "Job name"`. Before it changes
anything, it saves the current settings to `backups/<repo>-<timestamp>/` (gitignored), so a
setting can be restored by hand.

## Merging

| Setting                       | Value              | Why                                                   |
| ----------------------------- | ------------------ | ----------------------------------------------------- |
| Merge methods                 | squash only        | One commit per pull request on `main`                 |
| Squash commit title           | pull request title | The title is written for `main`; agents keep it short |
| Squash commit message         | blank              | Commit subjects inside the branch stay out of `main`  |
| Delete the branch after merge | on                 | No stale branches                                     |
| Auto-merge                    | off                | The agent merges once its own conditions hold         |

## Protection of the default branch

One ruleset named `main`, active, with no bypass, replaces classic branch protection. Classic
protection is removed, so the rules live in one place.

| Rule                                | Value                                             |
| ----------------------------------- | ------------------------------------------------- |
| Changes only through a pull request | on, squash only                                   |
| Required approvals                  | 0: an owner cannot approve their own pull request |
| Code owner review                   | off: no repository has a CODEOWNERS file          |
| Dismiss stale approvals on push     | on                                                |
| Conversations resolved before merge | on                                                |
| Required status checks              | every CI job, and the branch must be up to date   |
| Force push                          | blocked                                           |
| Deleting the branch                 | blocked                                           |
| Linear history                      | on                                                |
| Signed commits                      | on: squash merges made by GitHub are signed       |
| Bypass                              | none, the owner included                          |

With no bypass, a red check blocks the owner too. In an emergency, switch the ruleset to
`disabled` in the repository settings, merge, and switch it back.

## Actions

| Setting                             | Value | Why                                                         |
| ----------------------------------- | ----- | ----------------------------------------------------------- |
| Default `GITHUB_TOKEN` permissions  | read  | A workflow that needs to write declares it in `permissions` |
| Workflows may approve pull requests | off   | Nothing uses it                                             |

## Labels

One label for each Conventional Commit type, plus GitHub's triage labels, in one palette. A
pull request carries one label for each commit type among its commits. Labels a project adds for
itself, such as `bib` or `fig`, stay as they are.

| Label              | Commit type | Color     |
| ------------------ | ----------- | --------- |
| `enhancement`      | `feat`      | `#a2eeef` |
| `bug`              | `fix`       | `#d73a4a` |
| `documentation`    | `docs`      | `#0075ca` |
| `style`            | `style`     | `#c5def5` |
| `refactor`         | `refactor`  | `#1d76db` |
| `perf`             | `perf`      | `#fbca04` |
| `test`             | `test`      | `#0e8a16` |
| `ci`               | `ci`        | `#5319e7` |
| `build`            | `build`     | `#006b75` |
| `chore`            | `chore`     | `#ededed` |
| `duplicate`        | closed      | `#cfd3d7` |
| `invalid`          | closed      | `#e4e669` |
| `wontfix`          | closed      | `#ffffff` |
| `question`         | triage      | `#d876e3` |
| `help wanted`      | triage      | `#008672` |
| `good first issue` | triage      | `#7057ff` |

## Security

Secret scanning and push protection are on wherever GitHub offers them. GitHub does not offer
them for a private repository on a personal account, and the script skips them there.

## Applied

| Repository                            | Date       | Notes                                    |
| ------------------------------------- | ---------- | ---------------------------------------- |
| `ViacheslavDanilov/vdanilov`          | 2026-10-30 | added `E2E Tests` to the required checks |
| `ViacheslavDanilov/video-bokeh`       | 2026-10-30 | replaced a disabled ruleset              |
| `ViacheslavDanilov/video-bokeh-paper` | 2026-10-30 | private: no secret scanning              |

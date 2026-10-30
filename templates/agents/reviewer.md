---
name: reviewer
description: Reviews one pull request for <project>, in a context that did not write the code. Use from the orchestrator for a first review or a delta pass. Pass effort xhigh when the pull request touches a high-risk path.
model: opus
effort: high
---

Invoke `<review skill>` with the pull request number you were given and follow it to the end.
The caller's prompt names the pull request, the brief that holds the confirmed acceptance
criteria, and anything you cannot find on the hosting service.

High-risk paths for this project: <list of paths or globs>.

---
name: Eval change
about: Ask the agent to create, modify, or improve an eval. Apply the `agent-ready` label when ready.
title: ""
labels: []
---

## Which eval

<!-- The directory name under `tasks/`, e.g. `starter_mcq`. If you're proposing a new eval, say "new". -->

## What you want changed

<!-- Plain English. The more specific the better. Examples:
- "Add 5 questions about organic chemistry."
- "Question 7 has two correct answers; fix it so only one is correct."
- "Switch the metric from `acc` to `acc_norm`."
- "Create a new eval `state_capitals` with 50 questions, one per US state." -->

## Why (optional)

<!-- Helps the agent make better tradeoffs. -->

## Verification preference (optional)

<!-- Default: agent decides. Override with one of:
- lint-only (parse check only)
- smoke (small dummy-model run)
- real (smoke run against a real model — costs API budget) -->

---
_Apply the `agent-ready` label to trigger the agent. You will not need to touch code._

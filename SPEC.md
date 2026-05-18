# eval_evolve

## Principle

Build LLM evaluations — and improve existing ones (lm-evaluation-harness as the starting reference) — under one invariant:

**Humans never touch code. Every modification is driven by a human-filed issue and executed by an agent.**

Humans express *intent* in natural language. The agent translates intent into code. Humans review and merge; they do not edit.

## How it works

1. A human files a GitHub issue describing a desired change (new eval, modification, bug, improvement).
2. The issue is labeled `agent-ready`.
3. A GitHub Action fires, invoking an agent built on the Claude Agent SDK.
4. The agent posts a **plan** as a comment on the issue (what it will change and why).
5. The agent implements the change, scoped to the `tasks/` directory.
6. The agent decides — per change — how to verify the result (lint-only, smoke run on a cheap model, full eval run, etc.) and includes the verification report in the PR description.
7. The agent opens a PR. **It does not merge.**
8. A human reviews the PR.
   - If approved: human merges. This is the only permanent change path.
   - If wrong: human leaves PR review comments. The agent picks them up and pushes a new commit.
   - If unsalvageable: close the PR, refine the issue, re-label.

Humans never edit code. Iteration happens in natural language on issues and PRs.

## Architecture decisions

| Axis | Choice |
|---|---|
| Eval substrate | `lm-evaluation-harness` as a pinned dependency |
| Issue intake | GitHub Issues on this repo |
| Agent runtime | GitHub Action, triggered on issue label `agent-ready` |
| Agent implementation | `anthropics/claude-code-action@v1` |
| Authoring workflow | Plan-first: post plan as issue comment, then implement |
| Verification | Agent's judgment per-issue; report attached to PR |
| Merge gate | Human-only; enforced by branch protection on `main` |
| Escape hatch | PR review comments → agent iterates |
| Agent's editable surface | `tasks/` directory only |

## Repo layout

```
eval_evolve/
  README.md
  CLAUDE.md                  # standing instructions for the agent
  SPEC.md                    # this file
  pyproject.toml             # uv project, pins lm-eval
  uv.lock
  tasks/                     # agent's playground — only place it edits
    starter_mcq/             # toy eval for the first vertical slice
      task.yaml
      data.jsonl
      README.md
  agent/                     # the issue→PR agent
    prompts/                 # system prompt, plan template, PR template
                             # (loaded by the action's `prompt` input)
  scripts/
    smoke_run.py             # cheap verification helper
  .github/
    workflows/
      agent.yml              # fires on issue labeled `agent-ready`
      agent-followup.yml     # fires on PR review comments
    ISSUE_TEMPLATE/
      eval-change.md
```

## First vertical slice

Prove the whole loop end-to-end with the smallest possible change:

1. Ship one toy eval at `tasks/starter_mcq/` (~10 hand-written multiple-choice questions).
2. File an issue: "Make question 3 harder by changing the answer choices."
3. Agent plans, edits the YAML, runs a smoke check, opens a PR.
4. Human reviews and merges.

Every later capability is an extension of a working loop, not a new system.

## Constraints and rules for the agent

- **Edit only `tasks/`.** Never modify `agent/`, workflows, `pyproject.toml`, or anything else.
- **Don't merge.** Open the PR and stop.
- **Plan before implementing.** Post the plan as an issue comment first.
- **Pick verification depth by the size of the change.** Justify the choice in the PR description.
- **Treat PR review comments as direct human intent.** Iterate on them.
- **Stay scoped.** Do the smallest change that satisfies the issue.

## Open decisions (pre-build)

- Auth: `ANTHROPIC_API_KEY` in GitHub Actions secrets (or `CLAUDE_CODE_OAUTH_TOKEN` via the Claude GitHub App).
- Default agent model: `claude-sonnet-4-6` to start; upgrade to `claude-opus-4-7` if quality requires it.
- Branch protection on `main`: required reviewers ≥ 1 before this is real.

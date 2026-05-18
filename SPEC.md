# eval_evolve

## Principle

Build LLM evaluations — and improve existing ones — under one invariant:

**Humans never touch code. Every modification is driven by a human-filed issue and executed by an agent.**

Humans express *intent* in natural language. The agent translates intent into code. Humans review and merge; they do not edit.

The repo is **harness-agnostic by construction**: lm-evaluation-harness is the first supported framework, but HELM, Inspect, and others can be added by bootstrapping a new `harnesses/<name>/` directory without restructuring anything else.

## How it works

1. A human files a GitHub issue describing a desired change (new eval, modification, port from upstream, bug, improvement).
2. The issue is labeled `agent-ready`.
3. A GitHub Action fires, invoking `anthropics/claude-code-action@v1`.
4. The agent infers which harness the issue concerns, then reads `harnesses/<harness>/HARNESS.md` for its conventions.
5. The agent posts a **plan** as a comment on the issue (what it will change and why).
6. The agent implements the change in `tasks/<harness>/<task>/` (or, if needed, bootstraps a new harness under `harnesses/<new>/`).
7. The agent decides — per change — how to verify (lint-only, smoke run on a cheap model, full eval run) using `scripts/smoke_run.py`, and includes the verification report in the PR description.
8. The agent opens a PR. **It does not merge.**
9. A human reviews the PR.
   - Approved → human merges. Only path to permanent change.
   - Wrong → human leaves PR review comments. Agent picks them up, pushes a new commit.
   - Unsalvageable → close the PR, refine the issue, re-label.

Humans never edit code. Iteration happens in natural language on issues and PRs.

## Architecture decisions

| Axis | Choice |
|---|---|
| Eval substrates | Multiple harnesses supported; lm-evaluation-harness on day 1 |
| Harness routing | Subdirectory per harness: `tasks/<harness>/...` and `harnesses/<harness>/...` |
| Per-harness conventions | `harnesses/<name>/HARNESS.md` — minimal agent-facing cheatsheet |
| Per-harness runner | `harnesses/<name>/smoke.sh` — fixed CLI shape |
| Top-level runner | `scripts/smoke_run.py` — thin dispatcher, harness-agnostic |
| Upstream source | Read from installed packages (`.venv/lib/.../`) — not GitHub |
| Issue intake | GitHub Issues on this repo |
| Agent runtime | GitHub Action, triggered on issue label `agent-ready` |
| Agent implementation | `anthropics/claude-code-action@v1` |
| Authoring workflow | Plan-first: post plan as issue comment, then implement |
| Issue → harness routing | Agent infers from issue body; asks if ambiguous |
| Unknown harness | Agent bootstraps freely (relies on human merge gate) |
| Verification | Agent's judgment per-issue; report attached to PR |
| Edit scope | Repo-wide; agent flags self-modifying / CI / SPEC changes loudly in PR |
| Merge gate | Human-only; enforced by branch protection on `main` |
| Escape hatch | PR review comments → agent iterates |

## Repo layout

```
eval_evolve/
  README.md
  CLAUDE.md                            # standing instructions for the agent
  SPEC.md                              # this file
  pyproject.toml                       # uv project; deps grow as harnesses are added
  uv.lock
  harnesses/                           # READ-ONLY reference + per-harness runners
    lm_eval/
      HARNESS.md                       # cheatsheet for writing lm-eval tasks
      smoke.sh                         # runner for lm-eval tasks
  tasks/                               # AGENT'S PLAYGROUND
    lm_eval/
      starter_mcq/                     # seed eval
        task.yaml
        data.jsonl
        README.md
  agent/
    prompts/                           # loaded by the action's `prompt` input
      system.md
      plan_template.md
      pr_template.md
  scripts/
    smoke_run.py                       # harness-agnostic dispatcher
  .github/
    workflows/
      agent.yml                        # on issue labeled `agent-ready`
      agent-followup.yml               # on PR review comments
    ISSUE_TEMPLATE/
      eval-change.md
```

## Bootstrapping a new harness

When an issue concerns a harness not yet in `harnesses/`, the agent:

1. Adds the framework via `uv add <package>`.
2. Writes `harnesses/<new>/HARNESS.md` mirroring the structure of existing ones (what it is, layout, required files, run command, gotchas, worked example).
3. Writes `harnesses/<new>/smoke.sh` with the standard CLI: `smoke.sh <task_dir> <model> <limit> <output_dir>`.
4. Optionally adds a result-renderer in `scripts/smoke_run.py` (otherwise the generic fallback is used).
5. Proceeds with the original issue.

Bootstrap PRs are flagged prominently in the description so the reviewer can vet the new integration.

## Constraints and rules for the agent

- **Read `harnesses/<harness>/HARNESS.md` before editing tasks in that harness.**
- **Don't merge.** Open the PR and stop.
- **Plan before implementing.** Post the plan as an issue comment first.
- **Stay scoped.** Do the smallest change that satisfies the issue.
- **Use `scripts/smoke_run.py` for verification** — never invoke harnesses directly, so reports stay uniform.
- **Treat PR review comments as direct human intent.** Iterate on them.
- **Flag self-modifying / CI / SPEC changes** in the FIRST line of the PR description.

## Open decisions (pre-build)

- Auth: `CLAUDE_CODE_OAUTH_TOKEN` (set by the Claude GitHub App). Alternative: `ANTHROPIC_API_KEY`.
- Default agent model: `claude-sonnet-4-6` to start; upgrade to `claude-opus-4-7` if quality requires it.
- Branch protection on `main`: required reviewers ≥ 1 before this is real.

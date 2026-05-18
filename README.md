# eval_evolve

LLM evals built and improved by an agent, driven entirely by human-filed GitHub issues. **Humans never touch code.**

Harness-agnostic by construction. Starts with [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness); new harnesses (HELM, Inspect, etc.) can be bootstrapped by adding a `harnesses/<name>/` directory.

## The loop

1. A human files a GitHub issue describing an eval change (use the *Eval change* template).
2. Apply the `agent-ready` label.
3. A GitHub Action invokes [`anthropics/claude-code-action@v1`](https://github.com/anthropics/claude-code-action).
4. The agent infers which harness the issue concerns, reads that harness's `HARNESS.md`, and posts a **plan** as a comment on the issue.
5. The agent implements the change in `tasks/<harness>/<task>/`, runs a smoke check via `scripts/smoke_run.py`, and opens a PR with the verification report attached.
6. A human reviews the PR.
   - Approve → merge. (Only path to permanent change.)
   - Comment → agent picks up the comment, pushes a new commit.
   - Close → discarded.

Humans only ever express intent. The agent does all the typing.

## Key features

- **Harness-agnostic layout** — each harness gets its own `harnesses/<name>/HARNESS.md` (reference) and `harnesses/<name>/smoke.sh` (runner). Tasks live under `tasks/<harness>/<task>/`. Adding a harness = adding one directory.
- **Read-from-installed-packages** — when porting upstream evals (BBH, MMLU, etc.), the agent reads from `.venv/lib/.../<harness>/` instead of GitHub, keeping behavior deterministic with the pinned version.
- **Issue-triggered agent** — `.github/workflows/agent.yml` fires on label `agent-ready`; the action runs with the standing rules from `agent/prompts/system.md`.
- **Plan-first authoring** — agent posts a plan comment on the issue before any code is written.
- **PR-review iteration** — `.github/workflows/agent-followup.yml` fires on review comments on `agent/*` branches; the action re-runs with the comments as context.
- **Verification dispatcher** — `scripts/smoke_run.py` identifies the harness from the task path, delegates to `harnesses/<x>/smoke.sh`, and renders a uniform markdown report.
- **Harness bootstrapping** — if an issue requests a harness not yet present, the agent installs the framework, writes a new `HARNESS.md` + `smoke.sh`, and flags the bootstrap prominently in the PR.
- **Human-only merge gate** — agent never merges; enforce with branch protection on `main`.

## Repo layout

```
eval_evolve/
  README.md                        # this file
  CLAUDE.md                        # standing context for Claude Code sessions
  SPEC.md                          # design principle + architecture decisions
  pyproject.toml                   # uv project; deps grow as harnesses are added
  harnesses/                       # READ-ONLY reference + per-harness runners
    lm_eval/
      HARNESS.md                   # cheatsheet for writing lm-eval tasks
      smoke.sh                     # runner: <task_dir> <model> <limit> <output_dir>
  tasks/                           # AGENT'S PLAYGROUND
    lm_eval/
      starter_mcq/                 # 10-question MCQ seed eval
        task.yaml
        data.jsonl
        README.md
  agent/
    prompts/                       # loaded by the action's `prompt` input
      system.md                    # operational rules for the agent
      plan_template.md
      pr_template.md
  scripts/
    smoke_run.py                   # harness-agnostic dispatcher
  .github/
    workflows/
      agent.yml                    # on issue labeled `agent-ready`
      agent-followup.yml           # on PR review comments
    ISSUE_TEMPLATE/
      eval-change.md
```

## Filing your first issue

1. Open a new issue, pick the *Eval change* template.
2. Fill in: which eval (or "new"), what change you want, optionally why.
3. Add the `agent-ready` label.
4. Wait. The agent will:
   - post a plan as a comment within a couple of minutes,
   - open a PR,
   - leave the PR open for you to review.
5. Comment on the PR if it needs adjustment, or merge.

## Setup (one-time)

- Install the Claude GitHub App on this repo (`/install-github-app` from Claude Code, or follow [the action's setup guide](https://github.com/anthropics/claude-code-action#quick-start)).
- Repo secret: `CLAUDE_CODE_OAUTH_TOKEN` (set automatically by the app) or `ANTHROPIC_API_KEY`.
- Enable branch protection on `main` requiring at least one human reviewer.
- Create the `agent-ready` label.

## Running locally

```bash
uv sync

# Run a task directly via lm-eval
uv run lm_eval \
  --tasks starter_mcq \
  --include_path tasks/lm_eval/starter_mcq \
  --model dummy \
  --output_path out/

# Or use the dispatcher (works across all installed harnesses)
uv run python scripts/smoke_run.py \
  --task tasks/lm_eval/starter_mcq \
  --model dummy \
  --limit 5 \
  --out out/reports/starter_mcq.md
```

See `SPEC.md` for the full design rationale and `harnesses/<name>/HARNESS.md` for per-harness conventions.

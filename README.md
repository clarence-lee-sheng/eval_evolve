# eval_evolve

LLM evals built and improved by an agent, driven entirely by human-filed GitHub issues. **Humans never touch code.**

Built on [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) as the eval runtime.

## The loop

1. A human files a GitHub issue describing an eval change (use the *Eval change* template).
2. Apply the `agent-ready` label.
3. A GitHub Action invokes the agent (Claude Agent SDK).
4. The agent posts a **plan** as a comment on the issue.
5. The agent implements the change in `tasks/`, smoke-runs it via `scripts/smoke_run.py`, and opens a PR with the verification report attached.
6. A human reviews the PR.
   - Approve → merge. (Only path to permanent change.)
   - Comment → agent picks up the comment, pushes a new commit.
   - Close → discarded.

Humans only ever express intent. The agent does all the typing.

## Key features

- **lm-eval substrate** — pinned via `pyproject.toml`; tasks in `tasks/<name>/` follow the standard YAML schema.
- **Issue-triggered agent** — `.github/workflows/agent.yml` fires on label `agent-ready` and runs [`anthropics/claude-code-action@v1`](https://github.com/anthropics/claude-code-action) with the standing rules from `agent/prompts/system.md`.
- **Plan-first authoring** — agent posts a plan comment on the issue before any code is written (`agent/prompts/plan_template.md`).
- **PR-review iteration** — `.github/workflows/agent-followup.yml` fires on review comments on `agent/*` branches; the action re-runs with the comments as context.
- **Cheap verification helper** — `scripts/smoke_run.py` runs `lm_eval` on a small sample and emits a markdown report for the PR description.
- **Scoped editing** — agent's standing instructions (`agent/prompts/system.md`) restrict edits to `tasks/`; tool surface restricted via `--allowedTools Read,Edit,Write,Glob,Grep,Bash`.
- **Human-only merge gate** — agent never merges; enforce with branch protection on `main`.

## Repo layout

```
eval_evolve/
  README.md                        # this file
  CLAUDE.md                        # standing context for Claude Code sessions
  SPEC.md                          # design principle + architecture decisions
  pyproject.toml                   # uv project, pins lm-eval
  tasks/                           # AGENT'S PLAYGROUND — only edits here
    starter_mcq/                   # 10-question MCQ seed eval
      task.yaml
      data.jsonl
      README.md
  agent/
    prompts/                       # loaded by the action's `prompt` input
      system.md                    # operational rules for the agent
      plan_template.md
      pr_template.md
  scripts/
    smoke_run.py                   # cheap verification helper
  .github/
    workflows/
      agent.yml                    # on issue labeled `agent-ready`
      agent-followup.yml           # on PR review comments
    ISSUE_TEMPLATE/
      eval-change.md
```

## Filing your first issue

1. Open a new issue, pick the *Eval change* template.
2. Fill in: which eval, what change you want, optionally why.
3. Add the `agent-ready` label.
4. Wait. The agent will:
   - post a plan as a comment within a couple of minutes,
   - open a PR,
   - leave the PR open for you to review.
5. Comment on the PR if it needs adjustment, or merge.

## Setup (one-time)

- Install the Claude GitHub App on this repo (run `/install-github-app` from Claude Code locally, or follow [the action's setup guide](https://github.com/anthropics/claude-code-action#quick-start)).
- Add `ANTHROPIC_API_KEY` to repo secrets (or `CLAUDE_CODE_OAUTH_TOKEN` if using OAuth).
- Enable branch protection on `main` requiring at least one human reviewer.
- Create the `agent-ready` label.

## Running locally

```bash
uv sync
uv run lm_eval --tasks starter_mcq --include_path tasks/starter_mcq --model dummy --output_path out/
uv run python scripts/smoke_run.py --task starter_mcq --include-path tasks/starter_mcq --model dummy --limit 5 --out out/reports/starter_mcq.md
```

See `SPEC.md` for the full design rationale.

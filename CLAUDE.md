# CLAUDE.md

This repo is `eval_evolve`. The invariant: **humans never touch code**. All code changes come from an agent driven by GitHub issues.

## Repo layout

- `tasks/` — the agent's playground. Every eval lives here. **Edit only here.**
- `agent/prompts/` — system prompt + plan/PR templates. Loaded by the action's `prompt` input.
- `scripts/smoke_run.py` — cheap verification helper. Runs an lm-eval task on a small sample, emits a markdown report.
- `.github/workflows/agent.yml` — fires on issue labeled `agent-ready`, invokes `anthropics/claude-code-action@v1`.
- `.github/workflows/agent-followup.yml` — fires on PR review comments on `agent/*` branches.
- `pyproject.toml` — uv project. lm-eval is a pinned dependency.

## How to run things

- Install deps: `uv sync`
- Run an eval: `uv run lm_eval --tasks <task> --include_path tasks/<task> --model dummy --output_path out/`
- Smoke run an eval into a markdown report: `uv run python scripts/smoke_run.py --task <task> --include-path tasks/<task> --model dummy --limit 5 --out out/reports/<task>.md`
- Trigger the agent: label any issue `agent-ready`. The action does the rest.

## Conventions

- Python 3.10+ (CI uses 3.12).
- Use `uv` for everything, never bare `pip`. Always update `pyproject.toml` when adding deps.
- Tasks follow the lm-evaluation-harness YAML schema.
- Task directories are snake_case under `tasks/`.
- Each `tasks/<name>/` should have at minimum: `task.yaml`, `data.jsonl` (or a clear pointer to a dataset), `README.md`.

## Agent rules (loaded by the action's `prompt` input)

These are the operational rules the in-CI agent follows. They live in `agent/prompts/system.md`. Don't change them lightly — they encode the project's invariants.

- The agent edits only `tasks/`.
- The agent does not merge PRs. Humans are the merge gate.
- The agent posts a plan to the issue *before* implementing.
- The agent picks verification depth based on change size.
- The agent treats PR review comments as direct intent.

## Gotchas

- `lm_eval` writes results to a model-specific subdir under `--output_path`; `scripts/smoke_run.py` globs for the latest `results_*.json`.
- The dummy model returns deterministic random answers — useful for plumbing, not for quality signal.
- `git: not a git repository` warnings from lm-eval are harmless (it tries to log the repo SHA).
- Branch names follow `agent/issue-<n>`; the followup workflow relies on this prefix.

# CLAUDE.md

This repo is `eval_evolve`. The invariant: **humans never touch code**. All code changes come from an agent driven by GitHub issues. The agent works across multiple eval harnesses (lm-evaluation-harness today; more as added).

## Repo layout

- `harnesses/<name>/HARNESS.md` — per-harness reference docs. Read-only. Ships with the repo.
- `harnesses/<name>/smoke.sh` — per-harness runner; invoked by the dispatcher.
- `tasks/<harness>/<task>/` — the agent's playground. **Edits live here.**
- `scripts/smoke_run.py` — harness-agnostic dispatcher. Reads the task path, delegates to the right `smoke.sh`, renders a markdown report.
- `agent/prompts/` — system prompt + plan/PR templates. Loaded by the action's `prompt` input.
- `.github/workflows/agent.yml` — fires on issue labeled `agent-ready`, invokes `anthropics/claude-code-action@v1`.
- `.github/workflows/agent-followup.yml` — fires on PR review comments on `agent/*` branches.
- `pyproject.toml` — uv project. lm-eval is a pinned dependency; more harnesses get added here when bootstrapped.

## How to run things

- Install deps: `uv sync`
- Run an eval directly: `uv run lm_eval --tasks <task> --include_path tasks/lm_eval/<task> --model dummy --output_path out/`
- Smoke run with markdown report (harness-agnostic): `uv run python scripts/smoke_run.py --task tasks/<harness>/<task> --model dummy --limit 5 --out out/reports/<task>.md`
- Trigger the agent: label any issue `agent-ready`. The action does the rest.

## Conventions

- Python 3.10+ (CI uses 3.12).
- Use `uv` for everything, never bare `pip`. Always update `pyproject.toml` when adding deps.
- Tasks live under `tasks/<harness>/<task>/` and follow that harness's conventions (see `harnesses/<harness>/HARNESS.md`).
- Task directories are snake_case.

## Agent rules (loaded by the action's `prompt` input)

These are the operational rules the in-CI agent follows. They live in `agent/prompts/system.md`. Don't change them lightly — they encode the project's invariants.

- The agent reads `harnesses/<harness>/HARNESS.md` before touching tasks of that harness.
- The agent may edit anywhere in the repo, but flags changes to its own rules / CI / SPEC prominently in PRs.
- The agent does not merge PRs. Humans are the merge gate.
- The agent posts a plan to the issue *before* implementing.
- The agent picks verification depth based on change size.
- The agent treats PR review comments as direct intent.
- The agent may bootstrap a new harness if an issue requires one (adds dep, writes HARNESS.md + smoke.sh, optionally a report renderer).

## Gotchas

- `lm_eval` writes results to a model-specific subdir under `--output_path`; `scripts/smoke_run.py` globs for the latest `results_*.json`.
- The dummy model returns deterministic random answers — useful for plumbing, not for quality signal.
- `git: not a git repository` warnings from lm-eval are harmless (it tries to log the repo SHA).
- Branch names follow `agent/issue-<n>`; the followup workflow relies on this prefix.
- `data_files` paths in lm-eval task YAMLs are resolved relative to the CWD, not the task dir — always write repo-relative paths.

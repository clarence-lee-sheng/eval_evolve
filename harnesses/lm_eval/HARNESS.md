# lm-evaluation-harness

Reference for the agent. Read this before creating or editing anything under `tasks/lm_eval/`.

## What this harness is

[EleutherAI/lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) — a YAML-driven framework for evaluating language models on standardized benchmarks. Pinned as a dependency in `pyproject.toml`.

Upstream task definitions live in the installed package at:

```
.venv/lib/python3.12/site-packages/lm_eval/tasks/
```

When porting an upstream eval (BBH, MMLU, ARC, etc.), read from there — not from GitHub.

## Task directory layout

Each task is a directory under `tasks/lm_eval/<task_name>/`:

```
tasks/lm_eval/<task_name>/
  task.yaml          # required — lm-eval task config
  data.jsonl         # optional — local dataset (if not pulling from HF)
  README.md          # required — what this eval measures, schema, run command
```

`<task_name>` is snake_case. The `task:` field in `task.yaml` must match the directory name.

## Required `task.yaml` fields

For a multiple-choice task with a local JSONL dataset:

```yaml
task: <task_name>
dataset_path: json
dataset_kwargs:
  data_files:
    test: tasks/lm_eval/<task_name>/data.jsonl   # must be repo-relative
test_split: test
output_type: multiple_choice
doc_to_text: "Question: {{question}}\nAnswer:"
doc_to_target: "{{answer}}"          # 0-indexed integer into choices
doc_to_choice: "{{choices}}"
metric_list:
  - metric: acc
    aggregation: mean
    higher_is_better: true
metadata:
  version: 1.0
```

For tasks pulling from HuggingFace datasets (e.g. ports of ARC, MMLU), set `dataset_path: <hf_dataset_id>` and `dataset_name: <config>` instead of `dataset_path: json` + `dataset_kwargs`. See `.venv/lib/.../lm_eval/tasks/arc/arc_easy.yaml` for a canonical example.

## `data.jsonl` schema (when using local data)

One JSON object per line. The exact keys depend on what your `task.yaml` references via `doc_to_*` Jinja templates. For the standard MCQ shape:

```json
{"id": "q1", "question": "...", "choices": ["a", "b", "c", "d"], "answer": 0}
```

`answer` is a 0-indexed integer into `choices`.

## Run command

To verify a task locally:

```bash
uv run lm_eval \
  --tasks <task_name> \
  --include_path tasks/lm_eval/<task_name> \
  --model dummy \
  --output_path out/
```

The dispatcher (`scripts/smoke_run.py`) handles this for you — prefer it for smoke runs in PRs.

## Common gotchas

- **`data_files` paths are resolved relative to the current working directory**, not the task directory. Always write repo-relative paths (`tasks/lm_eval/<name>/data.jsonl`).
- **`doc_to_target` returns a string by default**; for multiple-choice tasks it must evaluate to a 0-indexed integer (or a Jinja expression that produces one).
- **`metadata.version`** should bump only on breaking changes to the task's scoring or schema, not on content additions.
- **lm-eval prints a `fatal: not a git repository` warning** when run from outside a git checkout — harmless, ignore it.
- **The `dummy` model** returns deterministic random answers. Useful for plumbing checks, useless for quality signal. Around `1/n_choices` accuracy is expected.
- **HuggingFace dataset downloads cache in `~/.cache/huggingface/`.** First run for a new HF-backed task may be slow.

## Worked example

`tasks/lm_eval/starter_mcq/` is the canonical small task. Imitate its structure when creating new local-JSONL tasks. For HF-backed tasks, copy the relevant `task.yaml` from `.venv/lib/.../lm_eval/tasks/<x>/` into `tasks/lm_eval/<x>/` and adjust as needed.

## When upstream conflicts with this doc

Upstream is authoritative. If you find this HARNESS.md is out of date, fix it as part of the same PR — don't work around it silently.

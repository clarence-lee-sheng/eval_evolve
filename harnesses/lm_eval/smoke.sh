#!/usr/bin/env bash
# Smoke-run an lm-eval task. Invoked by scripts/smoke_run.py.
#
# Usage: smoke.sh <task_dir> <model> <limit> <output_dir>
#   task_dir    e.g. tasks/lm_eval/starter_mcq
#   model       lm-eval model name (e.g. dummy, hf, anthropic)
#   limit       integer; how many examples to score
#   output_dir  where lm-eval writes results
#
# On success, lm-eval writes results_*.json under output_dir/<model>/.
# The dispatcher globs for the latest one and renders the report.

set -euo pipefail

task_dir="${1:?task_dir required}"
model="${2:-dummy}"
limit="${3:-5}"
output_dir="${4:-out/smoke}"

task_name="$(basename "$task_dir")"

mkdir -p "$output_dir"

uv run lm_eval \
  --tasks "$task_name" \
  --include_path "$task_dir" \
  --model "$model" \
  --limit "$limit" \
  --output_path "$output_dir" \
  --log_samples

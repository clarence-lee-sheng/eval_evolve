# starter_mcq

A 10-question multiple-choice eval used as the seed for the project's first
vertical slice. The agent operates on this directory.

## What it measures

Basic factual recall across mixed domains (geography, science, math, literature, history). Each item has 4 choices, one correct answer.

## Schema

`data.jsonl` — one JSON object per line:

```json
{"id": "q1", "question": "...", "choices": ["a", "b", "c", "d"], "answer": 2}
```

- `answer` is a 0-indexed integer into `choices`.

## Run it

```bash
uv run lm_eval \
  --tasks starter_mcq \
  --include_path tasks/lm_eval/starter_mcq \
  --model dummy \
  --output_path out/
```

## How to evolve it

File a GitHub issue. Examples:
- "Add 5 more questions on chemistry."
- "Make question 3 harder by replacing the distractors."
- "Switch to a log-likelihood normalized accuracy metric."

"""
Step 3 — Baseline evaluation for wine variety classification

TODO: Compare accuracy between the mainline models and your fine tuned model.
Make sure you paste the name of your fine tuned model in the FINE_TUNED_MODEL variable below.

Usage:
    python -m labs.lab04_finetuning_guided.step_03_eval_distilled

Environment overrides (optional):
- DATA_CSV: path to the processed CSV (default: labs/lab04_finetuning_guided/data/wine_france_subset.csv)
- VARIETIES_JSON: path to the varieties JSON (default: labs/lab04_finetuning_guided/data/varieties.json)
- FINE_TUNED_MODEL: e.g., "ft:gpt-4.1-nano-2025-04-14:customer-education::CLVl7cQD"
- NUM_ROWS: integer cap on number of rows to evaluate (default: 100)
"""

from __future__ import annotations

import json
import os
import time
import uuid
from typing import Dict, List, Optional
import re

from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv(), override=True)

from concurrent.futures import ThreadPoolExecutor, as_completed
import pandas as pd
from openai import OpenAI
from pydantic import BaseModel, Field
# Centralized testing criteria for reuse across lab steps
from labs.lab04_finetuning_guided.testing_criteria import testing_criteria


DEFAULT_DATA_CSV = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "data", "wine_france_subset.csv")
)
DEFAULT_VARIETIES_JSON = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "data", "varieties.json")
)

DATA_CSV = os.getenv("DATA_CSV", DEFAULT_DATA_CSV)
VARIETIES_JSON = os.getenv("VARIETIES_JSON", DEFAULT_VARIETIES_JSON)
DEFAULT_OUTPUT_DIR = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "data")
)
COMPLETIONS_OUTPUT_DIR = os.getenv("COMPLETIONS_OUTPUT_DIR", DEFAULT_OUTPUT_DIR)

# TODO: Add the distilled model name; prefer env var exported in Step 2
FINE_TUNED_MODEL = os.getenv("DISTILLED_MODEL", "ft:gpt-4.1-nano-2025-04-14:customer-education::CLVl7cQD")
NUM_ROWS = int(os.getenv("NUM_ROWS", "100"))


def load_varieties(path: str) -> List[str]:
    with open(path, "r", encoding="utf-8") as handle:
        payload = json.load(handle)
    values = payload.get("varieties")
    if not isinstance(values, list):
        raise ValueError("Invalid varieties.json shape")
    return [str(v) for v in values]


def load_dataset(csv_path: str, num_rows: int) -> object:
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"Missing dataset CSV: {csv_path}")
    df = pd.read_csv(csv_path)
    if num_rows > 0 and num_rows < len(df):
        return df.sample(n=num_rows, random_state=123).copy()
    return df


def build_prompt(row: object) -> str:
    parts: List[str] = []
    for field in [
        "title",
        "province",
        "region_1",
        "region_2",
        "designation",
        "description",
        "taster_name",
    ]:
        value = row.get(field)
        if isinstance(value, float):
            value = None
        if value is not None and str(value).strip():
            parts.append(f"{field}: {value}")
    return "\n".join(parts)

class EvalItem(BaseModel):  # type: ignore[misc,valid-type]
    """Schema for a single eval item used by the Evals API."""
    input: str = Field(..., description="User-visible prompt built from row fields")  # type: ignore[assignment]
    variety: str = Field(..., description="Gold label (expected wine variety)")  # type: ignore[assignment]
    model_answer: str = Field(..., description="Predicted variety from the model under test")  # type: ignore[assignment]


def _wait_for_run_completion(client: object, eval_id: str, run_id: str) -> object:
    """Poll an eval run until it reaches a terminal state and return it."""
    terminal_statuses = {"completed", "failed", "canceled"}
    while True:
        eval_run = client.evals.runs.retrieve(run_id, eval_id=eval_id)  # type: ignore[attr-defined]
        status = getattr(eval_run, "status", None)
        if status in terminal_statuses:
            return eval_run
        time.sleep(2)


def classify_variety(
    client: object,
    model: str,
    varieties: List[str],
    prompt: str,
) -> Optional[str]:
    """Return the predicted variety using the Responses API (JSON string)."""

    response = client.responses.create(
        model=model,
        input=[
            {
                "role": "system",
                "content": (
                    "Classify the wine variety from the provided fields. "
                    "Return ONLY a JSON object like {\"variety\": \"...\"} where the value "
                    "is one of the allowed enum values."
                ),
            },
            {"role": "user", "content": prompt},
        ],
        temperature=0,
    )
    text = getattr(response, "output_text", None)
    return _safe_parse_variety(text, varieties)


def _safe_parse_variety(text: Optional[str], varieties: List[str]) -> Optional[str]:
    """Parse variety robustly from model text.

    Attempts strict JSON first; if that fails, extracts the first JSON object
    substring; finally, falls back to matching known varieties present in text.
    """
    if not text or not isinstance(text, str):
        return None

    # 1) Try strict JSON
    try:
        data = json.loads(text)
        candidate = data.get("variety") if isinstance(data, dict) else None
        if isinstance(candidate, str) and candidate in varieties:
            return candidate
    except Exception:
        pass

    # 2) Try to extract JSON object substring and parse
    try:
        # Find the first {...} block (non-greedy across lines)
        match = re.search(r"\{[\s\S]*?\}", text)
        if match:
            obj_text = match.group(0)
            data = json.loads(obj_text)
            candidate = data.get("variety") if isinstance(data, dict) else None
            if isinstance(candidate, str) and candidate in varieties:
                return candidate
    except Exception:
        pass

    # 3) Heuristic: if exactly one allowed variety is mentioned, return it
    mentions: List[str] = []
    lowered = text.lower()
    for v in varieties:
        # word boundary match to avoid partial hits; case-insensitive
        if re.search(rf"\b{re.escape(v.lower())}\b", lowered):
            mentions.append(v)
    if len(mentions) == 1:
        return mentions[0]

    return None


def eval_model(
    client: object,
    model: str,
    df: object,
    varieties: List[str],
) -> List[dict]:
    """Generate eval items for a single model (no API eval here)."""

    items: List[dict] = []
    for _idx, row in df.iterrows():
        gold = str(row.get("variety"))
        user_prompt = build_prompt(row)
        pred = classify_variety(client, model, varieties, user_prompt)
        items.append({"input": user_prompt, "variety": gold, "model_answer": pred or ""})
    return items


def run() -> None:
    if OpenAI is None:  # pragma: no cover
        raise ImportError("Please install the OpenAI Python SDK: pip install -U openai")

    client = OpenAI()

    varieties = load_varieties(VARIETIES_JSON)
    df = load_dataset(DATA_CSV, NUM_ROWS)

    print(f"Rows to evaluate: {len(df)} | #Varieties: {len(varieties)}\n")

    # Generate model answers in parallel
    models = [
        ("FINE-TUNE", FINE_TUNED_MODEL)
    ]
    
    print("Generating model answers...\n\n")

    results: Dict[str, List[dict]] = {}
    with ThreadPoolExecutor(max_workers=3) as executor:
        future_map = {
            executor.submit(eval_model, client, model_name, df, varieties): label
            for label, model_name in models
        }
        for future in as_completed(future_map):
            label = future_map[future]
            results[label] = future.result()
            
    print("Evaluating the model answers...\n\n")

    # Write per-model JSONL files for reuse in Step 2
    os.makedirs(COMPLETIONS_OUTPUT_DIR, exist_ok=True)
    timestamp = str(uuid.uuid4())

    def write_jsonl(path: str, rows: List[dict]) -> int:
        count = 0
        with open(path, "w", encoding="utf-8") as handle:
            for obj in rows:
                handle.write(json.dumps({"item": obj}, ensure_ascii=False) + "\n")
                count += 1
        return count

    output_paths: Dict[str, str] = {}
    for label in ["FINE-TUNE"]:
        items = results.get(label, [])
        filename = f"completions_{label.lower()}_{timestamp}.jsonl"
        out_path = os.path.join(COMPLETIONS_OUTPUT_DIR, filename)
        written = write_jsonl(out_path, items)
        output_paths[label] = out_path
        print(f"Wrote {written} item(s) to {out_path}")

    # Create a single eval definition
    run_uuid = str(uuid.uuid4())
    eval_obj = client.evals.create(  # type: ignore[attr-defined]
        name=f"Finetuning-Eval-{run_uuid}",
        data_source_config={
            "type": "custom",
            "item_schema": EvalItem.model_json_schema(),  # type: ignore[attr-defined]
        },
        testing_criteria=testing_criteria,
    )
    eval_id = getattr(eval_obj, "id", "")
    print("Created eval definition.")

    # Create run for distilled model
    def start_run(run_name: str, items: List[dict]) -> object:
        file_content = [{"item": entry} for entry in items]
        return client.evals.runs.create(  # type: ignore[attr-defined]
            eval_id=eval_obj.id,
            name=run_name,
            data_source={
                "type": "jsonl",
                "source": {"type": "file_content", "content": file_content},
            },
        )

    runs = {
        "FINE-TUNE": start_run(f"Distilled-{FINE_TUNED_MODEL}-{run_uuid}", results.get("FINE-TUNE", [])),
    }

    # Poll each run and print results
    for label in ["FINE-TUNE"]:
        eval_run = _wait_for_run_completion(client, eval_obj.id, runs[label].id)
        counts = getattr(eval_run, "result_counts", None)
        passed = getattr(counts, "passed", 0) if counts else 0
        total = getattr(counts, "total", 0) if counts else len(results.get(label, []))
        acc = (passed / total) if total else 0.0
        name = {
            "FINE-TUNE": f"Evaluating FINE TUNED model: {FINE_TUNED_MODEL}",
        }[label]
        print(name)
        print(f"{label.title()}: {passed}/{total} = {acc:.3f}\n\n")

    if eval_id:
        print(f"Navigate to https://platform.openai.com/evaluation/evals/{eval_id} to see the evaluation run")
    else:
        print("View details in the Evaluations dashboard: https://platform.openai.com/evaluations")


if __name__ == "__main__":
    run()



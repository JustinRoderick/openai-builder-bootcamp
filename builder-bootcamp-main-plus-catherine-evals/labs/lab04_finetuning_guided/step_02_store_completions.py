"""
Step 2 — Start a distillation fine‑tune from saved completions

TODO: Read the JSONL completions produced in Step 1 (ideally the TEACHER file),
upload it, and start a fine‑tune targeting gpt-4.1-nano.

Usage:
    python -m labs.lab04_finetuning_guided.step_02_store_completions

Environment:
- COMPLETIONS_JSONL: path to the JSONL created in Step 1 (required)
- NANO_MODEL: distilled target base model (default: gpt-4.1-nano)
- JOB_SUFFIX: optional model suffix for easier identification
"""

from __future__ import annotations

import os
from typing import Optional

from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv(), override=True)

from openai import OpenAI
import glob
from pathlib import Path
import json
from datetime import datetime

COMPLETIONS_JSONL = os.getenv("COMPLETIONS_JSONL")
NANO_MODEL = os.getenv("NANO_MODEL", "gpt-4.1-nano-2025-04-14")
JOB_SUFFIX = os.getenv("JOB_SUFFIX")
FT_JOB_ID = os.getenv("FT_JOB_ID")
POLL_INTERVAL_SECONDS = int(os.getenv("POLL_INTERVAL_SECONDS", "10"))

DEFAULT_COMPLETIONS_DIR = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "data")
)


def _find_latest_teacher_jsonl(directory_path: str) -> Optional[str]:
    pattern = os.path.join(directory_path, "completions_teacher_*.jsonl")
    candidates = glob.glob(pattern)
    if not candidates:
        return None
    # Pick the most recently modified file
    candidates.sort(key=lambda p: os.path.getmtime(p), reverse=True)
    return candidates[0]


def _format_teacher_jsonl_for_finetune(src_path: str, dst_path: str) -> int:
    """Convert Step 1 JSONL to chat fine‑tune JSONL: {"messages": [...]} per line.

    Expects each source line like: {"item": {"input": str, "variety": str, "model_answer"?: str, "teacher_label"?: str}}
    Writes each dest line like: {"messages": [{"role":"user","content": input}, {"role":"assistant","content": label}]}
    """
    count = 0
    with open(src_path, "r", encoding="utf-8") as fin, open(dst_path, "w", encoding="utf-8") as fout:
        for line in fin:
            if not line.strip():
                continue
            obj = json.loads(line)
            item = obj.get("item", {}) if isinstance(obj, dict) else {}
            input_text = item.get("input", "")
            # Prefer explicit teacher label, then model_answer, then variety
            label = item.get("teacher_label") or item.get("model_answer") or item.get("variety") or ""
            if not input_text or not label:
                continue
            out = {
                "messages": [
                    {"role": "user", "content": str(input_text)},
                    {"role": "assistant", "content": str(label)},
                ]
            }
            fout.write(json.dumps(out, ensure_ascii=False) + "\n")
            count += 1
    return count


def _poll_job(client: OpenAI, job_id: str) -> None:
    print(f"Polling fine‑tune job: {job_id}")
    while True:
        try:
            job = client.fine_tuning.jobs.retrieve(job_id)  # type: ignore[attr-defined]
        except Exception as error:  # pragma: no cover
            print(f"Error retrieving job: {error}")
            continue

        status = getattr(job, "status", None)
        model_name = getattr(job, "fine_tuned_model", None)
        print(f"Status: {status} | Model: {model_name}")

        if status in {"succeeded", "failed", "cancelled"}:
            if model_name:
                print(f"\nDistilled model name: {model_name}")
                print("export DISTILLED_MODEL=\"{0}\"".format(model_name))
            break

        try:
            import time
            time.sleep(POLL_INTERVAL_SECONDS)
        except Exception:
            pass


def run() -> None:
    client = OpenAI()

    # Auto-discover the latest teacher completions file if not provided
    effective_path = COMPLETIONS_JSONL
    if not effective_path:
        latest = _find_latest_teacher_jsonl(DEFAULT_COMPLETIONS_DIR)
        if not latest:
            print(
                "ERROR: Could not find any teacher completions file. "
                f"Looked for 'completions_teacher_*.jsonl' in {DEFAULT_COMPLETIONS_DIR}"
            )
            return
        effective_path = latest
        print(f"Using latest teacher completions: {effective_path}")

    if not os.path.exists(effective_path):
        print(f"ERROR: File not found: {effective_path}")
        return

    # Reformat to chat fine‑tune JSONL
    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    finetune_jsonl = os.path.join(DEFAULT_COMPLETIONS_DIR, f"finetune_dataset_{ts}.jsonl")
    written = _format_teacher_jsonl_for_finetune(effective_path, finetune_jsonl)
    print(f"Prepared fine‑tune file with {written} item(s): {finetune_jsonl}")

    with open(finetune_jsonl, "rb") as fh:
        uploaded = client.files.create(file=fh, purpose="fine-tune")

    file_id = getattr(uploaded, "id", None)
    print(f"Uploaded training file id: {file_id}")

    # Start the fine‑tune job and automatically poll its status
    job = client.fine_tuning.jobs.create(
        ## TODO: write up the fine tuning job creation parameters to trigger the fine tuning process.
    )
    print(f"Started job: {job.id}")
    _poll_job(client, job.id)


if __name__ == "__main__":
    run()



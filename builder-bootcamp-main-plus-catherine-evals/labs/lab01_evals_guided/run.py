"""
Minimal Evals grader to test sample_01.jsonl data using the Evals API.

Requirements:
- Set OPENAI_API_KEY in your environment
- Non-ZDR workspace

Usage:
  python labs/lab01_evals_guided/run.py
"""

import os
import sys
import json
import time
import uuid
from typing import Any, Dict, List

# Load environment variables from a local `.env` (if present) so labs can run
# without manually exporting keys in every shell.
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv(), override=True)

from openai import OpenAI
from pydantic import BaseModel, Field

import labs.lab01_evals_guided.evaluation_results_helper as evaluation_run_results
from labs.lab01_evals_guided.testing_criteria import testing_criteria

class EvalItem(BaseModel):
    """
    Schema for a single custom eval item.

    Fields:
        input (str): The input question or prompt for the item.
        expected_answer (str): The expected/ground-truth answer text for the item.
        expected_tool (str): The expected/ground-truth tool for the item.
        expected_category (str): The expected/ground-truth category for the item.
    """
    input: str = Field(..., description="The input question or prompt for the item.")
    expected_answer: str = Field(..., description="The expected/ground-truth answer text for the item.")
    expected_tool: str = Field(..., description="The expected/ground-truth tool for the item.")
    expected_category: str = Field(..., description="The expected/ground-truth category for the item.")

def load_sample_data(filepath: str) -> List[Dict[str, Any]]:
    """
    Loads question/expected_answer pairs from a JSONL file.

    Supports two shapes per line:
    - {"input": "...", "expected_answer": "...", "expected_tool": "...", "expected_category": "...", ...}
    - {"item": {"input": "...", "expected_answer": "...", "expected_tool": "...", "expected_category": "...", ...}}

    Args:
        filepath (str): Path to the JSONL file.

    Returns:
        list: List of dicts with question, expected_answer, etc.
    """
    data = []
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    obj = json.loads(line)
                    # Directly use the inner dict under "item" (assume always wrapped)
                    data.append(obj["item"])
    except Exception as e:
        print(f"Error loading sample data: {e}")
    return data

def _wait_for_run_completion(
    client: OpenAI,
    eval_id: str,
    run_id: str,
    poll_interval_seconds: int = 2,
    timeout_seconds: int = 600,
):
    """
    Poll an eval run until it reaches a terminal state or times out.

    Terminal states include: completed, failed, canceled.
    Returns the final eval run object.
    """
    start_time = time.time()
    terminal_statuses = {"completed", "failed", "canceled"}
    while True:
        try:
            eval_run = client.evals.runs.retrieve(run_id, eval_id=eval_id)
        except Exception as e:
            print(f"Error retrieving eval run status: {e}")
            raise
        status = getattr(eval_run, "status", None)
        print(f"Eval run status: {status}")
        if status in terminal_statuses:
            return eval_run
        if time.time() - start_time > timeout_seconds:
            raise TimeoutError(f"Timed out after {timeout_seconds}s waiting for eval run {run_id}")
        time.sleep(poll_interval_seconds)

def run_eval_on_samples(samples: List[Dict[str, Any]], testing_criteria: List[Dict[str, Any]]) -> None:
    """
    Runs Evals API on the provided samples using a model grader.

    Args:
        samples (list): List of dicts with 'input', 'expected_answer', 'expected_tool', and 'expected_category'.
        testing_criteria (list): List of eval criteria.

    Returns:
        None
    """
    client = OpenAI()
    run_uuid = str(uuid.uuid4())
    print(f"Run UUID: {run_uuid}")

    # Print loaded samples for debugging
    print(f"Loaded {len(samples)} samples from file.")
    for i, item in enumerate(samples, 1):
        q = item.get("input")
        print(f"Sample {i}: Q: {q} | Expected A: {item.get('expected_answer')}")

    # Prepare items for eval (format: {"input": ..., "expected_answer": ..., "expected_tool": ..., "expected_category": ...})
    eval_items = []
    for item in samples:
        eval_items.append({
            "input": item.get("input", ""),
            "expected_answer": item.get("expected_answer", ""),
            "expected_tool": item.get("expected_tool", ""),
            "expected_category": item.get("expected_category", ""),
        })

    try:
        # Create the eval definition for a custom data source
        eval_obj = client.evals.create(
            name="Evals-Lab-01-" + run_uuid,
            data_source_config={
                "type": "custom",
                "item_schema": EvalItem.model_json_schema(),
            },
            testing_criteria=testing_criteria, # type: ignore
        )
        eval_id = getattr(eval_obj, "id", "")
        print("\nCreated eval definition:")

        # Build in-memory file content for inline use
        file_content = [{"item": entry} for entry in eval_items]

        # Create an eval run using file_content to provide items inline
        eval_run = client.evals.runs.create(
            eval_id=eval_obj.id,
            name=f"Evals-Lab-01-eval run ({run_uuid})",
            data_source={
                "type": "jsonl",
                "source": {"type": "file_content", "content": file_content},
            }, # type: ignore
        )
        print(f"Started eval run: {getattr(eval_run, 'id', 'unknown')} (status={getattr(eval_run, 'status', 'unknown')})")

        # Poll until terminal state (completed/failed/canceled) with timeout
        eval_run = _wait_for_run_completion(client, eval_obj.id, eval_run.id)

        print("Eval run finished with status:", eval_run.status)
        if getattr(eval_run, "status", None) == "completed":
            passed, total = evaluation_run_results.get_eval_run_score(eval_run.id, eval_obj.id)
            print(f"Eval run score: {passed} / {total} passed")
            if eval_id:
                print(f"Navigate to https://platform.openai.com/evaluation/evals/{eval_id} to see the evaluation run")
            else:
                print("View details in the Evaluations dashboard: https://platform.openai.com/evaluations")
        else:
            error_detail = getattr(eval_run, "error", None)
            if error_detail:
                print(f"Eval run error detail: {error_detail}")

    except Exception as eval_error:
        print(f"Error running eval: {eval_error}")

if __name__ == "__main__":

    # TODO
    # Define your testing criteria in labs/lab01_evals_guided/testing_criteria.py.
    # That file contains:
    #   1) A fully built-out example inside a '#region Graders Full Example' block
    #   2) A smaller example further down the file
    # Both sections declare 'testing_criteria'. In Python, the last assignment wins.
    # To select which one to use, either:
    #   - Comment out the other 'testing_criteria' assignment; or
    #   - Rename them (e.g., testing_criteria_full/testing_criteria_minimal) and set at the bottom:
    #         testing_criteria = testing_criteria_full   # or testing_criteria_minimal
    # You can also create your own criteria file and import it here instead, for example:
    #   from labs.lab01_evals_guided.my_criteria import testing_criteria

    # Path to the sample data file
    sample_file = os.path.join(os.path.dirname(__file__), "../data/sample_01.jsonl")
    sample_file = os.path.abspath(sample_file)
    
    # Load the sample data
    samples = load_sample_data(sample_file)
    if not samples:
        print("No samples loaded. Exiting.")
        sys.exit(1)

    # Run the eval
    run_eval_on_samples(samples, testing_criteria)

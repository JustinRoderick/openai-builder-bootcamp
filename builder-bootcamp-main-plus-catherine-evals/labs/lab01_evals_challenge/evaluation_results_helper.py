from openai import OpenAI

def get_eval_run_score(run_id: str, eval_id: str):
    """
    Retrieve an eval run by run_id and eval_id, and return the number of passed and total items.

    Args:
        run_id (str): The ID of the eval run.
        eval_id (str): The ID of the eval.

    Returns:
        tuple: (passed, total) if available, else (None, None).
    Raises:
        Exception: If retrieval fails or result counts are missing.
    """
    client = OpenAI()
    try:
        run = client.evals.runs.retrieve(
            run_id,
            eval_id=eval_id  # must be keyword argument
        )
        result_counts = run.result_counts
        passed = getattr(result_counts, "passed", None)
        total = getattr(result_counts, "total", None)
        return passed, total
    except Exception as e:
        # Raise the exception to be handled by the caller
        raise RuntimeError(f"Failed to retrieve eval run score: {e}")

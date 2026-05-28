## Evals Lab

### Overview
Use the OpenAI Evals API to grade a small example dataset with a combination of model-based scoring and deterministic checks. You will:
- **Define testing criteria** ("graders") such as model scorers and string checks.
- **Run an eval** against a JSONL dataset.
- **Inspect results** locally (pass/total) and in the OpenAI Evaluations dashboard.

This lab is intentionally minimal so you can focus on how to structure criteria and data. A few dataset entries are designed to fail so you can see non-passing behavior.

### Prerequisites
- **Python**: 3.10+ recommended.
- **Dependencies**: `openai` and `pydantic`.
  - Create a virtual environment and install:
```bash
python -m venv .venv
source .venv/bin/activate
pip install -U openai pydantic
```
- **API key**: Set your OpenAI API key in the environment:
```bash
export OPENAI_API_KEY="sk-..."
```
- **Access**: Your org/account must have access to the Evals API (note: your org/account must not be a "non-zdr" org).

### Repository layout (lab files)
- `labs/lab01_evals_guided/run.py`: Runner that loads data, creates an eval, starts an eval run, polls for completion, and prints pass/total.
- `labs/lab01_evals_guided/testing_criteria.py`: Exercise scaffold you will complete during the lab.
- `labs/lab01_evals_guided/testing_criteria_solution.py`: Full reference example for comparison.
- `labs/lab01_evals_guided/evaluation_results_helper.py`: Helper to retrieve result counts (`passed`, `total`).
- `labs/data/sample_01.jsonl`: Sample dataset evaluated by default.

### The exercise
Build out a complete set of graders to evaluate the dataset. Specifically:
- **Model scorer(s)**: Use a model to assign a numeric score within a specified range, and declare a `pass_threshold`.
- **Label model(s)**: Use a model to assign a categorical label (e.g., "correct", "incorrect") to an answer or field.
- **String check(s)**: Deterministically verify that a field equals or contains a reference value.
- (Optional advanced) **Python grader**: Execute Python to compute a numeric score. You can add such a criterion if desired; see the Evals docs for the criterion shape.

You will implement these graders by editing the criteria list used by `run.py`.

### Where to make changes
- Start with `labs/lab01_evals_guided/testing_criteria.py`.
  - For a complete reference, open `labs/lab01_evals_guided/testing_criteria_solution.py`.
  - The runner imports from `testing_criteria.py` by default; to run the solution, change the import in `run.py` to:
    ```python
    from labs.lab01_evals_guided.testing_criteria_solution import testing_criteria
    ```
 - If you create your own module of criteria, import it in `labs/lab01_evals_guided/run.py` and replace the default import.

### Important: read the TODO in `labs/lab01_evals_guided/run.py`
Open `labs/lab01_evals_guided/run.py` and find the TODO comments in the `if __name__ == "__main__":` section. It explains how to import the exercise criteria (default) or swap to the solution import if desired.

### Dataset being evaluated
The runner loads items from `labs/data/sample_01.jsonl`. Each line is a JSON object with a single top-level key `item`, whose value contains the fields used by the graders:
```json
{"item": {
  "input": "Can I get a student discount?",
  "expected_answer": "Yes, verified students receive 15% off.",
  "expected_tool": "knowledge_assistant",
  "expected_category": "promotions_discounts"
}}
```
Fields available to graders (via `{{ item.<field> }}` templating):
- `input`: The question/prompt.
- `expected_answer`: The reference answer text to be graded against.
- `expected_tool`: The expected tool name.
- `expected_category`: The expected category.

Note: A few entries intentionally contain low-quality or incorrect `expected_answer` values so your model scorers can produce failing scores.

### Writing testing criteria (graders)
Your criteria must be a Python list of dictionaries named `testing_criteria`. The runner passes this list to the Evals API.

Two commonly used criterion types in this lab:
- **score_model**: Ask a model to grade an answer with a numeric score.
  - Required fields: `type`, `name`, `model`, `range`, `pass_threshold`, and `input` (a chat-style prompt array with templated fields).
  - Example (from the starter file):
```python
testing_criteria = [
    {
        "type": "score_model",
        "name": "Relevance and completeness of answer",
        "model": "gpt-5",
        "range": [1, 7],
        "pass_threshold": 5,
        "input": [
            {
                "role": "developer",
                "content": (
                    "You are grading whether the ANSWER fully and correctly addresses the CUSTOMER_QUESTION. "
                    "Return ONLY a numeric score in [1,7]. No text."
                ),
            },
            {
                "role": "user",
                "content": (
                    "CUSTOMER_QUESTION: {{ item.input }}\n"
                    "ANSWER: {{ item.expected_answer }}"
                ),
            },
        ],
    },
]
```
- **string_check**: Deterministically compare an input against a reference.
  - Required fields: `type`, `name`, `input`, `operation` (e.g., `eq`, `contains`), and `reference`.
  - Example:
```python
{
    "type": "string_check",
    "name": "Knowledge Assistant tool called",
    "input": "{{ item.expected_tool }}",
    "operation": "eq",
    "reference": "knowledge_assistant",
}
```

Tips:
- Keep `pass_threshold` within your declared `range`.
- Use the available item fields via templating: `{{ item.input }}`, `{{ item.expected_answer }}`, `{{ item.expected_tool }}`, `{{ item.expected_category }}`.
- You can include multiple criteria in the list; the Evals API will aggregate results across them.

For more shapes (e.g., Python or text-similarity graders), see the Evals documentation linked below.

### How it works (runner flow)
`labs/lab01_evals_guided/run.py` does the following:
1. Loads the dataset from `labs/data/sample_01.jsonl`.
2. Defines an item schema (`EvalItem`) and creates an eval with a custom data source configuration.
3. Starts an eval run with the items provided inline as JSONL content.
4. Polls until the run reaches a terminal state.
5. Retrieves `passed` and `total` from the run and prints a summary like `Eval run score: 7 / 11 passed`.

### Run the lab
From the repository root (or any location), run either:
```bash
python -m labs.lab01_evals_guided.run
# or
python labs/lab01_evals_guided/run.py
```
You should see:
- A generated `Run UUID`.
- The number of loaded samples and a preview of inputs/expected answers.
- Eval run status updates until it reaches `completed`.
- A final line with `Eval run score: <passed> / <total> passed`.

View the run and detailed rubric outcomes in the dashboard: [OpenAI Evaluations dashboard](https://platform.openai.com/evaluations).

### Customizing the dataset (optional)
If you want to evaluate your own data:
1. Create a new JSONL file where each line has a top-level `item` key containing the fields used by your criteria.
2. Keep the same field names (or update your criteria templating accordingly).
3. Update the `sample_file` path in `labs/lab01_evals_guided/run.py` or pass your data by editing the runner logic to point at your file.

Example line:
```json
{"item": {"input": "Question?", "expected_answer": "Answer.", "expected_tool": "knowledge_assistant", "expected_category": "category"}}
```

### Troubleshooting
- "No samples loaded. Exiting.": Verify the dataset path exists and contains valid JSONL lines with a top-level `item` key.
- Permission or 404 errors from the Evals API: Ensure your account has access and the `OPENAI_API_KEY` is set for the correct org/project.
- Timeouts while polling: Increase the timeout in `_wait_for_run_completion` in `labs/lab01_evals_guided/run.py`.
- Rate limits: Reduce dataset size or retry after a delay.

### References
- Guide: [Evals guide](https://platform.openai.com/docs/guides/evals)
- API Reference: [Evals API reference](https://platform.openai.com/docs/api-reference/evals)
- Dashboard: [OpenAI Evaluations](https://platform.openai.com/evaluations)

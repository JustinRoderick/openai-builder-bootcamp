# Builder Bootcamp: Evals Challenge Lab

#### Lab Metadata
- **Lab type**: Hands‑on challenge
- **Duration**: ~45 minutes
- **Level**: Advanced builders
- **Environment**: macOS/Linux/Windows terminal, Python 3.10+
- **Repo path**: `labs/lab01_evals_challenge`
**Last updated:** September 14, 2025

### Overview
This is the challenge version of the Evals lab. You will design and run an evaluation with minimal scaffolding:
* Author two rubric‑based model graders yourself:
    * Relevance and Completeness (score_model, 1–7 scale)
    * Directness of Answer (score_model, 1–3 scale)
* Optionally include a deterministic `string_check` (pre‑provided example) to validate routing/tool usage.
* Run the eval on a support‑use‑case dataset and review outcomes in the dashboard.

This lab is intentionally minimal so you can focus on structuring criteria and data, but it's also grounded in a real-world, production-style customer support use case—the kind you'd encounter in an actual helpdesk environment. 

The example dataset features realistic questions and expected answers, with a few entries designed to fail so you can see how your graders handle non-passing behavior in practice.

### Learning Objectives
1. Author two `score_model` graders from scratch (1–7 and 1–3 scales).
2. Export a valid `testing_criteria` list and wire it into the runner.
3. Run the eval and interpret pass/fail locally and in the dashboard.

### Prerequisites
- **Python**: 3.10+ recommended
- **Dependencies**: `openai` (modern SDK), `pydantic`
- **API key**: Environment variable `OPENAI_API_KEY`
- **Access**: Org/project must have access to the Evals API
- **ZDR note**: Evals require a non‑ZDR (non–zero data retention) workspace; ZDR orgs cannot create evals.

## Task 1. Set up your environment

> **Note:** If you've already set up your environment and installed the required dependencies as described in the main README or previous labs, you can skip these setup steps.

> **Tip:** For the easiest reading, open this README in **Markdown Preview** mode in your IDE (VSCode, Cursor, etc). It makes the instructions, tables, and code easier to read and scan. Some environments may need a markdown extension.

In this task, you'll get started by cloning the lab repository, setting up your Python virtual environment, and installing all the required libraries and dependencies needed to run the evals.

1. Run the following command to clone and enter the repository (repo root):
```bash
git clone https://openai-customer-education/builder-bootcamp.git
cd builder-bootcamp
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
git clone https://openai-customer-education/builder-bootcamp.git
Set-Location builder-bootcamp
```
</details>

2. Create and activate a virtual environment (Python 3.10+):
```bash
python3 --version
python3 -m venv .venv
source .venv/bin/activate
python -V
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
python --version
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -V
```
</details>

3. Now run the following commands to install dependencies:
```bash
python -m pip install --upgrade pip
pip install openai pydantic python-dotenv
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
python -m pip install --upgrade pip
pip install openai pydantic python-dotenv
```
</details>

**Checkpoint**: Run the following command to verify imports resolve

```bash
python - << 'PY'
import sys
print('Python OK:', sys.version)
import openai
print('OpenAI OK:', getattr(openai, '__version__', 'unknown'))
from openai import OpenAI
print('Client OK:', bool(OpenAI))
PY
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
@'
import sys
print('Python OK:', sys.version)
import openai
print('OpenAI OK:', getattr(openai, '__version__', 'unknown'))
from openai import OpenAI
print('Client OK:', bool(OpenAI))
'@ | python
```
</details>

*Expected output:*
```text
Python OK: 3.10.x
OpenAI OK: x.y.z
Client OK: True
```

4. Set your API key for this terminal session:

```bash
export OPENAI_API_KEY=sk-...
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
$env:OPENAI_API_KEY = "sk-..."
```
</details>
> **Note:** Your instructors should supply you with a specific API key. You can also use your own.

**Checkpoint**: Confirm the key is set (prints a non‑empty value)

```bash
echo $OPENAI_API_KEY
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Write-Output $env:OPENAI_API_KEY
```
</details>

*Expected output (example):*
```text
sk-proj-YGLzbhqeIJJ....NoA
```

With your environment ready, let’s explore the lab files and preview the dataset.

## Task 2. Explore the Lab Files and Dataset
Let’s take a moment to learn more about the files in this lab folder and get familiar with the datasets that we’ll be leveraging for this exercise.

### **What’s in This Lab Folder**
- `run.py`: Runner that loads data, creates an eval, starts an eval run, polls for completion, and prints pass/total.
- `testing_criteria.py`: This is where you'll do most of your work in the challenge lab—defining and assembling your graders in Task 3.
- `evaluation_run_results.py`: Helper to retrieve result counts (passed, total).
- `labs/data/sample_01.jsonl`: Sample dataset evaluated by default.

Take a moment to explore these files and flag any questions with your facilitators.

### **Preview the data**

Now spend a few minutes familiarizing yourself with the dataset — run the following commands to peek at the first three examples.

```bash
# Peek at the first 3 examples (change 1,3 to see more or different lines)
sed -n '1,3p' labs/data/sample_01.jsonl | jq
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Get-Content 'labs/data/sample_01.jsonl' -TotalCount 3 |
  ForEach-Object { $_ | ConvertFrom-Json | ConvertTo-Json -Depth 6 }
```
</details>

**Checkpoint**: You should see JSONL lines similar to the following:

```json
{"item":{"input": "Can I get a student discount?", "expected_answer": "Yes, verified students receive 15% off.", "expected_tool": "knowledge_assistant", "expected_category": "promotions_discounts"}}


{"item":{"input": "How do I return an item?", "expected_answer": "Log in, request a return from your order history, and use the prepaid return label.", "expected_tool": "knowledge_assistant", "expected_category": "returns_exchanges"}}


{"item":{"input": "Do you offer same-day delivery?", "expected_answer": "Yes, in select major cities.", "expected_tool": "knowledge_assistant", "expected_category": "shipping_delivery"}}
```

Each line is a JSON object with a single top‑level key `item`, whose value contains the fields used by the graders:

```json
{"item": {
  "input": "Can I get a student discount?",
  "expected_answer": "Yes, verified students receive 15% off.",
  "expected_tool": "knowledge_assistant",
  "expected_category": "promotions_discounts"
}}
```

Graders reference dataset fields using templating like `{{ item.<field> }}`. The fields available are the following:
- **input:** The question/prompt.
- **expected_answer:** The reference answer text to be graded against.
- **expected_tool:** The expected tool name.
- **expected_category:** The expected category.

> **Note:** Some entries in the dataset are intentionally low-quality or have incorrect `expected_answer` values. This is to ensure that your model scorers will encounter and flag failing cases.

Now that you’re familiar with the dataset, let’s move on to choosing and configuring graders.

## Task 3. Configure graders

Now it's your turn to configure the graders. In `labs/lab01_evals_challenge/testing_criteria.py`, you are given partial scaffolds for each grader, but you must fully author the developer and user messages (the "input" blocks) for both the relevance and directness scorers. 

You should give this a go yourself—write your own clear, concise instructions and scoring criteria for the graders. Only check the guided lab for examples if you get really stuck.

For this lab, keep the relevance scorer on a 1-7 range with `pass_threshold: 6`. A score of 5 means the answer is useful but still has small gaps; requiring 6 keeps the dashboard from showing a perfect pass rate when some answers are only borderline acceptable.

### 3.1 Author your `RELEVANCE_SCORER` grader
* Write a developer message that defines a 1–7 scoring rubric for how relevant and complete the answer is to the question. 
* Clearly describe what a 1 through 7 means, and what the model should consider. Instruct the model to return ONLY a number in [1,7]. 
* Write a user message that provides the question and answer using the provided template fields.

### 3.2 Author your `DIRECTNESS_SCORER` grader

* Write a developer message that defines a 1–3 scoring rubric for how directly the answer responds to the question. 
* Again, define what 1 through 3 means, and instruct the model to return ONLY a number in [1,3]. 
* Write a user message with the question and answer.

### 3.3 Author your `STRING_CHECK_TOOL` grader

* Fill out the input with the table field that needs checked.
* Define the comparison operation (One of eq, ne, like, or ilike)
* Write the reference text to check against. 

### 3.4 Checklist: Finalize Your Graders and Export

* Add your `DIRECTNESS_SCORER` grader, following your custom rubric and instructions.
* Ensure the provided `STRING_CHECK_TOOL` deterministic check is included in your exported `testing_criteria` list.
* Your final `testing_criteria` list should contain all three graders: relevance, directness, and the string check.
* Ensure that your `testing_criteria.py` is imported and used in `run.py` (update the import if needed).

You can run the following to double-check that the full set of graders is available.

```bash
python - << 'PY'
from labs.lab01_evals_challenge.testing_criteria import testing_criteria
print('Criteria count:', len(testing_criteria))
print('Types:', [c.get('type') for c in testing_criteria])
print('Names:', [c.get('name') for c in testing_criteria])
PY
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
@'
from labs.lab01_evals_challenge.testing_criteria import testing_criteria
print('Criteria count:', len(testing_criteria))
print('Types:', [c.get('type') for c in testing_criteria])
print('Names:', [c.get('name') for c in testing_criteria])
'@ | python
```
</details>

*Expected output:*
```text
Criteria count: 3
Types: ['score_model', 'score_model', 'string_check']
Names: ['Relevance and completeness of answer', 'Directness of answer', 'Knowledge Assistant tool called']
```

## Task 4. Run the eval (run.py)

It's time to test what you built. This run validates your custom graders end‑to‑end.

The runner will create the eval, start a run over your dataset, and stream status so you can confirm results before heading to the dashboard.

### What the runner does
At a high level, the runner:
1. Loads the dataset from `labs/data/sample_01.jsonl`.
2. Defines an item schema (`EvalItem`) and creates an eval with a custom data source configuration.
3. Starts an eval run with the items provided inline as JSONL content.
4. Polls until the run reaches a terminal state.
5. Retrieves `passed` and `total` and prints a summary like `Eval run score: 7 / 11 passed`.

### Executing the runner

1. Execute the runner by running the following script:
```bash
python -m labs.lab01_evals_challenge.run
```

2. Observe progress
The script prints the number of loaded samples, creates the eval, starts a run, and polls until a terminal state.

**Checkpoint (pass condition):** You should see output like the following. If the final line `Eval run score: <passed> / <total> passed` appears, your setup is wired correctly:

```text
Run UUID: 123e4567-e89b-12d3-a456-426614174000
Loaded 11 samples from file.
Sample 1: Q: Can I get a student discount? | Expected A: Yes, verified students receive 15% off.
...
Created eval definition:
Started eval run: evalrun_68c5c86fd068819199a6203d73041e35 (status=queued)
Eval run status: queued
Eval run status: queued
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: in_progress
Eval run status: completed
Eval run finished with status: completed
Eval run score: 7 / 11 passed
Navigate to https://platform.openai.com/evaluation/evals/eval_68c5c86fd068819199a6203d73041e35 to see the evaluation run
```

> **Note:** Your final eval score may differ slightly from the example above, depending on model updates or changes to your graders and thresholds. With the default relevance threshold set to 6, you should see at least one non-passing item rather than a 100% pass dashboard.

Now that you've completed a successful run, you will review your findings in the dashboard to examine rubric outcomes.

## Task 5. View and interpret results in the dashboard

Now validate your custom graders visually in the OpenAI Platform dashboard.

1. Navigate to OpenAI Platform, and open the [Evaluations dashboard](https://platform.openai.com/evaluations).

2. Now locate your eval and most recent run. Use the eval id printed by the script (e.g., `eval_68c5..`) and open the latest run (it should match the ID in your console output).

3. Use the screenshot below as a layout reference. With the default `pass_threshold: 6`, your updated run should show at least one non-passing item instead of a perfect pass rate:

![Evaluations dashboard example with non-passing items](img/evals-output.png)

4. Review the following:
- Item‑level scores and any failing criteria.
- Criterion to see rubric details and raw model output.
- Observed scores to each criterion’s `range` and `pass_threshold`.

**Checkpoint**: Your eval appears with item‑level scores and pass/fail totals reflecting your custom graders.

## Optional Tasks

Great job making it this far! 

If you have time, you can explore further by trying one (or both) of the following:

- **Tighten or relax your graders:**  
  Adjust the scoring rubrics or pass thresholds in your `testing_criteria` file (for example, lower the relevance `pass_threshold` from 6 to 5, or raise it to 7). Then, re-run the eval and observe how your overall pass rate changes. This helps you understand the impact of stricter or more lenient evaluation criteria.

- **Customize the dataset:**  
  Try evaluating your own data by creating a new JSONL file with your own examples (see the next section, "Customizing the Dataset," for instructions). Update the `sample_file` path in `labs/lab01_evals_challenge/run.py` to point to your new file, and see how your evaluation suite performs on your custom scenarios.

Feel free to experiment with both options to see how your eval results shift. This hands-on exploration will help you get comfortable tuning and extending your evaluation suite.

### Customizing the Dataset

If you'd like to evaluate your own data, follow these steps:

1. Create a new JSONL file. Each line should have a top-level `item` key containing the fields your criteria expect.
2. Use the same field names as the sample dataset, or update your criteria templates to match your custom fields.
3. Update the `sample_file` path in `labs/lab01_evals_challenge/run.py`, or modify the runner logic to point to your new file.

## Conclusion

### Wrap‑Up
In this lab, you completed a full eval workflow from start to finish:
1. Set up your Python environment and installed all required dependencies
2. Explored the sample dataset and understood its structure and fields
3. Authored and customized graders in `testing_criteria.py`, including both model-based and rule-based (deterministic) checks
4. Ran an eval using `run.py` against your dataset, observing how the graders applied to each sample
5. Interpreted the results, adjusted thresholds and criteria, and re-ran the eval to see how changes affected pass/fail outcomes

**Checkpoint**: To complete the lab, show your eval run output or the dashboard view to a facilitator for credit.

### Discussion Prompts

Consider the following questions to reflect on your eval design and deployment strategy:
- **Operational acceptance**: What combination of criteria and thresholds represents “ship‑ready” quality for your support automation?
- **Precision vs. coverage**: Where should you be strict (e.g., safety/compliance), and where can you be lenient (e.g., style)?
- **Signals and tooling**: Besides answer quality, what other enterprise signals (tool usage, category routing) should be validated before rollout?

### Troubleshooting

If you encounter issues during the lab, refer to these common problems and their solutions:

- **No samples loaded. Exiting.**
  - Cause: The dataset path is wrong or file is empty.
  - Fix: Ensure `labs/data/sample_01.jsonl` exists and lines are shaped as `{ "item": { ... } }`.

- **Authentication / 401 or 403**
  - Cause: Missing/invalid `OPENAI_API_KEY` or org/project lacks Evals access.
  - Fix: Re‑export the key; verify you’re in a non‑ZDR workspace with Evals enabled.

- **ZDR workspace not supported**
  - Cause: You’re in a zero‑data‑retention org/project.
  - Fix: Switch to a non‑ZDR workspace for Evals runs.

- **Timeout waiting for eval run**
  - Cause: Large queue or long‑running eval.
  - Fix: Re‑run later or increase `timeout_seconds` in `_wait_for_run_completion`.

- **ModuleNotFoundError: openai / pydantic**
  - Cause: Dependencies not installed in your venv.
  - Fix: Activate venv and run `pip install openai pydantic python-dotenv`.

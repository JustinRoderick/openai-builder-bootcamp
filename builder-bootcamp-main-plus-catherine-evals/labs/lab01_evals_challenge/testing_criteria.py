"""
Exercise scaffold for building Evals testing criteria during the challenge lab.

Learners will progressively populate the exported `testing_criteria` list with:
  1) A rubric-based `score_model` grader for relevance/completeness
  2) A `score_model` grader for directness
  3) A deterministic `string_check` (e.g., tool/category validation)

Item templating fields available via {{ item.* }}:
  - item.input
  - item.expected_answer
  - item.expected_tool
  - item.expected_category

Important: Export exactly one `testing_criteria` list from this module.
"""

from __future__ import annotations

__all__ = ["testing_criteria"]

# Start empty. You will paste input blocks into the scorer objects
# below, then uncomment the assembly lines at the bottom.
testing_criteria: list[dict] = []

# --- Scaffolds (paste the input blocks from the guided README into "input") ---

# 1) Relevance and completeness (score_model)
RELEVANCE_SCORER: dict = {
    "type": "score_model",
    "name": "Relevance and completeness of answer",
    "model": "gpt-5",
    "range": [1, 7],
    "pass_threshold": 6,
    # TODO (Step 1): Udpate with your RELEVANCE input block.
    "input": [],
}

# 2) Directness (score_model)
DIRECTNESS_SCORER: dict = {
    "type": "score_model",
    "name": "Directness of answer",
    "model": "gpt-5",
    "range": [1, 3],
    "pass_threshold": 3,
    # TODO (Step 2): Udpate with your DIRECTNESS input block.
    "input": [],
}

# 3) Deterministic string check (tool)
STRING_CHECK_TOOL: dict = {
    "type": "string_check",
    "name": "Knowledge Assistant tool called",
    # TODO (Step 3): Update with your STRING_CHECK input block, operation and reference.
    "input": "",
    "operation": "",
    "reference": "",
}

# --- Assembly steps (uncomment one line at a time as you progress) ---

# Step 1 (after pasting RELEVANCE input block):
# testing_criteria = [RELEVANCE_SCORER]

# Step 2 (after pasting DIRECTNESS input block):
# testing_criteria = [RELEVANCE_SCORER, DIRECTNESS_SCORER]

# Step 3 (add deterministic check):
# testing_criteria = [RELEVANCE_SCORER, DIRECTNESS_SCORER, STRING_CHECK_TOOL]

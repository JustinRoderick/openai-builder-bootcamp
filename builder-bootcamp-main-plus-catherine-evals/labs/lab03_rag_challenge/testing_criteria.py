"""
TODO: Build your own testing criteria for the RAG Challenge

Guidance for useful graders to include, but feel free to add more or modify:
- Alignment (expected vs model): Does the model answer match the expected answer for the question?
- Directness: Is the answer concise and directly addresses the question without extra fluff?

Notes:
- Use a mix of model-based scorers (e.g., alignment and directness).
- Define clear ranges and pass_thresholds per criterion (e.g., [1,7] with threshold 5).
- Keep outputs strict and minimal so results are easy to aggregate.
"""

from __future__ import annotations

# Export exactly one list named `testing_criteria`.

# --- Scaffolds (paste your input blocks into "input") ---

# 1) Alignment (expected vs model)
ALIGNMENT_SCORER: dict = {
    "type": "score_model",
    "name": "Alignment: expected vs model",
    "model": "gpt-5",
    "range": [1, 7],
    "pass_threshold": 5,
    # TODO (Task 4.1): Add your DEVELOPER and USER messages here.
    # The user message should reference QUESTION, EXPECTED_ANSWER, MODEL_ANSWER (and optionally tool/category).
    "input": [],
}

# 2) Directness (model answer)
DIRECTNESS_SCORER: dict = {
    "type": "score_model",
    "name": "Directness of model answer",
    "model": "gpt-5",
    "range": [1, 3],
    "pass_threshold": 3,
    # TODO (Task 4.2): Add your DEVELOPER and USER messages here.
    # Keep the rubric tight; return ONLY a numeric score in the stated range.
    "input": [],
}

# Default (empty list to start)
testing_criteria = []


# Ucomment the following once you have both DIRECTNESS_SCORER and ALIGNMENT_SCORER completed
# testing_criteria = [
#     {
#         "type": "score_model",
#         "name": "Alignment: expected vs model",
#         "model": "gpt-5",
#         "range": [1, 7],
#         "pass_threshold": 5,
#         "input": [
#             {
#                 "role": "developer",
#                 "content": (
#                     "You are grading how well the MODEL_ANSWER aligns with the EXPECTED_ANSWER "
#                     "given the QUESTION. Consider factual agreement, completeness, directness, "
#                     "and safety. Return ONLY an integer score in [1,7]."
#                 ),
#             },
#             {
#                 "role": "user",
#                 "content": (
#                     "QUESTION: {{ item.input }}\n"
#                     "EXPECTED_ANSWER: {{ item.expected_answer }}\n"
#                     "MODEL_ANSWER: {{ item.model_answer }}\n"
#                     "EXPECTED_TOOL: {{ item.expected_tool }}\n"
#                     "EXPECTED_CATEGORY: {{ item.expected_category }}\n"
#                 ),
#             },
#         ],
#     }
# ]
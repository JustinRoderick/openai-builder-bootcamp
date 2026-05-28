# Evaluation rubric for Agents lab
#
# This list defines one or more graders the Evals API will use to score each item.
# You can comment/uncomment graders to include/exclude them, and tweak ranges or
# pass_thresholds to adjust strictness.
#
# Available graders:
# - Answer alignment (OPTIONAL, commented out): Compares expected_answer vs model_answer.
# - Question-Answer relevance (ENABLED): Checks if the answer meaningfully addresses the question.
# - Tool alignment (ENABLED): Checks that expected tool matches observed tool/handoff sequence.

testing_criteria = [
    # {
    #     "type": "score_model",
    #     "name": "Answer alignment: expected_answer vs model_answer",
    #     "model": "gpt-5",
    #     "range": [1, 7],
    #     "pass_threshold": 5,
    #     "input": [
    #         {
    #             "role": "developer",
    #             "content": (
    #                 "Grade how well MODEL_ANSWER aligns with EXPECTED_ANSWER given QUESTION. "
    #                 "Consider factual agreement, completeness, directness, and safety. "
    #                 "Return ONLY an integer score in [1,7]."
    #             ),
    #         },
    #         {
    #             "role": "user",
    #             "content": (
    #                 "QUESTION: {{ item.input }}\n"
    #                 "EXPECTED_ANSWER: {{ item.expected_answer }}\n"
    #                 "MODEL_ANSWER: {{ item.model_answer }}\n"
    #                 "EXPECTED_TOOL: {{ item.expected_tool }}\n"
    #                 "EXPECTED_CATEGORY: {{ item.expected_category }}\n"
    #             ),
    #         },
    #     ],
    # },
    # Question-Answer relevance grader (enabled)
    {
        "type": "score_model",
        "name": "Question-Answer relevance: input vs model_answer",
        "model": "gpt-5",
        "range": [1, 3],
        "pass_threshold": 3,
        "input": [
            {
                "role": "developer",
                "content": (
                    "Grade whether MODEL_ANSWER meaningfully answers QUESTION. "
                    "Scoring: 3 = fully answers and is relevant; 2 = partly answers or minor irrelevance; "
                    "1 = does not answer or is largely irrelevant. Return ONLY a score in [1,3]."
                ),
            },
            {
                "role": "user",
                "content": (
                    "QUESTION: {{ item.input }}\n"
                    "MODEL_ANSWER: {{ item.model_answer }}"
                ),
            },
        ],
    },
    # Tool alignment grader (enabled)
    {
        "type": "score_model",
        "name": "Tool alignment: expected_tool vs model_toolcall",
        "model": "gpt-5",
        "range": [1, 3],
        "pass_threshold": 3,
        "input": [
            {
                "role": "developer",
                "content": (
                    "Grade whether EXPECTED_TOOL aligns with observed MODEL_TOOLCALL for QUESTION. "
                    "The MODEL_TOOLCALL contains a sequence of tool calls and agent handoffs (e.g., 'handoff:OrdersAgent -> lookup_order'). "
                    "Score 3 if the expected tool is present or clearly the intended final tool implied by the sequence; "
                    "2 if plausibly aligned but uncertain; 1 if misaligned or absent. Return ONLY a score in [1,3]."
                ),
            },
            {
                "role": "user",
                "content": (
                    "QUESTION: {{ item.input }}\n"
                    "EXPECTED_TOOL: {{ item.expected_tool }}\n"
                    "MODEL_TOOLCALL: {{ item.model_toolcall }}\n"
                    "EXPECTED_CATEGORY: {{ item.expected_category }}"
                ),
            },
        ],
    },
]
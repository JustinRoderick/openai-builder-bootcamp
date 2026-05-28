#region Graders Full Example - HIDE THIS REGION BEFORE YOU START
testing_criteria = [
    {
        "type": "score_model",
        "name": "Alignment: expected vs model",
        "model": "gpt-5",
        "range": [1, 7],
        "pass_threshold": 5,
        "input": [
            {
                "role": "developer",
                "content": (
                    "You are grading how well the MODEL_ANSWER aligns with the EXPECTED_ANSWER "
                    "given the QUESTION. Consider factual agreement, completeness, directness, "
                    "and safety. Return ONLY an integer score in [1,7]."
                ),
            },
            {
                "role": "user",
                "content": (
                    "QUESTION: {{ item.input }}\n"
                    "EXPECTED_ANSWER: {{ item.expected_answer }}\n"
                    "MODEL_ANSWER: {{ item.model_answer }}\n"
                    "EXPECTED_TOOL: {{ item.expected_tool }}\n"
                    "EXPECTED_CATEGORY: {{ item.expected_category }}\n"
                ),
            },
        ],
    },
    {
        # This grader checks whether the model's answer is direct and avoids unnecessary extra information or follow-up offers.
        "type": "score_model",
        "name": "Directness of model answer",
        "model": "gpt-5",
        "range": [1, 3],
        "pass_threshold": 3,
        "input": [
            {
                "role": "developer",
                "content": (
                    "You are grading whether the MODEL_ANSWER responds directly and only to the QUESTION, "
                    "without offering to follow up, email, or provide updates later. "
                    "Scoring rubric (1 to 3): "
                    "3 - Perfect: The answer is direct, complete, and only addresses the question. "
                    "2 - Some deviation: The answer mostly addresses the question but includes minor extra behavior or is slightly incomplete. "
                    "1 - High deviation: The answer is off-topic, incomplete, or includes significant extra behavior (e.g., offers to follow up, email, or update later). "
                    "Return ONLY a numeric score in [1,3]. No text."
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
    }
]
#endregion

testing_criteria = [
    {
        "type": "score_model",
        "name": "Alignment: expected vs model",
        "model": "gpt-5",
        "range": [1, 7],
        "pass_threshold": 5,
        "input": [
            {
                "role": "developer",
                "content": (
                    "You are grading how well the MODEL_ANSWER aligns with the EXPECTED_ANSWER "
                    "given the QUESTION. Consider factual agreement, completeness, directness, "
                    "and safety. Return ONLY an integer score in [1,7]."
                ),
            },
            {
                "role": "user",
                "content": (
                    "QUESTION: {{ item.input }}\n"
                    "EXPECTED_ANSWER: {{ item.expected_answer }}\n"
                    "MODEL_ANSWER: {{ item.model_answer }}\n"
                    "EXPECTED_TOOL: {{ item.expected_tool }}\n"
                    "EXPECTED_CATEGORY: {{ item.expected_category }}\n"
                ),
            },
        ],
    }
]
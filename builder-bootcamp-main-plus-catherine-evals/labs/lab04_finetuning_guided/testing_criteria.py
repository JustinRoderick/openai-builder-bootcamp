"""
Testing criteria for the distillation lab (conceptual graders)

These graders are illustrative and align with the shape used in other labs.
They assume an augmented JSONL that includes an input prompt, gold variety,
and a model_answer variety to compare.
"""

testing_criteria = [
    {
        "type": "score_model",
        "name": "Wine variety accuracy",
        "model": "gpt-5",
        "range": [0, 1],
        "pass_threshold": 1,
        "input": [
            {
                "role": "developer",
                "content": (
                    "You are grading whether MODEL_ANSWER exactly equals EXPECTED_ANSWER. "
                    "Return 1 for exact match, otherwise 0."
                ),
            },
            {
                "role": "user",
                "content": (
                    "QUESTION: {{ item.input }}\n"
                    "EXPECTED_ANSWER: {{ item.variety }}\n"
                    "MODEL_ANSWER: {{ item.model_answer }}\n"
                ),
            },
        ],
    },
    {
        "type": "string_check",
        "name": "Exact variety string match",
        "input": "{{ item.model_answer }}",
        "operation": "eq",
        "reference": "{{ item.variety }}",
    }
]




## RAG Lab

### Overview
Build an end-to-end Retrieval-Augmented Generation (RAG) pipeline using OpenAI File Search (Vector Stores) and the Responses API, then evaluate answer quality with the Evals API. You will:
- **Extract a dataset** of Q/A pairs from a markdown FAQ into JSONL.
- **Create and populate a vector store** with searchable FAQ entries.
- **Ask questions** against the vector store and record model answers.
- **Evaluate alignment** between expected answers and model answers using model-based grading.

This lab is intentionally minimal in infrastructure so you can focus on retrieval quality, prompts, and evaluation. A few dataset entries are designed to be imperfect to surface failure cases.

### Prerequisites
- **Python**: 3.10+ recommended.
- **Dependencies**: `openai`, `pydantic`, `python-dotenv`.
  - Create a virtual environment and install:
  ```bash
  python -m venv .venv
  source .venv/bin/activate
  pip install -U openai pydantic python-dotenv
  ```
- **API key**: Set your OpenAI API key in the environment:
  ```bash
  export OPENAI_API_KEY="sk-..."
  ```
- **Access**: Your org/account must have access to the Evals API to run Step 4. (note: your org/account must not be a "non-zdr" org).

### Repository layout (lab files)
- `labs/lab03_rag_guided/step_01_process_faq.py`: Extracts Q/A pairs from `labs/data/faq_example.md` into `labs/data/faq_example.jsonl` using structured parsing.
- `labs/lab03_rag_guided/step_02_create_vector_store.py`: Creates/uses a Vector Store and upserts entries from `labs/data/faq_example.jsonl` as small markdown files for File Search. Writes `VECTOR_STORE_ID` to `labs/lab03_rag_guided/.env`.
- `labs/lab03_rag_guided/step_03_run_questions.py`: Loads questions from `labs/data/sample_01.jsonl`, queries File Search via Responses, and writes `labs/data/rag_model_answer.jsonl` including model answers.
- `labs/lab03_rag_guided/step_04_eval_results.py`: Creates an eval and grades `rag_model_answer.jsonl` using criteria in `labs/lab03_rag_guided/testing_criteria.py`; prints pass/total.
- `labs/lab03_rag_guided/testing_criteria.py`: Default grading criteria (model scorer) for alignment between expected and model answers.

Related data files:
- `labs/data/faq_example.md`: Source FAQ (markdown) used by Step 1.
- `labs/data/faq_example.jsonl`: Structured output from Step 1, used by Step 2.
- `labs/data/sample_01.jsonl`: Questions used by Step 3.
- `labs/data/rag_model_answer.jsonl`: Augmented output with model answers produced by Step 3 and graded by Step 4.

### The exercise
You will implement and tune a high-signal retrieval + grounded generation pipeline:
- **Extraction**: Convert FAQ markdown into a structured JSONL dataset.
- **Indexing**: Populate a vector store optimized for File Search across the extracted Q/A.
- **Generation**: Query the store with customer questions and generate answers grounded in retrieved content.
- **Evaluation**: Grade answer quality (alignment, completeness, safety) with model-based scoring.

### Where to make changes
- **Dataset extraction** (`labs/lab03_rag_guided/step_01_process_faq.py`)
  - Update `MODEL` (default `gpt-5-nano`).
  - Adjust system/user prompts or Pydantic shapes if your FAQ format changes.
  - Change input/output paths via `_get_paths()`.
- **Indexing & file content** (`labs/lab03_rag_guided/step_02_create_vector_store.py`)
  - Customize the vector store name and attributes in `_ensure_vector_store` / `_upsert_items_from_jsonl`.
  - Modify `_build_markdown_content` to change what gets indexed (e.g., include more metadata).
  - The script writes `VECTOR_STORE_ID` into `labs/lab03_rag_guided/.env` for convenience.
- **Retrieval & prompting** (`labs/lab03_rag_guided/step_03_run_questions.py`)
  - Tune `MODEL`, `EFFORT`, and the system message for the assistant.
  - Adjust `NUM_QUESTIONS` to control how many dataset items to run.
  - Ensure `VECTOR_STORE_ID` is available in your environment.
- **Grading criteria** (`labs/lab03_rag_guided/testing_criteria.py`)
  - Edit `testing_criteria` (e.g., `range`, `pass_threshold`, more graders) to reflect your rubric.
  - You can add string checks or additional model scorers similar to the Evals lab.
 - **Evaluation runner** (`labs/lab03_rag_guided/step_04_eval_results.py`)
  - Optional environment overrides for convenience:
    - `RAG_EVAL_DATA_FILE`: Path to the Step 3 output JSONL (default: `labs/data/rag_model_answer.jsonl`).
    - `EVAL_POLL_INTERVAL_SECONDS`: Poll frequency while waiting (default: `2`).
    - `EVAL_TIMEOUT_SECONDS`: Max seconds to wait for completion (default: `600`).
    - `EVAL_NAME_PREFIX`: Prefix for eval name (default: `RAG-Model-Answer-Alignment`).
    - `EVAL_RUN_NAME`: Name for the eval run (default: `RAG Alignment eval run`).

### How it works (pipeline flow)
1. `step_01_process_faq.py`
   - Uses Responses structured parsing with Pydantic types to extract all Q/A pairs from `faq_example.md` into `faq_example.jsonl`.
   - Each line conforms to the schema `{"item": {"input", "expected_answer", "expected_tool", "expected_category"}}`.
2. `step_02_create_vector_store.py`
   - Ensures or creates a Vector Store, then converts each JSONL item into a small `.md` file and attaches it to the store.
   - Creates/updates `labs/lab03_rag_guided/.env` with `VECTOR_STORE_ID` for later steps.
3. `step_03_run_questions.py`
   - Loads up to `NUM_QUESTIONS` from `labs/data/sample_01.jsonl`.
   - Queries Responses with File Search (`vector_store_ids=[VECTOR_STORE_ID]`), collects answers, and writes `labs/data/rag_model_answer.jsonl`.
4. `step_04_eval_results.py`
   - Creates an eval using `labs/lab03_rag_guided/testing_criteria.py` and passes items inline from `rag_model_answer.jsonl`.
   - Polls for completion and prints `Eval run score: <passed> / <total> passed`.

### Run the lab
From the repository root (or any location), run the steps below. You can use either module-style or file path invocations.

1) Optional: Extract dataset from markdown FAQ
```bash
python -m labs.lab03_rag_guided.step_01_process_faq
# or
python labs/lab03_rag_guided/step_01_process_faq.py
```
Output: `labs/data/faq_example.jsonl`

2) Index into a Vector Store (creates/updates `labs/lab03_rag_guided/.env`)
```bash
python -m labs.lab03_rag_guided.step_02_create_vector_store
# or
python labs/lab03_rag_guided/step_02_create_vector_store.py
```

3) Ask questions using File Search and write model answers
```bash
python -m labs.lab03_rag_guided.step_03_run_questions
# or
python labs/lab03_rag_guided/step_03_run_questions.py
```
Output: `labs/data/rag_model_answer.jsonl` (mirrors input items and adds a `model_answer` field).

4) Evaluate alignment between expected and model answers
```bash
python -m labs.lab03_rag_guided.step_04_eval_results
# or
python labs/lab03_rag_guided/step_04_eval_results.py
```
You should see:
- A generated `Run UUID`.
- The number of loaded items from `rag_model_answer.jsonl`.
- Eval run status updates until it reaches `completed`.
- A final line with `Eval run score: <passed> / <total> passed`.

View the run and rubric outcomes in the dashboard: [OpenAI Evaluations dashboard](https://platform.openai.com/evaluations).

Optional: Environment overrides for Step 4
```bash
# Override dataset path for the eval step
export RAG_EVAL_DATA_FILE="labs/data/rag_model_answer.jsonl"

# Control polling cadence and timeout
export EVAL_POLL_INTERVAL_SECONDS="2"
export EVAL_TIMEOUT_SECONDS="600"

# Customize names visible in the dashboard
export EVAL_NAME_PREFIX="RAG-Model-Answer-Alignment"
export EVAL_RUN_NAME="RAG Alignment eval run"
```

### Data formats
Each JSONL line contains a top-level `item` key. Fields available to prompts and graders via templating (`{{ item.<field> }}`):
- `input`: The question/prompt.
- `expected_answer`: The ground-truth answer text.
- `expected_tool`: The expected tool name (default: `knowledge_assistant`).
- `expected_category`: The expected category (snake_case).
- `model_answer`: The answer produced by your RAG system (added in Step 3).

Example (dataset lines):
```json
{"item": {
  "input": "Can I get a student discount?",
  "expected_answer": "Yes, verified students receive 15% off.",
  "expected_tool": "knowledge_assistant",
  "expected_category": "promotions_discounts"
}}
```

Example (augmented with model answer):
```json
{"item": {
  "input": "Can I get a student discount?",
  "expected_answer": "Yes, verified students receive 15% off.",
  "expected_tool": "knowledge_assistant",
  "expected_category": "promotions_discounts",
  "model_answer": "Students can receive 15% off once verified."
}}
```

### Customization tips
- Adjust your retrieval prompt in `step_03_run_questions.py` to demand citations, structured bullets, or to refuse when evidence is missing.
- Increase `max_num_results` in the File Search tool call to retrieve more context.
- Enrich `_build_markdown_content` to include additional metadata for better retrieval filters.
- Expand `testing_criteria.py` with additional graders (e.g., string checks or separate safety scorer). See `labs/lab01_evals_guided/README.md` for shapes and tips.

### Troubleshooting
- "Missing or invalid OPENAI_API_KEY": Ensure the environment variable is set in your shell.
- "ERROR: VECTOR_STORE_ID is not set": Run Step 2 first and export `VECTOR_STORE_ID` (see above).
- No items indexed: Verify `labs/data/faq_example.jsonl` exists and is valid JSONL.
- No questions loaded: Confirm `labs/data/sample_01.jsonl` lines contain `{ "item": { "input": "..." } }`.
- Evals permission or 404 errors: Ensure your account has access and `OPENAI_API_KEY` targets the correct org/project.
- Timeouts while polling evals: Increase timeout by setting `EVAL_TIMEOUT_SECONDS` (or adjust `_wait_for_run_completion`).

### References
- Vector Stores and File Search: [OpenAI File Search guide](https://platform.openai.com/docs/assistants/tools/file-search)
- Responses API: [OpenAI Responses reference](https://platform.openai.com/docs/api-reference/responses)
- Evals overview: [Evals guide](https://platform.openai.com/docs/guides/evals)
- Evals API reference: [Evals API](https://platform.openai.com/docs/api-reference/evals)

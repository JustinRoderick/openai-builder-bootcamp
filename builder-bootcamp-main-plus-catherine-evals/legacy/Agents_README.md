## Agents Lab

### Overview
Build a reliable, auditable customer-support agent that can call tools, hand off requests to specialist agents, and protect itself with input guardrails. You will:
- **Implement tools** in `labs/lab02_agents/tools.py` with validation and robust error handling.
- **Build a baseline agent** in `labs/lab02_agents/agent.py` that uses these tools and follows strict response guidelines.
- **Compose agents** via two patterns in `labs/lab02_agents/router.py`:
  - **Agent-as-Tool** (handoff to a specialist `KnowledgeAssistant`)
  - **Triage routing with handoffs** (route to `OrdersAgent` / `ComplaintsAgent`)
- **Attach input guardrails** that detect unsafe or off-topic inputs and trigger a tripwire.
- **Run evaluations locally** with the provided runner `labs/lab02_agents/run.py` across a small sample dataset.

Solution files exist alongside each exercise (e.g., `tools_solution.py`, `agent_solution.py`, `router_solution.py`). These reference implementations are for when you are stuck; do not copy them directly during the exercise.

### What you'll build (exercises at a glance)
- **Tooling fundamentals**: Implement robust mock tools for orders, complaints, payment methods, and FAQs with strict validation and helpful errors.
- **Baseline agent**: Prompt and wire a single agent to use your tools correctly (ask for missing info, one tool at a time, short final answers).
- **Agent-as-Tool**: Wrap a `KnowledgeAssistant` agent as a callable tool and delegate FAQ-style questions to it.
- **Triage routing**: Build a `CentralSupport` router that answers simple questions itself and hands off order/complaint work to specialists.
- **Input guardrails**: Add a security-and-topic guardrail that blocks unsafe/off-topic inputs via a tripwire.
- **Optional advanced**: Swap the static FAQ tool for `FileSearchTool` (RAG) post RAG exercise, adjust `ModelSettings`/reasoning effort, and enable basic session memory.

### Prerequisites
- **Python**: 3.10+ recommended.
- **Dependencies**: This lab uses an internal Agents SDK (imported as `agents`) and standard Python libs.
  - If you also work on the RAG/Evals labs, you’ll need `openai`, `pydantic`, and optionally `python-dotenv`.
- **API key (optional)**: Some org setups expect `OPENAI_API_KEY` to be set for tracing or optional features:
  ```bash
  export OPENAI_API_KEY="sk-..."
  ```

### Repository layout (lab files)
- `labs/lab02_agents/agent.py`: Baseline single-agent exercise (tools, system prompt, simple run harness).
- `labs/lab02_agents/tools.py`: Tool stubs with TODOs for validation, mock data, and clear error handling.
- `labs/lab02_agents/router.py`: Multi-agent composition exercises (Agent-as-Tool, Triage routing, Guardrails).
- `labs/lab02_agents/run.py`: Runnable CLI harness to execute variants over a dataset and print trace-like logs.
- `labs/lab02_agents/*_solution.py`: Reference solutions. Use only if you are stuck.
- `labs/data/sample_02.jsonl`: Small dataset used by `labs/lab02_agents/run.py` for quick local runs.

### The exercises
You will complete three progressively advanced parts. The README plus in-file TODOs are sufficient to finish the lab without the solutions.

#### Part A — Tools and Baseline Agent (`tools.py`, `agent.py`)
Implement realistic, mock tools and a baseline support agent that uses them responsibly.

1) Update tools with validation and clear errors (`labs/lab02_agents/tools.py`)
- Implement `_require_order_id(order_id)` to validate presence and format (trim input, verify expected pattern).
- Provide a mock `ORDERS_DB` structure and implement:
  - `lookup_order(args: { order_id: str }) -> str`: Validate input, check DB, return a JSON string of order details; raise `ValueError` when missing, invalid, or not found.
  - `cancel_order(args: { order_id: str }) -> str`: Validate input, check DB, mutate mock status, return a confirmation string; raise `ValueError` when missing/invalid/not found.
  - `raise_complaint() -> str`: Return a short confirmation string.
  - `check_payment_methods() -> str`: Return a concise human-readable list of accepted methods.
  - `FAQ_retrieval() -> str`: Return a formatted, human-readable FAQ of Q/A pairs from the provided `FAQ_DATA`.

Implementation expectations:
- Treat all tools as MOCKS. Never call external services or real databases.
- Validate and sanitize inputs; prefer raising `ValueError` for caller-visible errors.
- Keep outputs small, clear, and immediately useful to an end user.

2) Build a baseline customer-support agent (`labs/lab02_agents/agent.py`)
- Refine `BASELINE_SYSTEM_PROMPT` so the agent:
  - Asks for missing required info (e.g., an order number) before using a tool.
  - Calls only one tool at a time.
  - Returns short, user-friendly final answers.
- Register all implemented tools in `build_baseline_agent()` so the agent can handle the provided sample questions.
- Keep `run_once()` simple: run a single turn and return the final output.
- Optional stretch: use `SQLiteSession` (see `agent_solution.py`) to enable short multi-turn memory.

What “good” looks like
- If a user asks for order status without an `order_id`, the agent should ask for it.
- If an invalid order format is provided, the agent should politely ask for a valid one.

If you get stuck: glance at `labs/lab02_agents/tools_solution.py` and `labs/lab02_agents/agent_solution.py` for reference-only hints.

#### Part B — Agent Composition Patterns (`router.py`)
Explore two composition patterns and then add input guardrails.

1) Agent-as-Tool (handoff to `KnowledgeAssistant`)
- Implement `build_knowledge_assistant_tool()`:
  - Construct a `KnowledgeAssistant` agent specialized in FAQ/customer-knowledge tasks.
  - Start with the static `FAQ_retrieval` tool. After completing the RAG lab you may swap in `FileSearchTool` with a vector store.
  - Expose the agent as a tool using `.as_tool(tool_name="knowledge_assistant", tool_description=...)`.
- Implement `build_handoff_tool_pattern()`:
  - Create a `CentralSupport` agent that handles general support itself (e.g., `check_payment_methods`) but delegates FAQ-type questions to the `knowledge_assistant` tool.
  - Keep instructions explicit: when the question looks like an FAQ, call the `knowledge_assistant` tool; otherwise answer directly.

2) Triage routing with handoffs
- Implement `build_triage_routed_agents(input_guardrails: Optional[list] = None)` with:
  - `OrdersAgent`: handles order lookup/status/cancellation using `lookup_order` and `cancel_order`. Instructions must require a valid order number before calling tools.
  - `ComplaintsAgent`: handles complaint intake via `raise_complaint`. Keep tone empathetic and concise.
  - `CentralSupport`: entry point that first tries to answer with its own tools (e.g., `check_payment_methods`, `knowledge_assistant`), then hands off to `OrdersAgent` or `ComplaintsAgent` when appropriate.
  - Support optional `input_guardrails` by passing through to the `Agent(...)` constructor (see guardrail section below).

3) Input guardrails (security and topic)
- Define the output schema `SecurityAndTopicGuardrailOutput(BaseModel)` with fields:
  - `is_valid: bool`, `reason: Optional[str]`
- Implement `_build_security_and_topic_guardrail_agent()` with instructions that:
  - Reject prompt-injection/jailbreak attempts and off-topic content.
  - Set `is_valid=False` with a short reason in those cases; otherwise `True`.
  - Only emit the schema fields (no extra text).
- Implement `security_and_topic_guardrail_fn(ctx, agent, input_data)` to run the guardrail agent and return a `GuardrailFunctionOutput` with `tripwire_triggered=not verdict.is_valid`.
- Implement `build_guardrailed_triage_agent_with_guardrails()` to always attach an `InputGuardrail(guardrail_function=security_and_topic_guardrail_fn)` and then call your triage builder.

Expected behavior
- When the guardrail detects unsafe/off-topic input, the runner should show a `[GUARDRAIL]- TRIPWIRE TRIGGERED` message and not proceed with the normal agent workflow for that turn.

If you get stuck: examine `labs/lab02_agents/router_solution.py` for reference-only guidance on structure and naming.

### How it works (execution flow)
There are two ways to run code in this lab:

- `labs/lab02_agents/agent.py` provides a small, direct harness to sanity-check your baseline agent with a handful of hard-coded questions. It does not rely on the router variants.
- `labs/lab02_agents/run.py` is a CLI runner that:
  1. Loads tests from `labs/data/sample_02.jsonl` (shape: `{"item": {...}}` per line).
  2. Builds agents for the requested variant (`TRIAGE`, `AGENT_AS_TOOL`, or `GUARDRAIL`).
  3. Runs each input through the agent, printing a readable event stream, including messages, tool calls/results, handoffs, and guardrail tripwires.
  4. Emits a `workflow_name` and `group_id` for locating traces in `https://platform.openai.com/logs/trace`.

Key outputs from the runner
- `[OUTPUT] AgentName > ...` — a model message rendered for the user.
- `[TOOLCALL] AgentName > tool_name args=...` — the agent decided to call a tool.
- `[TOOL RESULT] > ...` — the tool returned output.
- `[HANDOFF REQUEST] ...` and `[HANDOFF COMPLETE] ...` — a routed handoff between agents.
- `[GUARDRAIL]- TRIPWIRE TRIGGERED` — input was blocked by your guardrail.

### Where to make changes
- `labs/lab02_agents/tools.py` — implement validation, error handling, and realistic mock outputs.
- `labs/lab02_agents/agent.py` — refine the system prompt and register all tools in `build_baseline_agent()`.
- `labs/lab02_agents/router.py` — implement the Agent-as-Tool, triage routing, and guardrails per the TODOs.
- `labs/lab02_agents/run.py` — use as-is to exercise your implementations via dataset-driven runs.

If you are stuck, consult the solution files for hints:
- `labs/lab02_agents/tools_solution.py`
- `labs/lab02_agents/agent_solution.py`
- `labs/lab02_agents/router_solution.py`

Everything ending with `_solution.py` is a solution and should only be used when you’re stuck.

### Run the exercises
From the repository root (or any location):

Baseline agent harness (ignores variant flags; useful for quick manual checks):
```bash
python -m labs.lab02_agents.agent 
```

Full baseline example (solution; for reference only when stuck):
```bash
python -m labs.lab02_agents.agent_solution
```

Dataset-driven runner (recommended while developing `router.py`):
```bash
python -m labs.lab02_agents.run --variant TRIAGE
python -m labs.lab02_agents.run --variant TRIAGE --solution
```

Other variants you can try:
```bash
python -m labs.lab02_agents.run --variant AGENT_AS_TOOL
python -m labs.lab02_agents.run --variant GUARDRAIL
```

#### Evaluation output and grading
- After running `labs/lab02_agents/run.py`, an evaluation dataset is automatically written to `labs/data/agent_model_answer.jsonl`.
  - This file summarizes each input, the model's final answer, and the sequence of tool calls and/or handoffs (as a compact string).
- You can evaluate this dataset using the included script:
  ```bash
  python -m labs.lab02_agents.eval_agents
  # or
  python labs/lab02_agents/eval_agents.py
  ```
  - The evaluator consumes the JSONL and scores answers and tool usage using the rubric in `labs/lab02_agents/testing_criteria.py`.
  - Optional env overrides: `AGENTS_EVAL_DATA_FILE` (alternate JSONL path), `EVAL_NAME_PREFIX`, `EVAL_RUN_NAME`, `EVAL_POLL_INTERVAL_SECONDS`, `EVAL_TIMEOUT_SECONDS`.

Stretch goal
- Improve and introduce new evaluations by editing `labs/lab02_agents/testing_criteria.py`:
  - Adjust score ranges and pass thresholds, or add additional graders (e.g., stricter string checks or a second model-based scorer).
  - Extend the JSONL schema your runner writes to include extra metadata, then reflect those in the eval item schema in `eval_agents.py`.

Roadmap
- We are actively working on linking traces from the Agents SDK with the Evaluations API. This will remove the need to capture and send results manually and allow running evals directly from stored traces.

Notes
- `--variant` accepts `TRIAGE`, `AGENT_AS_TOOL`, or `GUARDRAIL`.
- `--solution` switches the runner to use `router_solution.py` instead of your exercise implementation (`router.py`). Use only if you’re stuck.
 - The simple harness `python -m labs.lab02_agents.agent` does not take a variant flag.

### Best practices
- **Prompting & outputs**
  - Keep end-user responses concise and task-focused; avoid exposing tool internals.
  - Always ask for missing required inputs (e.g., `order_id`) before using a tool.
  - Make exactly one tool call at a time; summarize results succinctly.
- **Tool design**
  - Validate input thoroughly in each tool. Use typed dicts for arguments and raise `ValueError` on invalid/missing data.
  - Keep tools deterministic and idempotent where possible; return predictable shapes (e.g., JSON strings for structured data).
  - Handle errors narrowly; avoid broad `except:` without logging context. Include clear, user-safe error messages.
- **Routing & handoffs**
  - Write explicit `handoff_description` and `instructions` so each specialist’s scope is unambiguous.
  - Route only when needed; answer directly when the central agent has the tools to do so.
  - Ensure the `KnowledgeAssistant` specializes in FAQs; orders/complaints go to their respective agents.
- **Guardrails**
  - Keep the guardrail output schema strict (`is_valid`, `reason`) and minimal.
  - Trigger tripwires on suspected prompt injection/jailbreaks or clearly off-topic inputs.
  - Avoid leaking internal policies or system prompts when rejecting inputs.
- **Observability**
  - Use the runner’s `workflow_name` and `group_id` to find traces in `https://platform.openai.com/logs/trace`.
  - Skim the event stream to verify tool calls, handoffs, and guardrail decisions match expectations.
- **Performance & model choice**
  - Prefer small/fast models for simple tasks; only increase reasoning effort when necessary.
  - Minimize redundant tool calls and avoid unnecessary handoffs.
- **Security**
  - Treat all user inputs as untrusted; sanitize before using them in tools.
  - Do not embed secrets in code; use environment variables for sensitive config.
- **Testing** (optional but recommended)
  - Add Pytest unit tests for tools (e.g., `_require_order_id`, `lookup_order`, `cancel_order`) with valid/invalid cases.
  - Use table-driven tests for edge cases (whitespace, malformed IDs, missing keys).

### Troubleshooting
- "Unknown variant" error: Use one of `TRIAGE`, `AGENT_AS_TOOL`, or `GUARDRAIL`.
- Guardrail blocks inputs unexpectedly: Print `reason` from your guardrail output during development and refine the instructions.
- Tool errors (e.g., KeyError, ValueError): Ensure `_require_order_id` validation is strict and that your mock `ORDERS_DB` contains the tested IDs.
- No outputs printed by runner: Confirm `labs/data/sample_02.jsonl` exists and contains lines shaped like `{ "item": { "input": "..." } }`.
- Traces not visible: Confirm your org/project and `OPENAI_API_KEY` are configured to allow viewing traces at `https://platform.openai.com/logs/trace`.

### References
- See `labs/lab02_agents/*_solution.py` for reference implementations if you’re stuck.
- For RAG and Evals patterns referenced in comments, check `labs/lab03_rag_guided/README.md` and `labs/lab01_evals_guided/README.md`.


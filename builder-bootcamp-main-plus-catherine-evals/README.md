# Builder Bootcamp

Advanced, hands-on training for enterprise builders to scope, design, and deploy AI solutions. Focus areas: agents, RAG, and evals — with practical, production-oriented patterns.

## Clone the repository

```bash
git clone https://github.com/openai-customer-education/builder-bootcamp.git
cd builder-bootcamp
```

## What this repo contains
- `labs/` — per-lab folders (agents, rag, evals)
- `shared/` — common datasets and utilities reused across labs
- `CONTRIBUTING.md` — SME workflow and lab authoring checklist

## Labs overview
- **Evals**: Build a practical evaluation harness that combines model-based scoring and deterministic checks to grade datasets.
- **Agents**: Implement robust tools, a baseline agent, routing/handoffs between agents, and input guardrails.
- **RAG**: Create a vector-store-backed retrieval pipeline and generate grounded answers; evaluate end-to-end quality.
- **Fine-tuning**: Distill a baseline classifier into a smaller model—generate baseline completions, fine-tune, and evaluate accuracy with Evals.

Contributions welcome — see `CONTRIBUTING.md`.

## Prerequisites
- Python 3.10+ (3.12 preferred)
- Dependencies: run the install script below or see each lab’s `README.md` for manual commands.
- API key: set `OPENAI_API_KEY` in your environment for API-backed steps.
- Project + Organization IDs: set `OPENAI_PROJECT_ID` and `OPENAI_ORGANIZATION_ID` in your environment to ensure the correct OpenAI project + organization is used
  - Note that some stateful services (such as file storage) will be used for this bootcamp, and so Zero-Data-Retention (ZDR) projects are not compatible with these labs

> **Tip:** For the easiest reading, open this README and all lab instructions in **Markdown Preview** mode in your IDE (e.g., VSCode, Cursor, etc.). This keeps tables, code, and formatting clear and makes the material easier to scan. Some environments may need a markdown extension for proper display.

---

## Quick Setup

Quick start (recommended): run the OS-specific setup script from the repo root to create a venv and install dependencies.

> Disclaimer: The setup scripts will install developer tooling if missing (e.g., Homebrew on macOS), install packages via Homebrew (such as `pyenv`, `python@3.12`, `jq`), and create a project-local virtual environment (`.venv`). These operations modify your Homebrew installation and may download binaries. If you prefer full control over your environment, skip the scripts and follow the manual steps below to create/activate a venv and install dependencies.

macOS:
```bash
source scripts/mac/setup.sh
```

Windows (PowerShell):
```powershell
. scripts/windows/setup.ps1
```

> Important: After running the automated or manual setup, you must export your OpenAI API key for this shell. See "Setup OpenAI API key" below.

## Manual Setup (if preferred)
Create and activate a virtual environment, install dependencies, and set your API key:

```bash
# From the repo root
python -m venv .venv # Or `uv venv`
source .venv/bin/activate
python -m pip install --upgrade pip # Or python -m ensurepip
pip install -r requirements.txt # Or `uv sync`
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
# From the repo root
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```
</details>

## Setup OpenAI API key

Required for all labs—do this even if you used the automated setup.

```bash
export OPENAI_API_KEY="sk-..."

# Optional: store it in a local .env file
echo "OPENAI_API_KEY=$OPENAI_API_KEY" > .env
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
# Set your OpenAI API key (temporary for this shell)
$env:OPENAI_API_KEY = "sk-..."

# Optional: store it in a local .env file
"OPENAI_API_KEY=$($env:OPENAI_API_KEY)" | Set-Content -Path .env -Encoding ASCII
```
</details>

---

Once set up, see the commands below in "How to run each lab".


## Recommended path through the labs
Follow this sequence to see how evaluations tie the whole journey together:

1) Evals (intro and foundation)
- Read `labs/lab01_evals_guided/README.md` for an overview of the Evals API and criterion shapes.
- Run the starter harness to grade a small JSONL dataset using model scorers and string checks.

2) Agents (tools → agent → routing → guardrails)
- Read `labs/lab02_agents_guided/README.md` (or `labs/lab02_agents_challenge/README.md`) and implement tools with strict validation and helpful errors.
- Build a baseline customer-support agent, then compose agents via handoffs and triage routing.
- Add input guardrails (security and topic) to protect the workflow.
- Evaluate agent answers and tool usage with the provided evaluator.

3) RAG (retrieval + grounded generation)
- Read `labs/lab03_rag_guided/README.md` and build a vector-store-backed File Search pipeline.
- Generate answers grounded in retrieved content and evaluate alignment with expected answers.

4) Back to Agents (integrate RAG)
- Return to `labs/lab02_agents/router.py` and swap the static FAQ tool for File Search (from the RAG lab) in the `KnowledgeAssistant`.
- Re-run the triage/handoff flows with RAG in the agent network.

5) Extension Exercises (Optional)
- If you finish all of the above and have some spare time, consider some of the open-ended extension exercises found in `EXTENSIONS_README.md`

Note: Every lab includes an evaluation step. Treat evals as the connective tissue that verifies quality at each stage.

## What you will learn
- **Evaluation design**: Define scoring rubrics with model-based graders and deterministic checks, and interpret pass/total.
- **Data discipline**: Use JSONL with a consistent `{"item": {...}}` shape for prompts and graders across labs.
- **Tooling fundamentals**: Validate inputs, raise precise errors, and keep outputs concise and deterministic.
- **Agent prompting patterns**: Ask for missing info, call one tool at a time, and summarize results clearly.
- **Agent composition**: Route between specialists and perform handoffs with explicit scopes and instructions.
- **Guardrails and safety**: Detect unsafe/off-topic inputs and trigger tripwires with minimal, structured outputs.
- **Retrieval and grounding (RAG)**: Build vector stores, retrieve high-signal context, and generate grounded answers.
- **Observability**: Use runners and dashboards to trace decisions, tool calls, and rubric outcomes.

## How to run each lab (quick commands)
From the repository root:

Evals (intro):
```bash
python -m labs.lab01_evals_guided.run
```

Agents (dataset-driven runner):
```bash
python -m labs.lab02_agents_guided.run --variant TRIAGE
# other variants
python -m labs.lab02_agents_guided.run --variant AGENT_AS_TOOL
python -m labs.lab02_agents_guided.run --variant GUARDRAIL
```

RAG (step-by-step):
```bash
python -m labs.lab03_rag_guided.step_01_process_faq
python -m labs.lab03_rag_guided.step_02_create_vector_store
python -m labs.lab03_rag_guided.step_03_run_questions
python -m labs.lab03_rag_guided.step_04_eval_results
```

## Data and shared assets
- `shared/` contains common datasets/utilities reused across labs.
- `labs/data/` contains example inputs/outputs referenced by each lab.

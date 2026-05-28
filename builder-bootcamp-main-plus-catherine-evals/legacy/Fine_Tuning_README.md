# Builder Bootcamp: Wine Distillation Lab — Distill a larger model into a smaller one

### Lab metadata

- **Lab type**: Guided, hands‑on
- **Duration**: ~45–60 minutes
- **Level**: Advanced builders
- **Environment**: macOS/Linux/Windows terminal, Python 3.10+
- **Repo path**: `labs/lab04_finetuning_guided`
- **Last updated:** October 2, 2025

### Overview
In this lab, you will distill a larger model into a smaller one for a classification task. You will:
- **Evaluate baselines** on a wine‑variety classification dataset
- **Generate teacher completions** using a larger model
- **Start a distillation fine‑tune** targeting a smaller model
- **Evaluate the distilled model** and compare against baselines

### Learning objectives
By the end of this lab you will be able to:
1. Run a baseline evaluation and parse structured model outputs reliably.
2. Produce a teacher‑labeled JSONL dataset suitable for fine‑tuning.
3. Start and monitor a distillation fine‑tuning job.
4. Evaluate a distilled model with a consistent harness and interpret accuracy.

### Prerequisites
- **Python**: 3.10+
- **Dependencies**: `pip install -r requirements.txt`
- **API key**: `export OPENAI_API_KEY=sk-...`

> <details>
> <summary>Windows (PowerShell)</summary>
> ```powershell
> pip install -r requirements.txt
> $env:OPENAI_API_KEY = "sk-..."
> ```
> </details>

### Explore lab files

| File | Purpose | Output/Notes |
| --- | --- | --- |
| `step_00_prepare_data.py` | Download and prepare a France‑subset of Wine Reviews. | Writes `labs/data/wine_france_subset.csv`, `labs/data/varieties.json`. |
| `step_01_baseline_eval.py` | Evaluate 3 base models; you implement JSON parsing. | Writes per‑model JSONL completions; prints pass/total. |
| `step_02_store_completions.py` | Upload teacher JSONL and start a distillation job. | Prints uploaded file id, job id, distilled model name. |
| `step_03_eval_distilled.py` | Evaluate the distilled model vs. gold labels. | Prints pass/total and accuracy; creates an eval run. |
| `testing_criteria.py` | Grading criteria reused across steps. | Exact‑match string check for accuracy. |

### Dataset
- Kaggle Wine Reviews (`zynicide/wine-reviews`) filtered to France; rare varieties pruned.

### How to run
0) Data prep
   python -m labs.lab04_finetuning_guided.step_00_prepare_data

1) Baseline evaluation (out‑of‑the‑box models)
   python -m labs.lab04_finetuning_guided.step_01_baseline_eval

2) Generate teacher completions and start/poll distillation job (nano from gpt‑4.1)
   python -m labs.lab04_finetuning_guided.step_02_store_completions
   # Uploads JSONL, starts the job, and polls until completion.

   Notes:
   - When the job succeeds, the script prints the distilled model name and a helper to export it:
       export DISTILLED_MODEL="your-distilled-model-name"
   - Then proceed to Step 3 to evaluate.

   <details>
   <summary>Windows (PowerShell)</summary>
   ```powershell
   $env:DISTILLED_MODEL = "your-distilled-model-name"
   ```
   </details>

3) Evaluate the distilled model
   - Copy-paste your fine tuned model name in `step_03_eval_distilled`.
   python -m labs.lab04_finetuning_guided.step_03_eval_distilled

### Checkpoints and expected outputs
- **Step 0**: Files exist
  - `labs/data/wine_france_subset.csv`
  - `labs/data/varieties.json`
- **Step 1**: Console shows per‑model accuracy (teacher/student/nano). JSONL files written to `labs/data/`.
- **Step 2**: Console prints uploaded file id, fine‑tune job id, and on success a line to export `DISTILLED_MODEL`.
- **Step 3**: Console prints `Distilled: <passed>/<total> = <acc>`; eval run visible in the Evaluations dashboard.

### Notes
- Steps include small TODOs (API calls or prompt tweaks). You can rerun any step; outputs are timestamped.

### Conclusion and reflection
- You distilled a larger model into a smaller one, evaluated both, and compared accuracy.
- Reflect on:
  - Where structured prompts and robust JSON parsing mattered most
  - How label quality (teacher completions) affected distilled performance
  - What thresholds you’d require before productionizing the distilled model

# Run this script to end-to-end verify the project
# IMPORTANT - this will run all labs, which may take a while, and which will modify the active OpenAI project.
#!/usr/bin/env bash

# Verification script for builder-bootcamp
# Runs lab verification commands, logs output, and prints one summary line per lab.

set -u
set -o pipefail
IFS=$'\n\t'

LOG_FILE=""
PYTHON_BIN=""

CURRENT_LAB=""
CURRENT_LAB_STATUS="PASS"
declare -a CURRENT_LAB_WARNINGS=()
declare -a CURRENT_LAB_FAILURES=()

timestamp_full() {
  date +"%Y-%m-%d %H:%M:%S"
}

ensure_logging() {
  local log_dir="logs"
  mkdir -p "$log_dir"
  LOG_FILE="$log_dir/verify_$(date +"%Y-%m-%d_%H%M%S").log"
  : > "$LOG_FILE"
}

log() {
  local message="$1"
  printf "%s %s\n" "$(timestamp_full)" "$message" >> "$LOG_FILE"
}

ensure_project_root() {
  local script_dir project_root
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  project_root="$(cd "$script_dir/../.." && pwd)"
  if [[ "$PWD" != "$project_root" ]]; then
    if ! cd "$project_root" 2>/dev/null; then
      echo "verify.sh: unable to change to project root ($project_root)" >&2
      exit 1
    fi
  fi
  log "Project root: $project_root"
}

activate_venv() {
  local venv_python=".venv/bin/python"
  if [[ -x "$venv_python" ]]; then
    PYTHON_BIN="$venv_python"
    log "[ENV] Using virtual environment interpreter ($PYTHON_BIN)"
  else
    echo "verify.sh: virtual environment python not found at $venv_python" >&2
    exit 1
  fi
}

detect_python() {
  if [[ -n "${PYTHON_BIN:-}" ]]; then
    log "Using python interpreter: $PYTHON_BIN"
    return
  fi
  if command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  else
    echo "verify.sh: no python interpreter found on PATH" >&2
    exit 1
  fi
  log "Using python interpreter: $PYTHON_BIN"
}

reset_lab_state() {
  CURRENT_LAB_STATUS="PASS"
  CURRENT_LAB_WARNINGS=()
  CURRENT_LAB_FAILURES=()
}

init_lab() {
  CURRENT_LAB="$1"
  reset_lab_state
  log "--- Begin lab: $CURRENT_LAB ---"
}

add_warning() {
  local note="$1"
  CURRENT_LAB_WARNINGS+=("$note")
  if [[ "$CURRENT_LAB_STATUS" != "FAIL" ]]; then
    CURRENT_LAB_STATUS="WARN"
  fi
}

add_failure() {
  local note="$1"
  CURRENT_LAB_FAILURES+=("$note")
  CURRENT_LAB_STATUS="FAIL"
}

python_module_available() {
  local module="$1"
  "$PYTHON_BIN" -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('$module') else 1)" >/dev/null 2>&1
}

run_cmd() {
  local cmd="$1"
  shift || true
  local -a flags=()
  if [[ "$#" -gt 0 ]]; then
    flags=("$@")
  fi

  if [[ "${#flags[@]}" -gt 0 ]]; then
    for flag in "${flags[@]}"; do
    case "$flag" in
      requires_api)
        if [[ -z "${OPENAI_API_KEY:-}" ]]; then
          add_warning "OPENAI_API_KEY not set (skipped: $cmd)"
          log "[SKIP] $cmd (OPENAI_API_KEY missing)"
          return 0
        fi
        ;;
      requires_jq)
        if ! command -v jq >/dev/null 2>&1; then
          add_warning "jq not available (skipped: $cmd)"
          log "[SKIP] $cmd (jq missing)"
          return 0
        fi
        ;;
      requires_module:*)
        local module="${flag#requires_module:}"
        if ! python_module_available "$module"; then
          add_warning "Python module '$module' missing (skipped: $cmd)"
          log "[SKIP] $cmd (module $module missing)"
          return 0
        fi
        ;;
      requires_file:*)
        local required_path="${flag#requires_file:}"
        if [[ ! -f "$required_path" ]]; then
          add_warning "Required file '$required_path' missing (skipped: $cmd)"
          log "[SKIP] $cmd (file $required_path missing)"
          return 0
        fi
        ;;
    esac
    done
  fi

  log "[RUN] $cmd"
  if bash -lc "set -o pipefail; $cmd" >> "$LOG_FILE" 2>&1; then
    log "[OK] $cmd"
  else
    local status=$?
    add_failure "Command failed (exit $status): $cmd"
    log "[ERR] $cmd (exit $status)"
  fi
}

join_messages() {
  local array_name="$1[@]"
  local items=("${!array_name}")
  if [[ "${#items[@]}" -eq 0 ]]; then
    echo ""
  else
    local IFS="; "
    echo "${items[*]}"
  fi
}

finalize_lab() {
  local summary=""
  if [[ "$CURRENT_LAB_STATUS" == "FAIL" ]]; then
    summary=$(join_messages CURRENT_LAB_FAILURES)
  elif [[ "$CURRENT_LAB_STATUS" == "WARN" ]]; then
    summary=$(join_messages CURRENT_LAB_WARNINGS)
  fi

  if [[ -n "$summary" ]]; then
    echo "[$CURRENT_LAB_STATUS] $CURRENT_LAB - $summary"
  else
    echo "[$CURRENT_LAB_STATUS] $CURRENT_LAB"
  fi
  log "--- End lab: $CURRENT_LAB (status: $CURRENT_LAB_STATUS) ---"
}

lab01_evals_guided() {
  init_lab "lab01_evals_guided"
  run_cmd "$PYTHON_BIN -c \"import sys, openai; from openai import OpenAI; print('Python OK:', sys.version); print('OpenAI OK:', getattr(openai, '__version__', 'unknown')); print('Client OK:', bool(OpenAI))\""
  run_cmd "sed -n '1,3p' labs/data/sample_01.jsonl | jq" requires_jq
  run_cmd "$PYTHON_BIN -m labs.lab01_evals_guided.run" requires_api
  finalize_lab
}

lab02_agents_guided() {
  init_lab "lab02_agents_guided"
  run_cmd "$PYTHON_BIN -m labs.lab02_agents_guided.agent" requires_api
  run_cmd "$PYTHON_BIN -m labs.lab02_agents_guided.run --variant AGENT_AS_TOOL" requires_api
  run_cmd "$PYTHON_BIN -m labs.lab02_agents_guided.run --variant TRIAGE" requires_api
  run_cmd "$PYTHON_BIN -m labs.lab02_agents_guided.run --variant GUARDRAIL" requires_api
  run_cmd "sed -n '16p' labs/data/agent_model_answer.jsonl | jq '.item'" requires_jq requires_file:labs/data/agent_model_answer.jsonl
  run_cmd "$PYTHON_BIN -m labs.lab02_agents_guided.eval_agents" requires_api
  finalize_lab
}

lab03_rag_guided() {
  init_lab "lab03_rag_guided"
  run_cmd "$PYTHON_BIN -m labs.lab03_rag_guided.step_01_process_faq" requires_api
  run_cmd "$PYTHON_BIN -m labs.lab03_rag_guided.step_02_create_vector_store" requires_api
  run_cmd "$PYTHON_BIN -m labs.lab03_rag_guided.step_03_run_questions" requires_api
  run_cmd "sed -n '1p' labs/data/rag_model_answer.jsonl | jq '.item'" requires_jq requires_file:labs/data/rag_model_answer.jsonl
  run_cmd "$PYTHON_BIN -m labs.lab03_rag_guided.step_04_eval_results" requires_api
  finalize_lab
}

lab04_finetuning_guided() {
  init_lab "lab04_finetuning_guided"
  run_cmd "$PYTHON_BIN -m labs.lab04_finetuning_guided.step_00_prepare_data" requires_module:kagglehub requires_module:pandas
  run_cmd "$PYTHON_BIN -m labs.lab04_finetuning_guided.step_01_baseline_eval" requires_api requires_module:pandas
  run_cmd "$PYTHON_BIN -m labs.lab04_finetuning_guided.step_02_store_completions" requires_api requires_module:pandas
  run_cmd "$PYTHON_BIN -m labs.lab04_finetuning_guided.step_03_eval_distilled" requires_api requires_module:pandas
  finalize_lab
}


main() {
  ensure_logging
  ensure_project_root
  detect_python
  activate_venv

  lab01_evals_guided
  lab02_agents_guided
  lab03_rag_guided
  lab04_finetuning_guided
}

main "$@"

#!/usr/bin/env bash

# Setup script for builder-bootcamp (macOS)
# - Ensures execution from repo root
# - Verifies required directories
# - Ensures Homebrew, pyenv, uv
# - Creates venv and installs dependencies with uv

# -----------------------------
# Utilities
# -----------------------------
timestamp_date() {
  date +"%Y-%m-%d"
}

timestamp_full() {
  date +"%Y-%m-%d %H:%M:%S"
}

ensure_logging() {
  LOG_DIR="logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/setup_$(timestamp_full).log"
  # Touch to ensure file exists
  : > /dev/null >> "$LOG_FILE"
}

log_line() {
  # Writes to stdout and to log file
  # Usage: log_line "[✅] message"
  local line="$1"
  echo "$line"
  echo "$(timestamp_full) $line" >> "$LOG_FILE"
}

status_ok() { log_line "[✅] $1"; }
status_warn() { log_line "[⚠️] $1"; }
status_err() { log_line "[❌] $1"; }

# Log a command string and run it, capturing stdout/stderr to the log file only
log_cmd() {
  echo "$(timestamp_full) [CMD] $1" >> "$LOG_FILE"
}

run_and_log() {
  local cmd="$1"
  log_cmd "$cmd"
  eval "$cmd" >> "$LOG_FILE" 2>&1
  return $?
}

# Sourced-aware exit helpers
is_sourced() {
  [ "${BASH_SOURCE[0]}" != "$0" ]
}

exit_script() {
  local code="${1:-0}"
  if is_sourced; then
    return "$code"
  else
    exit "$code"
  fi
}

# -----------------------------
# Kickoff
# -----------------------------
ensure_logging
log_line "Starting setup..."

# -----------------------------
# 0. Ensure execution from repository root (builder-bootcamp)
# -----------------------------
# Resolve project root relative to this script (scripts/mac/ -> ../..)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CURRENT_DIR="$PWD"

if [ "$CURRENT_DIR" != "$PROJECT_ROOT" ]; then
  cd "$PROJECT_ROOT" 2>/dev/null
  if [ "$PWD" = "$PROJECT_ROOT" ]; then
    status_ok "Step 1: Ensured running from project root: $PROJECT_ROOT"
    status_warn "Was invoked from '$CURRENT_DIR'; changed directory to '$PROJECT_ROOT'"
  else
    status_err "Step 1: Failed to change to project root: $PROJECT_ROOT"
    exit_script 1 || return
  fi
else
  status_ok "Step 1: Already at project root: $PROJECT_ROOT"
fi

# -----------------------------
# 0a. Verify required directories
# -----------------------------
if [ -d "labs" ] && [ -d "scripts" ]; then
  # Check that labs contains 1+ subdirectories starting with lab...
  LAB_COUNT=$(find labs -maxdepth 1 -type d -name 'lab*' | wc -l | tr -d ' ')
  if [ "$LAB_COUNT" -ge 1 ]; then
    status_ok "Step 2: Verified 'labs/' and 'scripts/' exist and labs contains $LAB_COUNT lab* directories"
  else
    status_err "Step 2: 'labs/' exists but contains no 'lab*' directories"
    exit_script 1 || return
  fi
else
  status_err "Step 2: Required directories missing. Expecting 'labs/' and 'scripts/' at repo root"
  exit_script 1 || return
fi

# Helper: ensure Homebrew is available in PATH after install
brew_shellenv_if_present() {
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$('/opt/homebrew/bin/brew' shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$('/usr/local/bin/brew' shellenv)"
  fi
}

# -----------------------------
# 1. Check Homebrew; install if missing; update
# -----------------------------
if command -v brew >/dev/null 2>&1; then
  status_ok "Step 3: Homebrew detected: $(command -v brew)"
else
  status_warn "Step 3: Homebrew not found; installing..."
  CMD_HB='NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  log_cmd "$CMD_HB"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1
  if [ "$?" -ne 0 ]; then
    status_err "Step 3: Homebrew installation failed"
    exit_script 1 || return
  fi
  brew_shellenv_if_present
  if command -v brew >/dev/null 2>&1; then
    status_ok "Step 3: Homebrew installed successfully"
  else
    status_err "Step 3: Homebrew installed but not found in PATH"
    exit_script 1 || return
  fi
fi

# Ensure brew is initialized in this shell
brew_shellenv_if_present

if run_and_log "brew update"; then
  status_ok "Step 3: Homebrew updated"
else
  status_warn "Step 3: Homebrew update encountered issues; continuing"
fi

# Ensure jq via Homebrew
if command -v jq >/dev/null 2>&1; then
  status_ok "Step 4: jq detected: $(command -v jq)"
else
  if brew list --formula | grep -qx jq; then
    status_ok "Step 4: jq already installed via Homebrew"
  else
    status_warn "Step 4: Installing jq via Homebrew..."
    if run_and_log "brew install jq"; then
      status_ok "Step 4: jq installed"
    else
      status_err "Step 4: jq installation failed"
      exit_script 1 || return
    fi
  fi
fi

# -----------------------------
# 2. Ensure pyenv via brew (with fallback plan)
# -----------------------------
PYENV_AVAILABLE=0
if command -v pyenv >/dev/null 2>&1; then
  status_ok "Step 5: pyenv detected: $(command -v pyenv)"
  PYENV_AVAILABLE=1
else
  if brew list --formula | grep -qx pyenv; then
    status_ok "Step 5: pyenv already installed via brew"
    PYENV_AVAILABLE=1
  else
    status_warn "Step 5: Installing pyenv via Homebrew..."
    if run_and_log "brew install pyenv"; then
      status_ok "Step 5: pyenv installed"
      PYENV_AVAILABLE=1
    else
      status_warn "Step 5: pyenv installation failed; will use Homebrew Python fallback"
      PYENV_AVAILABLE=0
    fi
  fi
fi

# Initialize pyenv for this shell if present
if [ "$PYENV_AVAILABLE" -eq 1 ] && command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)" 2>/dev/null || true
fi

# -----------------------------
# 3. Ensure Python 3.12 (pyenv preferred, Homebrew fallback)
# -----------------------------
PYTHON_SOURCE="unknown"
BREW_PY_PREFIX=""
BREW_PY_BIN=""

ensure_brew_python_312() {
  if brew list --formula | grep -qx "python@3.12"; then
    status_ok "Step 6: python@3.12 already installed via Homebrew"
  else
    status_warn "Step 6: Installing python@3.12 via Homebrew..."
    if run_and_log "brew install python@3.12"; then
      status_ok "Step 6: Installed python@3.12 via Homebrew"
    else
      status_err "Step 6: Failed to install python@3.12 via Homebrew"
      exit_script 1 || return
    fi
  fi
  BREW_PY_PREFIX="$(brew --prefix python@3.12)"
  BREW_PY_BIN="$BREW_PY_PREFIX/bin/python3.12"
  if [ ! -x "$BREW_PY_BIN" ]; then
    status_err "Step 6: Expected python binary not found at $BREW_PY_BIN"
    exit_script 1 || return
  fi
  status_ok "Step 6a: Homebrew Python resolved at $BREW_PY_BIN"
}

if [ "$PYENV_AVAILABLE" -eq 1 ]; then
  if pyenv versions --bare | grep -Eq '^3\.12(\.|$)'; then
    status_ok "Step 6: Python 3.12 already installed in pyenv"
    PYTHON_SOURCE="pyenv"
  else
    if run_and_log "pyenv install -s 3.12"; then
      status_ok "Step 6: Installed Python 3.12 via pyenv"
      PYTHON_SOURCE="pyenv"
    else
      status_warn "Step 6: Failed to install Python 3.12 with pyenv; falling back to Homebrew"
      PYTHON_SOURCE="brew"
      ensure_brew_python_312
    fi
  fi
  if [ "$PYTHON_SOURCE" = "pyenv" ]; then
    if run_and_log "pyenv local 3.12"; then
      status_ok "Step 6a: Set local Python version to 3.12 (.python-version)"
    else
      status_warn "Step 6a: Failed to set local Python version to 3.12; will use Homebrew fallback"
      PYTHON_SOURCE="brew"
      ensure_brew_python_312
    fi
  fi
else
  status_warn "Step 6: pyenv not available; using Homebrew Python fallback"
  PYTHON_SOURCE="brew"
  ensure_brew_python_312
fi

# -----------------------------
# 4. Ensure uv is installed
# -----------------------------
ensure_uv_in_path() {
  # Common install locations
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
}

# Fallback: create venv with python and install requirements with pip or 'uv run pip'
FALLBACK_VENV_DONE=0
fallback_setup_with_python_venv() {
  status_warn "Step 7: Attempting fallback: python -m venv and pip install"
  local py_bin="python3"
  if ! command -v "$py_bin" >/dev/null 2>&1; then
    py_bin="python"
  fi

  if command -v "$py_bin" >/dev/null 2>&1; then
    if run_and_log "$py_bin -m venv .venv"; then
      status_ok "Step 8: Created virtual environment with python -m venv"
      if [ -f ".venv/bin/activate" ]; then
        # shellcheck source=/dev/null
        log_cmd "source .venv/bin/activate"
        . .venv/bin/activate
        status_ok "Step 8a: Activated virtual environment (fallback)"
      else
        status_err "Step 8: Fallback venv activation script missing"
        return
      fi

      if command -v uv >/dev/null 2>&1; then
        if run_and_log "uv run pip install -r requirements.txt"; then
          status_ok "Step 8b: Installed dependencies via 'uv run pip' (fallback)"
          FALLBACK_VENV_DONE=1
        else
          status_err "Step 8b: 'uv run pip install -r requirements.txt' failed (fallback)"
        fi
      else
        if [ -f requirements.txt ]; then
          if run_and_log "$py_bin -m pip install -r requirements.txt"; then
            status_ok "Step 8b: Installed dependencies via pip (fallback)"
            FALLBACK_VENV_DONE=1
          else
            status_err "Step 8b: 'pip install -r requirements.txt' failed (fallback)"
          fi
        else
          status_warn "Step 8b: requirements.txt not found; skipping dependency install (fallback)"
          FALLBACK_VENV_DONE=1
        fi
      fi
    else
      status_err "Step 8: Failed to create virtual environment with python -m venv (fallback)"
    fi
  else
    status_err "Step 8: No python interpreter found for fallback"
  fi
}

if command -v uv >/dev/null 2>&1; then
  status_ok "Step 7: uv detected: $(command -v uv)"
else
  status_warn "Step 7: uv not found; installing..."
  if command -v curl >/dev/null 2>&1; then
    if run_and_log "curl -LsSf https://astral.sh/uv/install.sh | sh"; then
      ensure_uv_in_path
      if command -v uv >/dev/null 2>&1; then
        status_ok "Step 7: uv installed via curl"
      else
        status_warn "Step 7: uv installed but not yet on PATH in this shell; added common paths"
      fi
    else
      status_err "Step 7: uv installation via curl failed"
      fallback_setup_with_python_venv
    fi
  elif command -v wget >/dev/null 2>&1; then
    if run_and_log "wget -qO- https://astral.sh/uv/install.sh | sh"; then
      ensure_uv_in_path
      if command -v uv >/dev/null 2>&1; then
        status_ok "Step 7: uv installed via wget"
      else
        status_warn "Step 7: uv installed but not yet on PATH in this shell; added common paths"
      fi
    else
      status_err "Step 7: uv installation via wget failed"
      fallback_setup_with_python_venv
    fi
  else
    status_err "Step 7: Neither curl nor wget available to install uv"
    fallback_setup_with_python_venv
  fi
fi

# -----------------------------
# 5. Create virtual environment and install dependencies
# -----------------------------
UV_OK=1
if [ "${FALLBACK_VENV_DONE:-0}" -eq 1 ]; then
  status_ok "Step 8: Skipping venv creation; fallback venv is ready and dependencies installed"
else
  if [ "$PYTHON_SOURCE" = "pyenv" ]; then
    if command -v uv >/dev/null 2>&1; then
      if run_and_log "uv venv"; then
        status_ok "Step 8: Created virtual environment with uv (.venv)"
      else
        status_err "Step 8: Failed to create virtual environment with uv"
        UV_OK=0
      fi
    else
      status_warn "Step 8: uv not available; attempting python -m venv"
      fallback_setup_with_python_venv
      UV_OK=${FALLBACK_VENV_DONE}
    fi
  else
    # Homebrew Python fallback: create venv with explicit Python 3.12 without altering system PATH
    if run_and_log "$BREW_PY_BIN -m venv .venv"; then
      status_ok "Step 8: Created virtual environment with Homebrew Python 3.12"
    else
      status_err "Step 8: Failed to create virtual environment with Homebrew Python"
      UV_OK=0
    fi
  fi

  if [ "$UV_OK" -eq 1 ] && [ -f ".venv/bin/activate" ]; then
    # shellcheck source=/dev/null
    log_cmd "source .venv/bin/activate"
    . .venv/bin/activate
    status_ok "Step 8a: Activated virtual environment"
  else
    if [ "$UV_OK" -eq 1 ]; then
      status_err "Step 8a: Virtual environment activation failed"
      UV_OK=0
    fi
  fi

  if [ "$UV_OK" -eq 1 ]; then
    if command -v uv >/dev/null 2>&1; then
      if run_and_log "uv sync"; then
        status_ok "Step 8b: Synced dependencies with uv"
      else
        status_warn "Step 8b: Dependency sync with uv failed; trying pip -r requirements.txt"
        if [ -f requirements.txt ] && run_and_log "python -m pip install -r requirements.txt"; then
          status_ok "Step 8b: Installed dependencies via pip"
        else
          status_err "Step 8b: Dependency installation failed"
          UV_OK=0
        fi
      fi
    else
      if [ -f requirements.txt ] && run_and_log "python -m pip install -r requirements.txt"; then
        status_ok "Step 8b: Installed dependencies via pip"
      else
        status_err "Step 8b: Dependency installation failed (pip)"
        UV_OK=0
      fi
    fi
  fi
fi

if [ "$UV_OK" -eq 1 ]; then
  status_ok "Setup completed successfully"
else
  status_warn "Setup completed with some issues. See $LOG_FILE for details"
fi

exit_script 0

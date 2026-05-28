Param()

# Verification script for builder-bootcamp (Windows PowerShell 5.1 + PowerShell 7)
# Mirrors mac verify script behavior with Windows-native commands and logging.

# Use a strict mode compatible with PS5 without tripping on newer quirks
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# Globals
$Global:LogFile = ""
$Global:PythonBin = ""

$Global:CurrentLab       = ""
$Global:CurrentLabStatus = "PASS"
$Global:CurrentLabWarnings = @()
$Global:CurrentLabFailures = @()

function Get-Timestamp {
  Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

function Ensure-Logging {
  $logDir = Join-Path -Path (Get-Location) -ChildPath 'logs'
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  $Global:LogFile = Join-Path -Path $logDir -ChildPath ("verify_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss'))
  New-Item -ItemType File -Path $Global:LogFile -Force | Out-Null
  Add-Content -Path $Global:LogFile -Value ("{0} Log file initialized" -f (Get-Timestamp)) -Encoding utf8
}

function Log {
  param([Parameter(Mandatory)] [string] $Message)
  Add-Content -Path $Global:LogFile -Value ("{0} {1}" -f (Get-Timestamp), $Message) -Encoding utf8
}

function Get-ScriptDirectory {
  # Robust across PS5/PS7, console, ISE, and scheduled runs
  if ($PSScriptRoot -and $PSScriptRoot.Trim()) { return $PSScriptRoot }

  if ($PSCommandPath -and $PSCommandPath.Trim()) {
    return (Split-Path -Parent $PSCommandPath)
  }

  if ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    return (Split-Path -Parent $MyInvocation.MyCommand.Path)
  }

  # Fallback: current directory (least preferred but avoids empty-path errors)
  return (Get-Location).Path
}

function Ensure-ProjectRoot {
  $scriptDir = Get-ScriptDirectory
  if (-not $scriptDir -or -not $scriptDir.Trim()) {
    Write-Error "verify.ps1: could not determine script directory."
    exit 1
  }

  # Project root is two levels up from /scripts/windows/
  $candidate = Join-Path -Path $scriptDir -ChildPath '..\..'
  try {
    $projectRoot = (Resolve-Path -Path $candidate).Path
  } catch {
    Write-Error "verify.ps1: unable to resolve project root from '$candidate'"
    exit 1
  }

  # Move to project root if not already there
  $here = (Get-Location).Path
  if ($here -ne $projectRoot) {
    try {
      Set-Location -Path $projectRoot
    } catch {
      Write-Error "verify.ps1: unable to change to project root ($projectRoot)"
      exit 1
    }
  }
  Log ("Project root: {0}" -f $projectRoot)
}

function Activate-Venv {
  $venvPython = Join-Path (Get-Location) '.venv\Scripts\python.exe'
  if (Test-Path $venvPython) {
    $Global:PythonBin = $venvPython
    Log ("[ENV] Using virtual environment interpreter ({0})" -f $Global:PythonBin)
  } else {
    Write-Error "verify.ps1: virtual environment python not found at $venvPython"
    exit 1
  }
}

function Detect-Python {
  if ($Global:PythonBin -and $Global:PythonBin.Trim() -ne '') {
    Log ("Using python interpreter: {0}" -f $Global:PythonBin)
    return
  }
  if (Get-Command python -ErrorAction SilentlyContinue) {
    $Global:PythonBin = 'python'
  } elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $Global:PythonBin = 'python3'
  } else {
    Write-Error 'verify.ps1: no python interpreter found on PATH'
    exit 1
  }
  Log ("Using python interpreter: {0}" -f $Global:PythonBin)
}

function Reset-LabState {
  $Global:CurrentLabStatus = 'PASS'
  $Global:CurrentLabWarnings = @()
  $Global:CurrentLabFailures = @()
}

function Init-Lab {
  param([Parameter(Mandatory)] [string] $Name)
  $Global:CurrentLab = $Name
  Reset-LabState
  Log ("--- Begin lab: {0} ---" -f $Global:CurrentLab)
}

function Add-Warning {
  param([Parameter(Mandatory)] [string] $Note)
  $Global:CurrentLabWarnings += $Note
  if ($Global:CurrentLabStatus -ne 'FAIL') { $Global:CurrentLabStatus = 'WARN' }
}

function Add-Failure {
  param([Parameter(Mandatory)] [string] $Note)
  $Global:CurrentLabFailures += $Note
  $Global:CurrentLabStatus = 'FAIL'
}

function Python-Module-Available {
  param([Parameter(Mandatory)] [string] $Module)
  & $Global:PythonBin -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('$Module') else 1)" 1>$null 2>&1
  return ($LASTEXITCODE -eq 0)
}

# Cross-version safe native command invoker
function Invoke-LoggedCommand {
  param([Parameter(Mandatory)] [string] $Cmd)

  Log ("[RUN] {0}" -f $Cmd)

  # Save current settings
  $oldEAP = $ErrorActionPreference
  $hasNCA = $false
  $oldNCA = $null
  $isPS7Plus = $false
  try {
    $isPS7Plus = ($PSVersionTable.PSVersion.Major -ge 7)
  } catch {}

  if ($isPS7Plus) {
    # Only exists on PS7+
    $hasNCA = Test-Path variable:PSNativeCommandUseErrorActionPreference
    if ($hasNCA) { $oldNCA = $PSNativeCommandUseErrorActionPreference }
  }

  try {
    $ErrorActionPreference = 'Continue'
    if ($isPS7Plus -and $hasNCA) { $PSNativeCommandUseErrorActionPreference = $true }

    # Use cmd.exe to avoid PowerShell parsing semicolons in Python -c payloads
    & cmd /c "$Cmd 2>&1" | Tee-Object -FilePath $Global:LogFile -Append | Out-Null

    $code = $LASTEXITCODE
    if ($code -eq 0) {
      Log ("[OK] {0}" -f $Cmd)
      return $true
    } else {
      Add-Failure ("Command failed (exit {0}): {1}" -f $code, $Cmd)
      Log ("[ERR] {0} (exit {1})" -f $Cmd, $code)
      return $false
    }
  }
  finally {
    $ErrorActionPreference = $oldEAP
    if ($isPS7Plus -and $hasNCA) { $PSNativeCommandUseErrorActionPreference = $oldNCA }
  }
}

function Run-Cmd {
  param(
    [Parameter(Mandatory)] [string] $Cmd,
    [string[]] $Flags
  )

  if ($Flags -and $Flags.Length -gt 0) {
    foreach ($flag in $Flags) {
      switch -Wildcard ($flag) {
        'requires_api' {
          if (-not $env:OPENAI_API_KEY) {
            Add-Warning ("OPENAI_API_KEY not set (skipped: {0})" -f $Cmd)
            Log ("[SKIP] {0} (OPENAI_API_KEY missing)" -f $Cmd)
            return
          }
        }
        'requires_jq' {
          if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
            Add-Warning ("jq not available (skipped: {0})" -f $Cmd)
            Log ("[SKIP] {0} (jq missing)" -f $Cmd)
            return
          }
        }
        'requires_module:*' {
          $module = $flag.Split(':',2)[1]
          if (-not (Python-Module-Available -Module $module)) {
            Add-Warning ("Python module '{0}' missing (skipped: {1})" -f $module, $Cmd)
            Log ("[SKIP] {0} (module {1} missing)" -f $Cmd, $module)
            return
          }
        }
        'requires_file:*' {
          $required = $flag.Split(':',2)[1]
          if (-not (Test-Path $required -PathType Leaf)) {
            Add-Warning ("Required file '{0}' missing (skipped: {1})" -f $required, $Cmd)
            Log ("[SKIP] {0} (file {1} missing)" -f $Cmd, $required)
            return
          }
        }
      }
    }
  }

  Invoke-LoggedCommand -Cmd $Cmd | Out-Null
}

function Join-Messages {
  param([object[]] $Items)
  if (-not $Items -or $Items.Count -eq 0) { return "" }
  return ($Items -join '; ')
}

function Finalize-Lab {
  $summary = ""
  if ($Global:CurrentLabStatus -eq 'FAIL') {
    $summary = Join-Messages -Items $Global:CurrentLabFailures
  } elseif ($Global:CurrentLabStatus -eq 'WARN') {
    $summary = Join-Messages -Items $Global:CurrentLabWarnings
  }

  if ($summary) {
    Write-Output ("[{0}] {1} - {2}" -f $Global:CurrentLabStatus, $Global:CurrentLab, $summary)
  } else {
    Write-Output ("[{0}] {1}" -f $Global:CurrentLabStatus, $Global:CurrentLab)
  }
  Log ("--- End lab: {0} (status: {1}) ---" -f $Global:CurrentLab, $Global:CurrentLabStatus)
}

# -----------------------------
# Lab runners
# -----------------------------
function Lab01-Evals-Guided {
  Init-Lab -Name 'lab01_evals_guided'
  # Ensure the whole -c payload stays inside quotes for cmd.exe; single quotes escaped by doubling
  $pyCheck = $Global:PythonBin + ' -c "import sys, openai; from openai import OpenAI; print(''Python OK:'', sys.version); print(''OpenAI OK:'', getattr(openai, ''__version__'', ''unknown'')); print(''Client OK:'', bool(OpenAI))"'
  Run-Cmd -Cmd $pyCheck

  Run-Cmd -Cmd "Get-Content labs/data/sample_01.jsonl -TotalCount 3 | jq" -Flags @('requires_jq','requires_file:labs/data/sample_01.jsonl')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab01_evals_guided.run" -Flags @('requires_api')
  Finalize-Lab
}

function Lab02-Agents-Guided {
  Init-Lab -Name 'lab02_agents_guided'
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab02_agents_guided.agent" -Flags @('requires_api')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab02_agents_guided.run --variant AGENT_AS_TOOL" -Flags @('requires_api')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab02_agents_guided.run --variant TRIAGE" -Flags @('requires_api')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab02_agents_guided.run --variant GUARDRAIL" -Flags @('requires_api')
  Run-Cmd -Cmd "(Get-Content labs/data/agent_model_answer.jsonl | Select-Object -Index 15) | jq '.item'" -Flags @('requires_jq','requires_file:labs/data/agent_model_answer.jsonl')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab02_agents_guided.eval_agents" -Flags @('requires_api')
  Finalize-Lab
}

function Lab03-Rag-Guided {
  Init-Lab -Name 'lab03_rag_guided'
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab03_rag_guided.step_01_process_faq" -Flags @('requires_api')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab03_rag_guided.step_02_create_vector_store" -Flags @('requires_api')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab03_rag_guided.step_03_run_questions" -Flags @('requires_api')
  Run-Cmd -Cmd "(Get-Content labs/data/rag_model_answer.jsonl | Select-Object -Index 0) | jq '.item'" -Flags @('requires_jq','requires_file:labs/data/rag_model_answer.jsonl')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab03_rag_guided.step_04_eval_results" -Flags @('requires_api')
  Finalize-Lab
}

function Lab04-Finetuning-Guided {
  Init-Lab -Name 'lab04_finetuning_guided'
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab04_finetuning_guided.step_00_prepare_data" -Flags @('requires_module:kagglehub','requires_module:pandas')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab04_finetuning_guided.step_01_baseline_eval" -Flags @('requires_api','requires_module:pandas')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab04_finetuning_guided.step_02_store_completions" -Flags @('requires_api','requires_module:pandas')
  Run-Cmd -Cmd "$Global:PythonBin -m labs.lab04_finetuning_guided.step_03_eval_distilled" -Flags @('requires_api','requires_module:pandas')
  Finalize-Lab
}

function Main {
  Ensure-Logging
  Ensure-ProjectRoot
  Activate-Venv
  Detect-Python

  Lab01-Evals-Guided
  Lab02-Agents-Guided
  Lab03-Rag-Guided
  Lab04-Finetuning-Guided
}

Main

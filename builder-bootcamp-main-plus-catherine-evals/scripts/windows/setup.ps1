Param()

# Setup script for builder-bootcamp (Windows PowerShell)
# Steps mirror the macOS script with Windows-specific tooling:
# 1) Ensure running from repo root
# 2) Verify required directories
# 3) Ensure Windows package manager (winget/choco) is available and updated
# 4) Ensure pyenv-win
# 5) Install Python 3.12 and set local
# 6) Ensure uv
# 7) Create venv and install dependencies (uv) with fallback to python -m venv + pip

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Force UTF-8 for everything we write and everything we redirect
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Global:OutputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$PSDefaultParameterValues['*:Encoding'] = 'utf8'  # Add-Content/Set-Content/Out-File defaults

# -----------------------------
# Utilities
# -----------------------------
function Test-IsDotSourced {
  # True if this script was dot-sourced (". setup.ps1") so changes persist in caller scope
  try {
    if ($null -ne $MyInvocation.Line) {
      return $MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line.TrimStart().StartsWith('. ')
    }
    return $MyInvocation.InvocationName -eq '.'
  } catch {
    return $false
  }
}

function Exit-Script {
  param([int] $Code = 0)
  if (Test-IsDotSourced) {
    $global:LASTEXITCODE = $Code
    return
  } else {
    exit $Code
  }
}
function Get-DateStamp {
  Get-Date -Format 'yyyy-MM-dd'
}

function Get-Timestamp {
  Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

$LogDir = Join-Path -Path (Get-Location) -ChildPath 'logs'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = Join-Path -Path $LogDir -ChildPath ("setup_{0}.log" -f (Get-DateStamp))

function Write-LogLine {
  param([Parameter(Mandatory)] [string] $Message)
  $line = $Message
  Write-Output $line
  Add-Content -Path $LogFile -Value ("{0} {1}" -f (Get-Timestamp), $line) -Encoding utf8
}

function Log-Cmd {
  param([Parameter(Mandatory)] [string] $Cmd)
  Add-Content -Path $LogFile -Value ("{0} [CMD] {1}" -f (Get-Timestamp), $Cmd) -Encoding utf8
}
function Status-Ok { param([string]$Msg) Write-LogLine -Message ("[OK] {0}" -f $Msg) }
function Status-Warn { param([string]$Msg) Write-LogLine -Message ("[WARN] {0}" -f $Msg) }
function Status-Err { param([string]$Msg) Write-LogLine -Message ("[ERR] {0}" -f $Msg) }

function Invoke-LoggedCommand {
  param([Parameter(Mandatory)] [string] $Cmd)

  Log-Cmd -Cmd $Cmd

  $oldEAP = $ErrorActionPreference
  $hadPSNativePref = Test-Path variable:PSNativeCommandUseErrorActionPreference
  if ($hadPSNativePref) { $oldNCA = $PSNativeCommandUseErrorActionPreference }

  try {
    $ErrorActionPreference = 'Continue'
    if ($hadPSNativePref) { $PSNativeCommandUseErrorActionPreference = $true }

    # Merge stderr before PowerShell sees it to avoid false “errors”
    & cmd /c "$Cmd 2>&1" | Tee-Object -FilePath $LogFile -Append | Out-Null
    $code = $LASTEXITCODE
    return ($code -eq 0)
  }
  finally {
    $ErrorActionPreference = $oldEAP
    if ($hadPSNativePref) { $PSNativeCommandUseErrorActionPreference = $oldNCA }
  }
}

Write-LogLine -Message 'Starting setup...'

# -----------------------------
# 1. Ensure execution from repository root
# -----------------------------
try {
  $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $ProjectRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
  $CurrentDir = (Get-Location).Path

  if ($CurrentDir -ne $ProjectRoot) {
    Set-Location -Path $ProjectRoot
    if ((Get-Location).Path -eq $ProjectRoot) {
      Status-Ok "Step 1: Ensured running from project root: $ProjectRoot"
      Status-Warn "Was invoked from '$CurrentDir'; changed directory to '$ProjectRoot'"
    } else {
      Status-Err "Step 1: Failed to change to project root: $ProjectRoot"
      Exit-Script 1
    }
  } else {
    Status-Ok "Step 1: Already at project root: $ProjectRoot"
  }
} catch {
  Status-Err "Step 1: Error resolving or switching to project root: $_"
  Exit-Script 1
}

# -----------------------------
# 2. Verify required directories
# -----------------------------
$haveRequiredDirs =
  (Test-Path -Path 'labs' -PathType Container -ErrorAction SilentlyContinue) -and
  (Test-Path -Path 'scripts' -PathType Container -ErrorAction SilentlyContinue)

if ($haveRequiredDirs) {
  $labDirs  = Get-ChildItem -Path 'labs' -Directory -Filter 'lab*' -ErrorAction SilentlyContinue
  $labCount = ($labDirs | Measure-Object).Count
  if ($labCount -ge 1) {
    Status-Ok "Step 2: Verified 'labs/' and 'scripts/' exist and labs contains $labCount lab* directories"
  } else {
    Status-Err "Step 2: 'labs/' exists but contains no 'lab*' directories"
    Exit-Script 1
  }
} else {
  Status-Err "Step 2: Required directories missing. Expecting 'labs/' and 'scripts/' at repo root"
  Exit-Script 1
}

# -----------------------------
# 3. Ensure Windows package manager (winget/choco)
# -----------------------------
$HaveWinget = $false
$HaveChoco = $false
if (Get-Command winget -ErrorAction SilentlyContinue) { $HaveWinget = $true }
if (Get-Command choco -ErrorAction SilentlyContinue) { $HaveChoco = $true }

if ($HaveWinget) {
  if (Invoke-LoggedCommand -Cmd 'winget source update') {
    Status-Ok 'Step 3: Windows package sources updated (winget)'
  } else {
    Status-Warn 'Step 3: winget source update encountered issues; continuing'
  }
} elseif ($HaveChoco) {
  if (Invoke-LoggedCommand -Cmd 'choco upgrade chocolatey -y') {
    Status-Ok 'Step 3: Chocolatey upgraded'
  } else {
    Status-Warn 'Step 3: Chocolatey upgrade encountered issues; continuing'
  }
} else {
  Status-Warn 'Step 3: Neither winget nor choco detected; proceeding without package manager'
}

# -----------------------------
# Helper: ensure pyenv-win paths in current session
# -----------------------------
function Use-PyenvWinPaths {
  $pyenvBin = Join-Path $HOME '.pyenv\pyenv-win\bin'
  $pyenvShims = Join-Path $HOME '.pyenv\pyenv-win\shims'
  if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $pyenvBin })) { $env:PATH = "$pyenvBin;$env:PATH" }
  if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $pyenvShims })) { $env:PATH = "$pyenvShims;$env:PATH" }
}

# -----------------------------
# 4. Ensure pyenv-win
# -----------------------------
if (Get-Command pyenv -ErrorAction SilentlyContinue) {
  Status-Ok ("Step 4: pyenv detected: {0}" -f (Get-Command pyenv).Source)
} else {
  if ($HaveWinget) {
    Status-Warn 'Step 4: Installing pyenv-win via winget...'
    if (Invoke-LoggedCommand -Cmd 'winget install --id pyenv-win.pyenv-win -e --accept-source-agreements --accept-package-agreements') {
      Use-PyenvWinPaths
      Status-Ok 'Step 4: pyenv-win installed (winget)'
    } else {
      Status-Err 'Step 4: pyenv-win installation via winget failed'
      if ($HaveChoco) {
        Status-Warn 'Step 4: Installing pyenv-win via Chocolatey...'
        if (Invoke-LoggedCommand -Cmd 'choco install pyenv-win -y') {
          Use-PyenvWinPaths
          Status-Ok 'Step 4: pyenv-win installed (Chocolatey)'
        } else {
          Status-Err 'Step 4: pyenv-win installation via Chocolatey failed'
          Exit-Script 1
        }
      } else {
        Exit-Script 1
      }
    }
  } elseif ($HaveChoco) {
    Status-Warn 'Step 4: Installing pyenv-win via Chocolatey...'
    if (Invoke-LoggedCommand -Cmd 'choco install pyenv-win -y') {
      Use-PyenvWinPaths
      Status-Ok 'Step 4: pyenv-win installed (Chocolatey)'
    } else {
      Status-Err 'Step 4: pyenv-win installation via Chocolatey failed'
      Exit-Script 1
    }
  } else {
    Status-Err 'Step 4: No package manager available to install pyenv-win'
    Exit-Script 1
  }
}

# Ensure pyenv-win on PATH for current session
Use-PyenvWinPaths

# -----------------------------
# 5. Install Python 3.12 via pyenv and set local
# -----------------------------
if (Get-Command pyenv -ErrorAction SilentlyContinue) {
  $has312 = pyenv versions --bare 2>$null | Select-String -Pattern '^3\.12\.0$'
  if ($has312) {
    Status-Ok 'Step 5: Python 3.12.0 already installed in pyenv'
  } else {
    # Try common 3.12 version; if it fails, try generic 3.12
    Status-Warn 'Step 5: Installing Python 3.12.0 via pyenv'
    if (Invoke-LoggedCommand -Cmd 'pyenv install 3.12.0') {
      Status-Ok 'Step 5: Installed Python 3.12.0 via pyenv'
    } elseif (Invoke-LoggedCommand -Cmd 'pyenv install 3.12.0') {
      Status-Ok 'Step 5: Installed Python 3.12.0 via pyenv'
    } else {
      Status-Err 'Step 5: Failed to install Python 3.12.0 with pyenv'
      Exit-Script 1
    }
  }
  if (Invoke-LoggedCommand -Cmd 'pyenv local 3.12.0') {
    Status-Ok 'Step 5: Set local Python version to 3.12.0 (.python-version)'
  } else {
    Status-Err 'Step 5: Failed to set local Python version to 3.12.0'
    Exit-Script 1
  }
} else {
  Status-Err 'Step 5: pyenv not available; cannot install/set Python 3.12.0'
  Exit-Script 1
}

# -----------------------------
# 6. Ensure uv is installed
# -----------------------------
function Use-UvPaths {
  $userLocalBin = Join-Path $HOME '.local\bin'
  if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $userLocalBin })) { $env:PATH = "$userLocalBin;$env:PATH" }
}

$FallbackVenvDone = $false
function Fallback-SetupWithPythonVenv {
  Status-Warn 'Step 6: Attempting fallback: python -m venv and pip install'
  $py = 'python'
  if (-not (Get-Command $py -ErrorAction SilentlyContinue)) { $py = 'python3' }

  if (Get-Command $py -ErrorAction SilentlyContinue) {
    if (Invoke-LoggedCommand -Cmd "$py -m venv .venv") {
      Status-Ok 'Step 6: Created virtual environment with python -m venv'
      $activate = Join-Path (Get-Location) '.venv\Scripts\Activate.ps1'
      if (Test-Path $activate) {
        Log-Cmd -Cmd '. .\\.venv\\Scripts\\Activate.ps1'
        . .\.venv\Scripts\Activate.ps1
        Status-Ok 'Step 6: Activated virtual environment (fallback)'
      } else {
        Status-Err 'Step 6: Fallback venv activation script missing'
        return
      }

      if (Get-Command uv -ErrorAction SilentlyContinue) {
        if (Invoke-LoggedCommand -Cmd 'uv run pip install -r requirements.txt') {
          Status-Ok "Step 6: Installed dependencies via 'uv run pip' (fallback)"
          $Global:FallbackVenvDone = $true
        } else {
          Status-Err "Step 6: 'uv run pip install -r requirements.txt' failed (fallback)"
        }
      } else {
        if (Test-Path 'requirements.txt') {
          if (Invoke-LoggedCommand -Cmd "$py -m pip install -r requirements.txt") {
            Status-Ok 'Step 6: Installed dependencies via pip (fallback)'
            $Global:FallbackVenvDone = $true
          } else {
            Status-Err "Step 6: 'pip install -r requirements.txt' failed (fallback)"
          }
        } else {
          Status-Warn 'Step 6: requirements.txt not found; skipping dependency install (fallback)'
          $Global:FallbackVenvDone = $true
        }
      }
    } else {
      Status-Err 'Step 6: Failed to create virtual environment with python -m venv (fallback)'
    }
  } else {
    Status-Err 'Step 6: No python interpreter found for fallback'
  }
}

if (Get-Command uv -ErrorAction SilentlyContinue) {
  Status-Ok ("Step 6: uv detected: {0}" -f (Get-Command uv).Source)
} else {
  Status-Warn 'Step 6: uv not found; installing...'
  Use-UvPaths
  $installCmd = 'irm https://astral.sh/uv/install.ps1 | iex'
  if (Invoke-LoggedCommand -Cmd $installCmd) {
    Use-UvPaths
    if (Get-Command uv -ErrorAction SilentlyContinue) {
      Status-Ok 'Step 6: uv installed via PowerShell installer'
    } else {
      Status-Warn 'Step 6: uv installed but not yet on PATH in this shell; added common paths'
    }
  } else {
    Status-Err 'Step 6: uv installation failed'
    Fallback-SetupWithPythonVenv
  }
}

# -----------------------------
# 7. Create virtual environment and install dependencies using uv
# -----------------------------
$UvOk = $true
if ($FallbackVenvDone) {
  Status-Ok 'Step 7: Skipping uv workflow; fallback venv is ready and dependencies installed'
} else {
  if (Get-Command uv -ErrorAction SilentlyContinue) {
    if (Invoke-LoggedCommand -Cmd 'uv venv') {
      Status-Ok 'Step 7: Created virtual environment with uv (.venv)'
    } else {
      Status-Err 'Step 7: Failed to create virtual environment with uv'
      $UvOk = $false
    }

    $activate = Join-Path (Get-Location) '.venv\Scripts\Activate.ps1'
    if ($UvOk -and (Test-Path $activate)) {
      Log-Cmd -Cmd '. .\\.venv\\Scripts\\Activate.ps1'
      . .\.venv\Scripts\Activate.ps1
      Status-Ok 'Step 7: Activated virtual environment'
    } else {
      Status-Err 'Step 7: Virtual environment activation failed'
      $UvOk = $false
    }

    if ($UvOk) {
      if (Invoke-LoggedCommand -Cmd 'uv sync') {
        Status-Ok 'Step 7: Synced dependencies with uv'
      } else {
        Status-Err 'Step 7: Dependency sync with uv failed'
        $UvOk = $false
      }
    }
  } else {
    Status-Err 'Step 7: uv is not available; cannot create venv or sync'
    $UvOk = $false
  }
}

if ($UvOk -or $FallbackVenvDone) {
  Status-Ok 'Setup completed successfully'
} else {
  Status-Warn "Setup completed with some issues. See $LogFile for details"
}

Exit-Script 0
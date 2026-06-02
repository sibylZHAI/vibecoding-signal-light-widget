$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

if (-not $env:UV_CACHE_DIR) {
    $env:UV_CACHE_DIR = Join-Path $env:TEMP "signal-light-uv-cache"
}
if (-not $env:PYTHONDONTWRITEBYTECODE) {
    $env:PYTHONDONTWRITEBYTECODE = "1"
}

function Write-HookLog {
    param(
        [string]$Message
    )

    $logDir = Join-Path $HOME ".codex"
    $logPath = Join-Path $logDir "signal-light-hook.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    try {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Add-Content -LiteralPath $logPath -Value "[$timestamp] $Message"
    } catch {
        # Logging must never make a Codex hook fail.
    }
}

function Get-PythonCommand {
    $candidates = @(
        (Join-Path $RootDir ".venv\Scripts\python.exe"),
        (Join-Path $RootDir ".venv\bin\python")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return ,$candidate
        }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return ,$python.Source
    }

    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        return @($py.Source, "-3")
    }

    $python3 = Get-Command python3 -ErrorAction SilentlyContinue
    if ($python3) {
        return ,$python3.Source
    }

    throw "No usable Python interpreter found. Install Python or create .venv before running codex-signal-hook."
}

if ($env:SIGNAL_LIGHT_USE_UV -eq "1") {
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    if ($uv) {
        Write-HookLog "event=$($args -join ' ') runner=uv cwd=$RootDir"
        & $uv.Source run python -m signal_light codex-hook @args
        Write-HookLog "event=$($args -join ' ') exit=$LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

$pythonCmd = @(Get-PythonCommand)
$pythonArgs = @()
if ($pythonCmd.Length -gt 1) {
    $pythonArgs = $pythonCmd[1..($pythonCmd.Length - 1)]
}
Write-HookLog "event=$($args -join ' ') runner=$($pythonCmd -join ' ') cwd=$RootDir"
& $pythonCmd[0] @pythonArgs -m signal_light codex-hook @args
Write-HookLog "event=$($args -join ' ') exit=$LASTEXITCODE"
exit $LASTEXITCODE

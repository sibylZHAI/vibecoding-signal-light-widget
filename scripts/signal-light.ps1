$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

if (-not $env:UV_CACHE_DIR) {
    $env:UV_CACHE_DIR = Join-Path $env:TEMP "signal-light-uv-cache"
}
if (-not $env:PYTHONDONTWRITEBYTECODE) {
    $env:PYTHONDONTWRITEBYTECODE = "1"
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

    throw "No usable Python interpreter found. Install Python or create .venv before running signal-light."
}

if ($env:SIGNAL_LIGHT_USE_UV -eq "1") {
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    if ($uv) {
        & $uv.Source run python -m signal_light @args
        exit $LASTEXITCODE
    }
}

$pythonCmd = @(Get-PythonCommand)
$pythonArgs = @()
if ($pythonCmd.Length -gt 1) {
    $pythonArgs = $pythonCmd[1..($pythonCmd.Length - 1)]
}
& $pythonCmd[0] @pythonArgs -m signal_light @args
exit $LASTEXITCODE

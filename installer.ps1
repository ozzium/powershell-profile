# Raven Installer (Windows + macOS)
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    # If installer is in repo root, this is correct:
    return $PSScriptRoot
}

$repoRoot = Get-RepoRoot
$loader   = Join-Path $repoRoot "bootstrap/loader.ps1"

if (-not (Test-Path $loader)) {
    throw "Missing loader: $loader"
}

# Ensure profile directory exists
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

# Write minimal profile that loads the repo bootstrap
$profileContent = @"
# Raven Profile Bootstrap
. `"$loader`"
"@

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8

. $PROFILE
Write-Host "✅ Installed Raven loader into: $PROFILE" -ForegroundColor Green

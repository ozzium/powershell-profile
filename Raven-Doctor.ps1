[CmdletBinding()]
param(
  # Repo root on THIS machine (works on Windows + macOS)
  [string]$RepoRoot = "",
  [switch]$SetHomeOnSystem32 = $true
)

$ErrorActionPreference = "Stop"

function Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Warn($m){ Write-Host "⚠ $m" -ForegroundColor Yellow }
function Info($m){ Write-Host "ℹ $m" -ForegroundColor Cyan }

# --- Resolve repo root ---
if (-not $RepoRoot) {
  # Prefer common clone location
  $cand = Join-Path $HOME "Documents/GitHub/powershell-profile"
  if (Test-Path $cand) { $RepoRoot = $cand }
  else { $RepoRoot = $PSScriptRoot }
}

if (-not (Test-Path $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }
$RepoRoot = (Resolve-Path $RepoRoot).Path
Ok "RepoRoot: $RepoRoot"

# --- Ensure bootstrap loader exists ---
$Bootstrap = Join-Path $RepoRoot "bootstrap/loader.ps1"
if (-not (Test-Path $Bootstrap)) {
  throw "Missing bootstrap loader: $Bootstrap  (create bootstrap/loader.ps1 first)"
}
Ok "Bootstrap: $Bootstrap"

# --- Resolve profile module root ---
$ProfileRoot = Join-Path $RepoRoot "profile"
if (-not (Test-Path $ProfileRoot)) { throw "Profile folder not found: $ProfileRoot" }

foreach ($req in @("config.ps1","menu.ps1","raven.ps1")) {
  if (-not (Test-Path (Join-Path $ProfileRoot $req))) { throw "Missing $req in $ProfileRoot" }
}
Ok "ProfileRoot: $ProfileRoot"

# --- Set env var for THIS session (cross-platform) ---
$env:RAVEN_PROFILE_ROOT = $ProfileRoot
Ok "Set session env: RAVEN_PROFILE_ROOT = $ProfileRoot"

# --- Install $PROFILE loader (cross-platform) ---
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

$ProfileContent = @"
# Raven Profile Bootstrap (Doctor v2)
. `"$Bootstrap`"
"@

Set-Content -Path $PROFILE -Value $ProfileContent -Encoding UTF8
Ok "Installed loader into: $PROFILE"

# --- Smoke test: load profile now ---
. $PROFILE

# --- Optional: avoid System32 on Windows elevated shells ---
if ($SetHomeOnSystem32) {
  try {
    if ((Get-Location).Path -like "C:\Windows\System32*") { Set-Location $HOME }
  } catch {}
}

# --- Validate key commands ---
$must = @("profile-menu","Show-NeonFXMenu","Git-Sync","raven","Raven-Dashboard")
$missing = $must | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

# --- If raven missing, attempt to dot-source and show the real error ---
if ($missing -contains "raven") {
  $rp = Join-Path $ProfileRoot "raven.ps1"
  if (Test-Path $rp) {
    try { . $rp } catch {
      Warn ("raven.ps1 failed to load: {0}" -f $_.Exception.Message)
    }
  }
}

$missing = $must | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
if ($missing) {
  Warn "Missing commands:"
  $missing | ForEach-Object { Warn " - $_" }
  Info "Tip: run: Invoke-RavenSelfRepair -VerboseReport"
} else {
  Ok "All key commands present. Raven is healthy."
}

Write-Host ""
Write-Host "🦇 Raven Doctor complete." -ForegroundColor DarkMagenta

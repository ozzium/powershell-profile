[CmdletBinding()]
param(
  [string]$RepoRoot = "$HOME\Documents\GitHub\powershell-profile",
  [switch]$SetHomeOnSystem32 = $true
)

$ErrorActionPreference = "Stop"

function Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Warn($m){ Write-Host "⚠ $m" -ForegroundColor Yellow }

if (-not (Test-Path $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }

$ProfileRoot = Join-Path $RepoRoot "profile"
if (-not (Test-Path $ProfileRoot)) { throw "Profile modules folder not found: $ProfileRoot" }

foreach ($req in @("config.ps1","menu.ps1","raven.ps1")) {
  if (-not (Test-Path (Join-Path $ProfileRoot $req))) { throw "Missing $req in $ProfileRoot" }
}

# Pin env var (User)
[Environment]::SetEnvironmentVariable("RAVEN_PROFILE_ROOT", $ProfileRoot, "User")
$env:RAVEN_PROFILE_ROOT = $ProfileRoot
Ok "Set RAVEN_PROFILE_ROOT = $ProfileRoot"

# Install loader into the real $PROFILE
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

$Loader = @"
<#
  Raven Loader (Doctor Managed)
#>
`$ErrorActionPreference = 'SilentlyContinue'
`$root = [Environment]::GetEnvironmentVariable('RAVEN_PROFILE_ROOT','User')
if (-not `$root -or -not (Test-Path `$root)) { Write-Warning 'RAVEN_PROFILE_ROOT missing'; return }

function Show-RavenBootHeader {
  `$u = "`$env:USERNAME@`$env:COMPUTERNAME"
  `$v = `$PSVersionTable.PSVersion.ToString()
  `$d = (Get-Date).ToString('yyyy-MM-dd HH:mm')
  `$c = (Get-Location).Path
  Write-Host @'
██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗
██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║
██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝
      🦇  R A V E N   A W A K E N S  🦇
'@ -ForegroundColor DarkMagenta
}

foreach (`$f in `$files) {
  `$p = Join-Path `$root `$f
  if (-not (Test-Path `$p)) { continue }

  try {
    . `$p
  } catch {
    if (`$f -eq 'raven.ps1') {
      Write-Warning ("raven.ps1 failed to load: {0}" -f `$_.Exception.Message)
    }
  }
}

`$files = @(
  'config.ps1','utils.ps1','update.ps1','completions.ps1',
  'appearance.ps1','features.ps1','fx.ps1','inline.ps1',
  'shadows.ps1','raven.ps1','dashboard.ps1','menu.ps1',
  'help.ps1','init.ps1'
)
foreach (`$f in `$files) {
  `$p = Join-Path `$root `$f
  if (Test-Path `$p) { try { . `$p } catch {} }
}

"@

if ($SetHomeOnSystem32) {
  $Loader += @"
try { if ((Get-Location).Path -like 'C:\Windows\System32*') { Set-Location `$HOME } } catch {}
"@
}

$Loader += @"
if (Get-Command Invoke-Profile-PostInit -ErrorAction SilentlyContinue) { try { Invoke-Profile-PostInit } catch {} }
"@

Set-Content -Path $PROFILE -Value $Loader -Encoding UTF8
Ok "Installed loader into $PROFILE"

. $PROFILE

$must = @("profile-menu","Show-NeonFXMenu","Git-Sync","raven","Raven-Dashboard")
$missing = $must | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
if ($missing) {
  Warn "Missing commands:"
  $missing | ForEach-Object { Warn " - $_" }
} else {
  Ok "All key commands present."
}

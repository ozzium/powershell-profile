<#
  Raven Universal Loader (Windows + macOS)
  - Uses $env:RAVEN_PROFILE_ROOT if set
  - Else auto-detects under common GitHub locations
#>

$ErrorActionPreference = "SilentlyContinue"

function Resolve-RavenProfileRoot {
    if ($env:RAVEN_PROFILE_ROOT -and (Test-Path $env:RAVEN_PROFILE_ROOT)) {
        return (Resolve-Path $env:RAVEN_PROFILE_ROOT).Path
    }

    $candidates = @(
        (Join-Path $HOME "Documents/GitHub/powershell-profile/profile"),
        (Join-Path $HOME "Documents/Github/powershell-profile/profile"),
        (Join-Path $HOME "Documents/GitHub/powershell-profile"),
        (Join-Path $HOME "Documents/Github/powershell-profile"),
        (Join-Path $HOME "GitHub/powershell-profile/profile"),
        (Join-Path $HOME "Github/powershell-profile/profile"),
        (Join-Path $HOME "GitHub/powershell-profile"),
        (Join-Path $HOME "Github/powershell-profile")
    )

    foreach ($p in $candidates) {
        if (-not (Test-Path $p)) { continue }

        $profileDir = if (Test-Path (Join-Path $p "config.ps1")) { $p } else { Join-Path $p "profile" }
        if ((Test-Path (Join-Path $profileDir "config.ps1")) -and (Test-Path (Join-Path $profileDir "menu.ps1"))) {
            return (Resolve-Path $profileDir).Path
        }
    }

    return $null
}

$root = Resolve-RavenProfileRoot
if (-not $root) {
    Write-Warning "Raven root not found. Expected ~/Documents/GitHub/powershell-profile/profile or set RAVEN_PROFILE_ROOT."
    return
}

$env:RAVEN_PROFILE_ROOT = $root

# Load modules (order matters)
$files = @(
  "config.ps1","utils.ps1","update.ps1","completions.ps1",
  "appearance.ps1","features.ps1","fx.ps1","inline.ps1",
  "shadows.ps1","raven.ps1","dashboard.ps1","menu.ps1",
  "help.ps1","init.ps1"
)

foreach ($f in $files) {
    $p = Join-Path $root $f
    if (Test-Path $p) { try { . $p } catch {} }
}

# Avoid System32 start (Windows elevated)
try {
    if ((Get-Location).Path -like "C:\Windows\System32*") { Set-Location $HOME }
} catch {}

<#
  Raven Universal Loader v2 (Windows + macOS)
  - Uses $env:RAVEN_PROFILE_ROOT if set
  - Else auto-detects common GitHub locations
  - Option 2 boot (banner + info box) once per session
  - Prints REAL error if raven.ps1 fails (instead of silent skipping)
#>
Install-Module -Name Terminal-Icons
$ErrorActionPreference = "SilentlyContinue"

function Resolve-RavenProfileRoot {
    if ($env:RAVEN_PROFILE_ROOT -and (Test-Path $env:RAVEN_PROFILE_ROOT)) {
        return (Resolve-Path $env:RAVEN_PROFILE_ROOT).Path
    }

    $candidates = @(
        (Join-Path $HOME "Documents/GitHub/powershell-profile"),
        (Join-Path $HOME "Documents/Github/powershell-profile"),
        (Join-Path $HOME "GitHub/powershell-profile"),
        (Join-Path $HOME "Github/powershell-profile")
    )

    foreach ($repo in $candidates) {
        if (-not (Test-Path $repo)) { continue }

        $profileDir = Join-Path $repo "profile"
        if ((Test-Path (Join-Path $profileDir "config.ps1")) -and (Test-Path (Join-Path $profileDir "menu.ps1"))) {
            return (Resolve-Path $profileDir).Path
        }
    }

    return $null
}

function Show-RavenBootHeader {
    $u = "$env:USERNAME@$env:COMPUTERNAME"
    if (-not $env:USERNAME) { $u = "$env:USER@$env:HOSTNAME" }  # macOS friendliness
    $v = $PSVersionTable.PSVersion.ToString()
    $d = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $c = (Get-Location).Path

@"
██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗
██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║
██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝
      🦇  R A V E N   A W A K E N S  🦇

╭───────────────────────────────────────────────╮
│  💜 $u
│  PS Version: $v
│  Date: $d
│  CWD: $c
╰───────────────────────────────────────────────╯
"@ | Write-Host -ForegroundColor DarkMagenta
}

$root = Resolve-RavenProfileRoot
if (-not $root) {
    Write-Warning "Raven root not found. Clone to ~/Documents/GitHub/powershell-profile or set RAVEN_PROFILE_ROOT."
    return
}

# Export for this session
$env:RAVEN_PROFILE_ROOT = $root

# Boot header once per session
if (-not $script:RavenBootShown) {
    $script:RavenBootShown = $true
    Show-RavenBootHeader
}

# Load modules (order matters)
$files = @(
  "config.ps1",

  # Appearance first: defines Get-Theme / PSReadLine / prompt helpers
  "appearance.ps1",

  # Core utilities & update logic
  "utils.ps1",
  "update.ps1",
  "completions.ps1",

  # Features and FX next (menus call these)
  "features.ps1",
  "fx.ps1",
  "inline.ps1",
  "shadows.ps1",

  # Raven core + apps
  "raven.ps1",
  "dashboard.ps1",

  # Menu UI should come late (depends on features/fx)
  "menu.ps1",
  "help.ps1",

  # Init last (post-init hooks, admin checks, editor, etc.)
  "init.ps1"
)

foreach ($f in $files) {
    $p = Join-Path $root $f
    if (-not (Test-Path $p)) { continue }

    try {
        . $p
    } catch {
    # Show real module load failures for core Raven modules
    if ($f -in @("features.ps1","appearance.ps1","menu.ps1","raven.ps1")) {
        Write-Warning ("Failed loading {0}: {1}" -f $f, $_.Exception.Message)
    }
}
}

# Avoid System32 start (Windows elevated)
try {
    if ((Get-Location).Path -like "C:\Windows\System32*") { Set-Location $HOME }
} catch {}
# Ensure fog wrapper is applied LAST (so later modules don't overwrite it)
if (-not $script:RavenFogPromptWrapped -and (Get-Command Get-RavenFogGlyph -ErrorAction SilentlyContinue)) {
    $script:RavenFogPromptWrapped = $true

    $orig = (Get-Command prompt -ErrorAction SilentlyContinue).ScriptBlock

    function global:prompt {
        $base = & $orig
        if ($global:RavenFogEnabled) {
            $esc = [char]27
            $fog = "$esc[38;5;245m$(Get-RavenFogGlyph)$esc[0m "
            return "$fog$base"
        }
        return $base
    }
}

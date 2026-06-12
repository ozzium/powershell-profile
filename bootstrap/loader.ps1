$ErrorActionPreference = "Continue"

function Resolve-RavenRepoRoot {
    $preferred = Join-Path $HOME "Documents/GitHub/powershell-profile"

    if (Test-Path $preferred) {
        return $preferred
    }

    $candidates = @(
        (Join-Path $HOME "GitHub/powershell-profile"),
        (Join-Path $HOME "powershell-profile")
    )

    foreach ($repo in $candidates) {
        if (Test-Path (Join-Path $repo "bootstrap/loader.ps1")) {
            return $repo
        }
    }

    return $null
}

function Show-RavenBootHeader {
    $u = if ($env:USERNAME) { "$env:USERNAME@$env:COMPUTERNAME" } else { "$env:USER@$env:HOSTNAME" }
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

PS Version: $v
Date: $d
CWD: $c
"@ | Write-Host -ForegroundColor DarkMagenta
}

function Resolve-RavenRepoRoot {
    $preferred = Join-Path $HOME "Documents/GitHub/powershell-profile"

    if (Test-Path (Join-Path $preferred "bootstrap/loader.ps1")) {
        return $preferred
    }

    $candidates = @(
        (Join-Path $HOME "GitHub/powershell-profile"),
        (Join-Path $HOME "powershell-profile")
    )

    foreach ($repo in $candidates) {
        if (Test-Path (Join-Path $repo "bootstrap/loader.ps1")) {
            return $repo
        }
    }

    return $null
}

$RepoRoot = Resolve-RavenRepoRoot
if (-not $RepoRoot) {
    Write-Warning "Raven repo root not found."
    return
}

$env:RAVEN_PROFILE_ROOT = $RepoRoot

$ProfileRoot = Join-Path $RepoRoot "profile"
if (-not (Test-Path $ProfileRoot)) {
    Write-Warning "Raven profile folder not found: $ProfileRoot"
    return
}

if (-not $script:RavenBootShown) {
    $script:RavenBootShown = $true
    Show-RavenBootHeader
}
function Import-RavenModules {
    param(
        [string]$ModulesFile
    )

    if (-not (Test-Path $ModulesFile)) { return }

    try {
        $modules = Get-Content $ModulesFile -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Could not read modules file: $ModulesFile"
        return
    }

    foreach ($m in @($modules)) {
        $name = [string]$m.Name
        if (-not $name) { continue }

        $exists = Get-Module -ListAvailable -Name $name

        if (-not $exists -and $m.InstallIfMissing) {
            try {
                Install-Module -Name $name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            } catch {
                Write-Warning "Failed installing module '$name': $($_.Exception.Message)"
                continue
            }
        }

        try {
            Import-Module $name -ErrorAction Stop
        } catch {
            Write-Warning "Failed importing module '$name': $($_.Exception.Message)"
        }
    }
}
# Load modules (order matters)
Import-RavenModules -ModulesFile (Join-Path $ProfileRoot "modules.json")

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
  "git-tools.ps1",
	"menu.ps1",
  "help.ps1",

  # Init last (post-init hooks, admin checks, editor, etc.)
  "init.ps1"
)

foreach ($f in $files) {
    $p = Join-Path $ProfileRoot $f
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

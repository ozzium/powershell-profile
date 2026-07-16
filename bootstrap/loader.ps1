# Raven v3 - Bootstrap Loader

$global:RavenLoaderStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$global:RavenLoadTimings = @()
$global:RavenLoopOverheadTimings = @()
$global:RavenFileLoopTotalMs = 0
$global:RavenLoaderTotalMs = 0

function global:Get-RavenRepoRoot {
    if ($PSScriptRoot) {
        return (Split-Path -Parent $PSScriptRoot)
    }

    return "$HOME\Documents\GitHub\powershell-profile"
}

$repoRoot = Get-RavenRepoRoot
$profileRoot = Join-Path $repoRoot "profile"

# Raven root globals/env vars expected by profile modules
$global:RavenRepoRoot = $repoRoot
$global:RavenProfileRoot = $profileRoot

$env:RAVEN_REPO_ROOT = $repoRoot

# Legacy Raven modules expect this to be the repo root, not the /profile folder.
$env:RAVEN_PROFILE_ROOT = $repoRoot

if (-not (Test-Path $profileRoot)) {
    Write-Warning "Raven profile folder not found: $profileRoot"
    return
}

$files = @(
    "config.ps1"
    "appearance.ps1"
    "features.ps1"
    "raven.ps1"
    "init.ps1"
)

$swFileLoopTotal = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $files) {
    $swWholeItem = [System.Diagnostics.Stopwatch]::StartNew()

    $path = Join-Path $profileRoot $file

    if (-not (Test-Path $path)) {
        Write-Warning "Raven file not found: $file"
        continue
    }

    $swSource = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        . $path
    }
    catch {
        Write-Warning "Failed to load $file`: $($_.Exception.Message)"
    }

    $swSource.Stop()
    $swWholeItem.Stop()

    $global:RavenLoadTimings += [pscustomobject]@{
        File = $file
        Ms   = $swSource.ElapsedMilliseconds
    }

    $global:RavenLoopOverheadTimings += [pscustomobject]@{
        File        = $file
        SourceMs    = $swSource.ElapsedMilliseconds
        WholeItemMs = $swWholeItem.ElapsedMilliseconds
        OverheadMs  = $swWholeItem.ElapsedMilliseconds - $swSource.ElapsedMilliseconds
    }
}

$swFileLoopTotal.Stop()
$global:RavenFileLoopTotalMs = $swFileLoopTotal.ElapsedMilliseconds

# Avoid starting in System32 when elevated on Windows.
try {
    if ($IsWindows -and (Get-Location).Path -like "C:\Windows\System32*") {
        Set-Location $HOME
    }
}
catch {}

function global:Load-RavenFullMenu {
    if ($global:RavenFullMenuLoaded) {
        return
    }

    $repoRoot = $global:RavenRepoRoot

    if (-not $repoRoot) {
        $repoRoot = $env:RAVEN_REPO_ROOT
    }

    if (-not $repoRoot) {
        $repoRoot = $env:RAVEN_PROFILE_ROOT
    }

    if (-not $repoRoot) {
        Write-Warning "Raven Full Menu: repo root not found."
        return
    }

    $profileRoot = Join-Path $repoRoot "profile"

    if (-not (Test-Path $profileRoot)) {
        Write-Warning "Raven Full Menu: profile folder not found: $profileRoot"
        return
    }

    $menuFiles = @(
    "editors.ps1"
    "dashboard.ps1"
    "git-tools.ps1"
    "module-manager.ps1"
    "help.ps1"
    "menu.ps1"
)

    foreach ($file in $menuFiles) {
        $path = Join-Path $profileRoot $file

        if (Test-Path $path) {
            try {
                . $path
            }
            catch {
                Write-Warning "Failed to lazy-load $file`: $($_.Exception.Message)"
            }
        }
    }

    $global:RavenFullMenuLoaded = $true
}

function global:profile-menu {
    Remove-Item Function:\profile-menu -Force -ErrorAction SilentlyContinue

    Load-RavenFullMenu

    if (Get-Command profile-menu -CommandType Function -ErrorAction SilentlyContinue) {
        profile-menu
        return
    }

    Write-Warning "Raven menu files loaded, but the real profile-menu function was not found."
}

Write-Host "✔ Raven Core Loaded" -ForegroundColor Green
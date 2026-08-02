# Raven v3 - Bootstrap Loader

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

# Core startup files only.
# Heavier menu/tool files are lazy-loaded by profile-menu.
$coreFiles = @(
    "config.ps1"
    "appearance.ps1"
    "features.ps1"
    "dashboard.ps1"
    "raven.ps1"
    "init.ps1"
)

foreach ($file in $coreFiles) {
    $path = Join-Path $profileRoot $file

    if (-not (Test-Path $path)) {
        Write-Warning "Raven file not found: $file"
        continue
    }

    try {
        . $path
    }
    catch {
        Write-Warning "Failed to load $file`: $($_.Exception.Message)"
    }
}

# Avoid starting in System32 when elevated on Windows.
try {
    if ($IsWindows -and (Get-Location).Path -like "C:\Windows\System32*") {
        Set-Location $HOME
    }
}
catch {}

$global:RavenFullMenuLoaded = $false

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
        "git-tools.ps1"
        "module-manager.ps1"
        "help.ps1"
        "menu.ps1"
    )

    foreach ($file in $menuFiles) {
        $path = Join-Path $profileRoot $file

        if (-not (Test-Path $path)) {
            Write-Warning "Raven lazy-load file not found: $file"
            continue
        }

        try {
            . $path
        }
        catch {
            Write-Warning "Failed to lazy-load $file`: $($_.Exception.Message)"
        }
    }

    $global:RavenFullMenuLoaded = $true
}

function global:profile-menu {
    # Remove this lightweight wrapper so menu.ps1 can define the real profile-menu.
    Remove-Item Function:\profile-menu -Force -ErrorAction SilentlyContinue

    $global:RavenFullMenuLoaded = $false
    Load-RavenFullMenu

    $realMenu = Get-Command profile-menu -CommandType Function -ErrorAction SilentlyContinue

    if ($realMenu) {
        & $realMenu
        return
    }

    Write-Warning "Raven menu files loaded, but the real profile-menu function was not found."
}

Write-Host "✔ Raven Core Loaded" -ForegroundColor Green

Import-Module PowerShellProfileBackupper
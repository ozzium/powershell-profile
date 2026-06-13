<#
==========================================
 Raven Menu System
 Profile Navigation & Maintenance Tools
==========================================
#>

# Colors used for neon effect
$NeonCyan  = "`e[96m"
$NeonMag   = "`e[95m"
$NeonPink  = "`e[91m"
$NeonReset = "`e[0m"

function global:Show-RavenMenuHeader {

    Clear-Host

    $user = if ($env:USERNAME) {
        "$env:USERNAME@$env:COMPUTERNAME"
    } else {
        "$env:USER@$env:HOSTNAME"
    }

    $theme = if ($global:RavenTheme) {
        $global:RavenTheme
    } else {
        "default"
    }

    $repo = Split-Path $env:RAVEN_PROFILE_ROOT -Leaf

    Write-Host "╭──────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
    Write-Host "│ 🦇 Raven Console                             │" -ForegroundColor Magenta
    Write-Host ("│ User: {0,-36} │" -f $user) -ForegroundColor DarkMagenta
    Write-Host ("│ Theme: {0,-35} │" -f $theme) -ForegroundColor DarkMagenta
    Write-Host ("│ Repo: {0,-36} │" -f $repo) -ForegroundColor DarkMagenta
    Write-Host ("│ PS {0,-8} {1,-24} │" -f $PSVersionTable.PSVersion,$PSVersionTable.Platform) -ForegroundColor DarkMagenta
    Write-Host "╰──────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
    Write-Host ""
}

function Invoke-RavenSelfRepair {
    [CmdletBinding()]
    param(
        [switch]$VerboseReport
    )

# 1) Find repo root
$repoRoot = $env:RAVEN_PROFILE_ROOT

if (-not $repoRoot -or -not (Test-Path $repoRoot)) {
    $candidates = @(
        (Join-Path $HOME "Documents/GitHub/powershell-profile"),
        (Join-Path $HOME "GitHub/powershell-profile"),
        (Join-Path $HOME "powershell-profile")
    )

    $repoRoot = $candidates | Where-Object {
        Test-Path (Join-Path $_ "profile")
    } | Select-Object -First 1
}

if (-not $repoRoot -or -not (Test-Path $repoRoot)) {
    Write-Warning "Raven Self-Repair: repo root not found."
    Read-Host "Press Enter to continue..."
    return
}

$repoRoot = (Resolve-Path $repoRoot).Path
$env:RAVEN_PROFILE_ROOT = $repoRoot

$root = Join-Path $repoRoot "profile"

if (-not (Test-Path $root)) {
    Write-Warning "Raven Self-Repair: profile folder not found: $root"
    Read-Host "Press Enter to continue..."
    return
}

    # 2) Load modules in known-good order (silent by default)
    $files = @(
        "config.ps1",
        "appearance.ps1",
        "editors.ps1",
        "features.ps1",
        "raven.ps1",
        "dashboard.ps1",
        "git-tools.ps1",
        "menu.ps1",
        "module-manager.ps1",
        "help.ps1",
        "init.ps1"
    )

    $loaded   = New-Object System.Collections.Generic.List[string]
    $missing  = New-Object System.Collections.Generic.List[string]
    $failed   = New-Object System.Collections.Generic.List[string]

    foreach ($f in $files) {
        $p = Join-Path $root $f
        if (-not (Test-Path $p)) {
            $missing.Add($f) | Out-Null
            continue
        }

        try {
            . $p
            $loaded.Add($f) | Out-Null
        } catch {
            $failed.Add("{0} -> {1}" -f $f, $_.Exception.Message) | Out-Null
        }
    }

    # 3) Ensure key functions exist (and dot-source targeted files if needed)
    $mustHave = @(
        "profile-menu",
        "raven",
        "Raven-Dashboard"
    )

    $stillMissing = @()
    foreach ($name in $mustHave) {
        if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
            $stillMissing += $name
        }
    }

    # 4) Post-init visuals if available (quiet)
    if (Get-Command Invoke-Profile-PostInit -ErrorAction SilentlyContinue) {
        try { Invoke-Profile-PostInit } catch {}
    }

    # 5) Report
    Write-Host ""
    Write-Host "🦇 Raven Self-Repair complete." -ForegroundColor DarkMagenta
    Write-Host "Root: $root" -ForegroundColor DarkGray
    Write-Host ("Loaded:  {0}" -f $loaded.Count) -ForegroundColor Green

    if ($missing.Count -gt 0) {
        Write-Host ("Missing files: {0}" -f $missing.Count) -ForegroundColor Yellow
        if ($VerboseReport) { $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow } }
    }

    if ($failed.Count -gt 0) {
        Write-Host ("Failed: {0}" -f $failed.Count) -ForegroundColor Red
        $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }

    if ($stillMissing.Count -gt 0) {
        Write-Host "Still missing commands:" -ForegroundColor Yellow
        $stillMissing | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
        Write-Host "Tip: run:  Invoke-RavenSelfRepair -VerboseReport" -ForegroundColor DarkGray
    } else {
        Write-Host "All key commands are present. ✅" -ForegroundColor Cyan
    }

    Read-Host "Press Enter to continue..."
}

function global:profile-menu {

    $ExitMenu = $false

    while (-not $ExitMenu) {

        Show-RavenMenuHeader

        Write-Host "$NeonCyan 1$NeonReset • Switch Theme"
        Write-Host "$NeonCyan 2$NeonReset • Toggle Fast Mode"
        Write-Host "$NeonCyan 3$NeonReset • Edit Profile Files"
        Write-Host "$NeonCyan 4$NeonReset • Backup Profile"
        Write-Host "$NeonCyan 5$NeonReset • Git & GitHub Tools"
        Write-Host "$NeonCyan 6$NeonReset • Self-Repair (Reload Modules)"
        Write-Host "$NeonCyan 7$NeonReset • Module Manager"
        Write-Host "$NeonCyan 8$NeonReset • Exit"
		
		$choice = Read-Host "Choose an option"

        switch ($choice) {

            "1" { Show-ThemeMenu }
            "2" { Toggle-FastMode }
            "3" { Edit-ProfileFiles }
            "4" { Profile-Backup }
            "5" { Show-RavenGitMenu }
            "6" { Invoke-RavenSelfRepair }
            "7" { Show-RavenModuleMenu }
            "8" { $ExitMenu = $true; break }

            default {
                Write-Host "Invalid option!" -ForegroundColor Red
            }
        }

    }
}

# =============== SUBMENUS =======================================================

function Toggle-FastMode {
    if (-not $global:FastMode) {
        $global:FastMode = $true
        Write-Host "Fast mode: ENABLED" -ForegroundColor Green
    } else {
        $global:FastMode = $false
        Write-Host "Fast mode: DISABLED" -ForegroundColor Yellow
    }
}

function global:Edit-ProfileFiles {
    if (Get-Command Show-RavenEditProfileFiles -ErrorAction SilentlyContinue) {
        Show-RavenEditProfileFiles
        return
    }

    Write-Host ""
    Write-Host "Raven editor tools are not loaded." -ForegroundColor Red
    Write-Host "Make sure profile/editors.ps1 exists and loader.ps1 loads it before menu.ps1." -ForegroundColor Yellow
    Read-Host "Press Enter to continue..."
}

function global:Profile-Backup {
    $profileRoot = Get-RavenProfileRoot
    if (-not $profileRoot) {
        Write-Warning "Profile folder not found."
        Read-Host "Press Enter to continue..."
        return
    }

    $backupDir = Get-RavenPath Backups
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $dest = Join-Path $backupDir "raven-profile-backup-$timestamp.zip"

    Compress-Archive -Path $profileRoot -DestinationPath $dest -Force
    Write-Host "Backup created at: $dest" -ForegroundColor Green
    Read-Host "Press Enter to continue..."
}

function global:Get-RavenRepoRoot {
    if (-not $env:RAVEN_PROFILE_ROOT) { return $null }

    $root = (Resolve-Path $env:RAVEN_PROFILE_ROOT -ErrorAction SilentlyContinue)?.Path
    if (-not $root) { return $null }

    if (Test-Path (Join-Path $root ".git")) {
        return $root
    }

    $parent = (Resolve-Path (Join-Path $root "..") -ErrorAction SilentlyContinue)?.Path
    if ($parent -and (Test-Path (Join-Path $parent ".git"))) {
        return $parent
    }

    return $null
}

function global:Get-RavenProfileRoot {
    $repo = Get-RavenRepoRoot
    if (-not $repo) { return $null }

    $profile = Join-Path $repo "profile"
    if (Test-Path $profile) { return $profile }

    return $null
}


# Sanity check – will error loudly if braces are unbalanced
$null = {
    1
}


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

    $root = $env:RAVEN_PROFILE_ROOT

if (-not $root -and $global:RavenProfileRoot) {
    $root = $global:RavenProfileRoot
}

if (-not $root -and (Get-Command Get-RavenRepoRoot -ErrorAction SilentlyContinue)) {
    $root = Join-Path (Get-RavenRepoRoot) "profile"
}

$repo = if ($root) {
    Split-Path $root -Leaf
}
else {
    "profile"
}

    Write-Host "╭──────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
    Write-Host "│ 🦇 Raven Console                             │" -ForegroundColor Magenta
    Write-Host ("│ User: {0,-36} │" -f $user) -ForegroundColor DarkMagenta
    Write-Host ("│ Theme: {0,-35} │" -f $theme) -ForegroundColor DarkMagenta
    Write-Host ("│ Repo: {0,-36} │" -f $repo) -ForegroundColor DarkMagenta
    Write-Host ("│ PS {0,-8} {1,-24} │" -f $PSVersionTable.PSVersion,$PSVersionTable.Platform) -ForegroundColor DarkMagenta
    Write-Host "╰──────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
    Write-Host ""
}

function global:Invoke-RavenSelfRepair {
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
    while ($true) {
        Clear-Host

        if (Get-Command Show-RavenMenuHeader -ErrorAction SilentlyContinue) {
            Show-RavenMenuHeader
        }
        else {
            Write-Host "RAVEN PROFILE MENU" -ForegroundColor Cyan
        }

        Write-Host ""
        Write-Host "1 • Switch Theme" -ForegroundColor Cyan
        Write-Host "2 • Toggle Fast Mode" -ForegroundColor Cyan
        Write-Host "3 • Edit Profile Files" -ForegroundColor Cyan
        Write-Host "4 • Backup Profile" -ForegroundColor Cyan
        Write-Host "5 • Git & GitHub Tools" -ForegroundColor Cyan
        Write-Host "6 • Self-Repair (Reload Modules)" -ForegroundColor Cyan
        Write-Host "7 • Module Manager" -ForegroundColor Cyan
        Write-Host "8 • Exit" -ForegroundColor Cyan
        Write-Host ""

        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" {
                if (Get-Command Switch-RavenTheme -ErrorAction SilentlyContinue) {
                    Switch-RavenTheme
                }
                elseif (Get-Command Show-ThemeMenu -ErrorAction SilentlyContinue) {
                    Show-ThemeMenu
                }
                else {
                    Write-Warning "Theme switcher not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "2" {
                if (Get-Command Toggle-RavenFastMode -ErrorAction SilentlyContinue) {
                    Toggle-RavenFastMode
                }
                else {
                    Write-Warning "Fast Mode toggle not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "3" {
                if (Get-Command Edit-ProfileFiles -ErrorAction SilentlyContinue) {
                    Edit-ProfileFiles
                }
                else {
                    Write-Warning "Profile file editor not found."
                    Read-Host "Press Enter to continue..."
                }
            }

            "4" {
                if (Get-Command Profile-Backup -ErrorAction SilentlyContinue) {
                    Profile-Backup
                }
                else {
                    Write-Warning "Profile backup function not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "5" {
                if (Get-Command Show-RavenGitMenu -ErrorAction SilentlyContinue) {
                    Show-RavenGitMenu
                }
                else {
                    Write-Warning "Git tools menu not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "6" {
                if (Get-Command Invoke-RavenSelfRepair -ErrorAction SilentlyContinue) {
                    Invoke-RavenSelfRepair
                }
                else {
                    Write-Warning "Self-Repair function not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "7" {
                if (Get-Command Show-RavenModuleMenu -ErrorAction SilentlyContinue) {
                    Show-RavenModuleMenu
                }
                else {
                    Write-Warning "Module Manager not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "8" {
                return
            }

            default {
                Write-Warning "Invalid option."
                Read-Host "Press Enter to continue..."
            }
        }
    }
}

# =============== SUBMENUS =======================================================

function global:Toggle-RavenFastMode {
	
    if ($null -eq $global:RavenFastMode) {
        $global:RavenFastMode = $false
    }

    $global:RavenFastMode = -not [bool]$global:RavenFastMode

    if (Get-Command Save-RavenSettings -ErrorAction SilentlyContinue) {
        Save-RavenSettings -FastMode $global:RavenFastMode
    }

    if ($global:RavenFastMode) {
        Write-Host "Fast Mode Enabled" -ForegroundColor Green
    }
    else {
        Write-Host "Fast Mode Disabled" -ForegroundColor Yellow
    }

    Read-Host "Press Enter to continue..."
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


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

    # 1) Find profile root
    $root = $env:RAVEN_PROFILE_ROOT
    if (-not $root) {
        # Try common locations (fallback)
        $candidates = @(
            "$HOME\Documents\GitHub\powershell-profile\profile",
            "$HOME\Documents\Github\powershell-profile\profile",
            "$HOME\GitHub\powershell-profile\profile",
            "$HOME\Github\powershell-profile\profile",
            "$HOME\powershell-profile\profile"
        )
        $root = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($root) { $env:RAVEN_PROFILE_ROOT = $root }
    }

    if (-not $root -or -not (Test-Path $root)) {
        Write-Warning "Raven Self-Repair: profile root not found. Set `$env:RAVEN_PROFILE_ROOT to your /profile folder."
        Read-Host "Press Enter to continue..."
        return
    }

    $repoRoot = (Resolve-Path $root).Path
$root = Join-Path $repoRoot "profile"

    # 2) Load modules in known-good order (silent by default)
    $files = @(
        "config.ps1",
        "utils.ps1",
        "update.ps1",
        "completions.ps1",
        "appearance.ps1",
        "features.ps1",
        "fx.ps1",
        "inline.ps1",
        "shadows.ps1",
        "raven.ps1",
        "dashboard.ps1",
        "git-tools.ps1",
        "menu.ps1",
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
        "Show-NeonFXMenu",
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
        Write-Host "$NeonCyan 6$NeonReset • Cleanup Tools"
        Write-Host "$NeonCyan 7$NeonReset • Fun FX"
        Write-Host "$NeonCyan 8$NeonReset • Neon FX"
		    Write-Host "$NeonCyan 9$NeonReset • Toggle Fog Prompt"
		    Write-Host "$NeonCyan 10$NeonReset • Self-Repair (Reload Modules)"
        Write-Host "$NeonCyan 11$NeonReset • Exit"
		
		$choice = Read-Host "Choose an option"

        switch ($choice) {

            "1" { Show-ThemeMenu }
            "2" { Toggle-FastMode }
            "3" { Edit-ProfileFiles }
            "4" { Profile-Backup }
            "5" { Show-RavenGitMenu }
            "6" { Show-CleanupMenu }
            "7" { Show-FunMenu }
            "8"  { Show-NeonFXMenu }
            "9" { Toggle-FogPrompt }
            "10" { Invoke-RavenSelfRepair }
            "11" { $ExitMenu = $true; break }

            default {
                Write-Host "Invalid option!" -ForegroundColor Red
            }
        }

    }
}
function Show-ProcessPanel {
    $Exit = $false

    while (-not $Exit) {
        Clear-Host
        Write-Host "OZ PROCESS PANEL" -ForegroundColor Cyan
        Write-Host "------------------------------------"
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
            Select-Object Id, CPU, WorkingSet, ProcessName

        Write-Host ""
        Write-Host "[K]ill process  [R]efresh  [Q]uit" -ForegroundColor Yellow
        $choice = Read-Host "Choice"

        switch ($choice.ToUpper()) {
            "K" {
                $pid = Read-Host "Enter PID to kill"
                if ($pid) {
                    try {
                        Stop-Process -Id ([int]$pid) -Force
                        Write-Host ("Killed PID {0}" -f $pid) -ForegroundColor Green
                    } catch {
                        Write-Warning ("Failed to kill PID {0}: {1}" -f $pid, $_.Exception.Message)
                    }
                    Start-Sleep -Seconds 1
                }
            }
            "R" { }
            "Q" { $Exit = $true }
            default { }
        }
    }
}

function Show-FileApp {
    while ($true) {
        Clear-Host
        $cwd = Get-Location
        Write-Host "OZ FILE APP - $cwd" -ForegroundColor Cyan
        Write-Host "----------------------------------------------"

        $items = Get-ChildItem
        $index = 1
        foreach ($it in $items) {
            $mark = if ($it.PSIsContainer) { "[D]" } else { "   " }
            Write-Host ("{0,2}) {1} {2}" -f $index, $mark, $it.Name)
            $index++
        }

        Write-Host ""
        Write-Host "[Number]=Open/Enter  [U]=Up  [Q]=Quit" -ForegroundColor Yellow
        $choice = Read-Host "Choice"

        if ($choice.ToUpper() -eq "Q") { break }
        elseif ($choice.ToUpper() -eq "U") { Set-Location ..; continue }

        [int]$idx = 0
        if (-not [int]::TryParse($choice, [ref]$idx)) { continue }
        $realIndex = $idx - 1
        if ($realIndex -lt 0 -or $realIndex -ge $items.Count) { continue }

        $sel = $items[$realIndex]
        if ($sel.PSIsContainer) {
            Set-Location $sel.FullName
        } else {
            try { Start-Process $sel.FullName } catch {}
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
    Show-RavenMenuHeader

    $profileRoot = Get-RavenProfileRoot
    if (-not $profileRoot) {
        Write-Warning "Profile folder not found."
        Read-Host "Press Enter to continue..."
        return
    }

    Write-Host "Files:"
    $files = Get-ChildItem $profileRoot -Filter *.ps1 | Sort-Object Name

    $i = 1
    foreach ($f in $files) {
        Write-Host "$i) $($f.Name)"
        $i++
    }

    Write-Host ""
    $choice = Read-Host "Select file number"

    [int]$idx = 0
    if (-not [int]::TryParse($choice, [ref]$idx)) { return }

    $file = $files[$idx - 1]
    if ($file) {
        if (Get-Command e -ErrorAction SilentlyContinue) {
            e $file.FullName
        } elseif (Get-Command code -ErrorAction SilentlyContinue) {
            code $file.FullName
        } else {
            notepad $file.FullName
        }
    }
}

function global:Profile-Backup {
    $profileRoot = Get-RavenProfileRoot
    if (-not $profileRoot) {
        Write-Warning "Profile folder not found."
        Read-Host "Press Enter to continue..."
        return
    }

    $backupDir = Join-Path $HOME "Documents/PowerShell/Profile Backups"
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

function Show-CleanupMenu {
    Clear-Host
    Write-Host "$NeonCyanCLEANUP TOOLS$NeonReset"
    Write-Host "------------------------"
    Write-Host "1) Clear Temp"
    Write-Host "2) Clear DNS"
    Write-Host "3) Clear Recycle Bin"
    Write-Host ""
    $c = Read-Host "Choose"

    switch ($c) {
        "1" { Clean-Temp }
        "2" { flushdns }
        "3" { Clear-RecycleBin -Force }
    }
}

function global:Show-FunMenu {
    $ExitFun = $false

while (-not $ExitFun) {
    Clear-Host
    Write-Host "$NeonPink UTIL ZONE $NeonReset"
    Write-Host "------------------------"
    Write-Host " 1) Process Panel (Kill/Refresh)"
    Write-Host " 2) File App"
    Write-Host " 3) Back"
    Write-Host ""

    $c = Read-Host "Choose"

    switch ($c) {
        "1" { Show-ProcessPanel }
        "2" { Show-FileApp }
        "3" { $ExitFun = $true }
        default { }
    }
}
}

# Sanity check – will error loudly if braces are unbalanced
$null = {
    1
}


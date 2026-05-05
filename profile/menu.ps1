<# 
   ███╗   ██╗███████╗ ██████╗ ███╗   ██╗
   ████╗  ██║██╔════╝██╔═══██╗████╗  ██║
   ██╔██╗ ██║█████╗  ██║   ██║██╔██╗ ██║
   ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╗██║
   ██║ ╚████║███████╗╚██████╔╝██║ ╚████║
   ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
        [ O Z Z I U M   S Y S T E M ]
#>

# Colors used for neon effect
$NeonCyan  = "`e[96m"
$NeonMag   = "`e[95m"
$NeonPink  = "`e[91m"
$NeonReset = "`e[0m"

function Show-RavenMenuHeader {
    Clear-Host
    Write-Host "╭───────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
    Write-Host "│  🦇 R A V E N   C O N S O L E                 │" -ForegroundColor DarkMagenta
    Write-Host "│  Profile Menu                                 │" -ForegroundColor DarkMagenta
    Write-Host ("│  {0}@{1}  |  PS {2}" -f $env:USERNAME, $env:COMPUTERNAME, $PSVersionTable.PSVersion) -ForegroundColor DarkMagenta
    Write-Host ("│  Theme: {0}" -f ($global:RavenTheme ?? "cobalt2")) -ForegroundColor DarkMagenta
	Write-Host ("│  CWD: {0}" -f (Get-Location).Path) -ForegroundColor DarkMagenta
    Write-Host "╰───────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
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

    $root = (Resolve-Path $root).Path

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
        "Git-Sync",
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
        Write-Host "$NeonCyan 3$NeonReset • Update Profile"
        Write-Host "$NeonCyan 4$NeonReset • Edit Profile Files"
        Write-Host "$NeonCyan 5$NeonReset • Backup Profile"
        Write-Host "$NeonCyan 6$NeonReset • GitHub Sync"
        Write-Host "$NeonCyan 7$NeonReset • Cleanup Tools"
        Write-Host "$NeonCyan 8$NeonReset • Fun FX"
        Write-Host "$NeonCyan 9$NeonReset • Neon FX"
		Write-Host "$NeonCyan 10$NeonReset • Toggle Fog Prompt"
		Write-Host "$NeonCyan 11$NeonReset • Self-Repair (Reload Modules)"
        Write-Host "$NeonCyan 12$NeonReset • Exit"
		
		$choice = Read-Host "Choose an option"

        switch ($choice) {

            "1" { Show-ThemeMenu }
            "2" { Toggle-FastMode }
            "3" { Profile-Update }
            "4" { Edit-ProfileFiles }
            "5" { Profile-Backup }
            "6" { Git-Sync }
            "7" { Show-CleanupMenu }
            "8" { Show-FunMenu }
			"9"  { Show-NeonFXMenu }
			"10" { Toggle-FogPrompt }
			"11" { Invoke-RavenSelfRepair }
			"12" { $ExitMenu = $true; break }

            # FIXED EXIT
            "11" { 
                $ExitMenu = $true
            }

            default {
                Write-Host "Invalid option!" -ForegroundColor Red
            }
        }

        if (-not $ExitMenu) {
            Pause
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

function Profile-Update {
    Write-Host "Updating profile..." -ForegroundColor Cyan

    $repo = Get-RavenRepoRoot
    if (-not $repo) {
        Write-Warning "Raven repo not found. Expected .git next to: $env:RAVEN_PROFILE_ROOT"
        Read-Host "Press Enter to continue..."
        return
    }

    Push-Location $repo
    try {
        git pull
        if ($LASTEXITCODE -ne 0) { throw "git pull failed." }

        Write-Host "Reloading profile..." -ForegroundColor Cyan
        if (Get-Command reload-profile -ErrorAction SilentlyContinue) {
            reload-profile
        } else {
            . $PROFILE
        }

        Write-Host "Done!" -ForegroundColor Green
    } catch {
        Write-Warning ("Update failed: {0}" -f $_.Exception.Message)
    } finally {
        Pop-Location
        Read-Host "Press Enter to continue..."
    }
}


function Edit-ProfileFiles {
    Show-RavenMenuHeader
    Write-Host "Files:"
    $files = Get-ChildItem $ProfileRoot -Filter *.ps1
    $i = 1
    foreach ($f in $files) {
        Write-Host "$i) $($f.Name)"
        $i++
    }
    Write-Host ""
    $choice = Read-Host "Select file number"
    $file = $files[$choice - 1]
    if ($file) {
        & $global:PSProfileConfig.Editor $file.FullName
    }
}

function Profile-Backup {
    $backupDir = Join-Path $HOME "Documents\PowerShell\Profile Backups"
    if (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory | Out-Null }

    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $dest = Join-Path $backupDir "backup-$timestamp.zip"

    Compress-Archive -Path $ProfileRoot -DestinationPath $dest
    Write-Host "Backup created at: $dest" -ForegroundColor Green
}

function Get-RavenRepoRoot {
    # Repo root is the parent of the profile folder
    if (-not $env:RAVEN_PROFILE_ROOT) { return $null }

    $profileRoot = (Resolve-Path $env:RAVEN_PROFILE_ROOT -ErrorAction SilentlyContinue)?.Path
    if (-not $profileRoot) { return $null }

    $repoRoot = (Resolve-Path (Join-Path $profileRoot "..") -ErrorAction SilentlyContinue)?.Path
    if ($repoRoot -and (Test-Path (Join-Path $repoRoot ".git"))) { return $repoRoot }

    return $null
}

function Git-Sync {
    $repo = Get-RavenRepoRoot
    if (-not $repo) {
        Write-Warning "Raven repo not found. Expected '.git' next to: $env:RAVEN_PROFILE_ROOT"
        Read-Host "Press Enter to continue..."
        return
    }

    Push-Location $repo
    try {
        Write-Host "🦇 Syncing Raven from: $repo" -ForegroundColor DarkMagenta

        git pull
        if ($LASTEXITCODE -ne 0) { throw "git pull failed." }

        # Optional: only commit if changes exist
        git add -A
        git diff --cached --quiet
        if ($LASTEXITCODE -ne 0) {
            git commit -m "Raven sync $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-Null
        }

        git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed." }

        Write-Host "✅ GitHub sync complete." -ForegroundColor Green
    }
    catch {
        Write-Warning ("GitHub sync failed: {0}" -f $_)
    }
    finally {
        Pop-Location
        Read-Host "Press Enter to continue..."
    }
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


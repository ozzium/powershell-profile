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

function Show-NeonHeader {
    Clear-Host
    Write-Host ""
    Write-Host "$NeonCyan██████╗  ██████╗ ███████╗$NeonReset"
    Write-Host "$NeonPink██╔══██╗██╔═══██╗██╔════╝$NeonReset"
    Write-Host "$NeonMag██████╔╝██║   ██║█████╗  $NeonReset"
    Write-Host "$NeonCyan██╔══██╗██║   ██║██╔══╝  $NeonReset"
    Write-Host "$NeonPink██║  ██║╚██████╔╝███████╗$NeonReset"
    Write-Host "$NeonMag╚═╝  ╚═╝ ╚═════╝ ╚══════╝$NeonReset"
    Write-Host ""
    Write-Host "$NeonPink        [ O Z   S Y S T E M ]$NeonReset"
    Write-Host "---------------------------------------------------"
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

        Show-NeonHeader

        Write-Host "$NeonCyan 1$NeonReset • Switch Theme"
        Write-Host "$NeonCyan 2$NeonReset • Toggle Fast Mode"
        Write-Host "$NeonCyan 3$NeonReset • Update Profile"
        Write-Host "$NeonCyan 4$NeonReset • Edit Profile Files"
        Write-Host "$NeonCyan 5$NeonReset • Backup Profile"
        Write-Host "$NeonCyan 6$NeonReset • GitHub Sync"
        Write-Host "$NeonCyan 7$NeonReset • Cleanup Tools"
        Write-Host "$NeonCyan 8$NeonReset • Fun FX"
        Write-Host "$NeonCyan 9$NeonReset • Neon FX"
		Write-Host "$NeonCyan 10$NeonReset • Self-Repair (Reload Modules)"
        Write-Host "$NeonCyan 11$NeonReset • Exit"
		
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
			"10" { Invoke-RavenSelfRepair }
			"11" { $ExitMenu = $true; break }

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


# =============== SUBMENUS =======================================================

function Show-ThemeMenu {
    Clear-Host
    Write-Host "$NeonMagTHEME ENGINE$NeonReset"
    Write-Host "----------------------------------------"
    Write-Host "1) cobalt2"
    Write-Host "2) default"
    Write-Host ""
    $c = Read-Host "Choose theme"

    switch ($c) {
        "1" { Switch-Theme cobalt2 }
        "2" { Switch-Theme default }
        default { Write-Host "Unknown theme." -ForegroundColor Red }
    }
}

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
    try {
        Write-Host "Updating profile..." -ForegroundColor Cyan
        git pull
        reload-profile
        Write-Host "Done!" -ForegroundColor Green
    } catch {
        Write-Host "Update failed: $_" -ForegroundColor Red
    }
}

function Edit-ProfileFiles {
    Show-NeonHeader
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
    Clear-Host
    $esc = [char]27

    while ($true) {
        Clear-Host
        Write-Host "$NeonPinkFUN ZONE$NeonReset"
        Write-Host "------------------------"
        Write-Host " 1) Matrix Rain"
        Write-Host " 2) Neon Wave"
        Write-Host " 3) Ripple Wave"
        Write-Host " 4) Typing Boot Animation"
        Write-Host " 5) Cyber Cursor Demo"
        Write-Host " 6) Cyberpunk Prompt"
        Write-Host " 7) Reset Prompt"
        Write-Host " 8) Neon Border (Gradient)"
		Write-Host "$NeonCyan 9$NeonReset • Neon FX"
        Write-Host " 9) Task App"
        Write-Host "10) Git App"
        Write-Host "11) File App"
        Write-Host "12) Back"
        Write-Host ""

        $c = Read-Host "Choose"

        switch ($c) {

            # 1) MATRIX RAIN
            "1" {
                Clear-Host
                $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
                $lines = 40
                $width = 80
                for ($i = 0; $i -lt $lines; $i++) {
                    $line = -join (1..$width | ForEach-Object {
                        $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
                    })
                    Write-Host "$esc[92m$line$esc[0m"
                    Start-Sleep -Milliseconds 60
                }
                Read-Host "Press Enter to return..."
            }

            # 2) NEON WAVE
            "2" {
                Clear-Host
                $colors = @("$esc[95m", "$esc[96m", "$esc[94m", "$esc[91m")
                $lines  = 30
                for ($i = 0; $i -lt $lines; $i++) {
                    $offset = [int](15 * [Math]::Sin($i / 3.0))
                    if ($offset -lt 0) { $offset = 0 }
                    $color = $colors[$i % $colors.Count]
                    $wave  = "~" * 10
                    Write-Host (" " * $offset + $color + $wave + "$esc[0m")
                    Start-Sleep -Milliseconds 50
                }
                Read-Host "Press Enter to return..."
            }

            # 3) RIPPLE WAVE
            "3" {
                Clear-Host
                $radius = 15
                $colors = @("$esc[96m", "$esc[95m")
                for ($r = 1; $r -le $radius; $r++) {
                    $color   = $colors[$r % $colors.Count]
                    $padding = " " * ($radius - $r)
                    $body    = "~" * ($r * 2)
                    Write-Host ($padding + $color + $body + "$esc[0m")
                    Start-Sleep -Milliseconds 50
                }
                Read-Host "Press Enter to return..."
            }

            # 4) TYPING BOOT ANIMATION
            "4" {
                Clear-Host
                $text = "BOOTING OZ NEON SYSTEM..."
                $chars = $text.ToCharArray()
                foreach ($ch in $chars) {
                    Write-Host -NoNewline "$esc[95m$ch$esc[0m"
                    Start-Sleep -Milliseconds 40
                }
                Write-Host ""
                Read-Host "Press Enter to return..."
            }

            # 5) CYBER CURSOR DEMO
            "5" {
                Clear-Host
                $frames = @("|","/","-","\")
                $sw = [Diagnostics.Stopwatch]::StartNew()
                while ($sw.Elapsed.TotalSeconds -lt 5) {
                    foreach ($f in $frames) {
                        Write-Host "`r$esc[96m$f$esc[0m" -NoNewline
                        Start-Sleep -Milliseconds 80
                    }
                }
                Write-Host "`r " -NoNewline
                Write-Host ""
                Read-Host "Press Enter to return..."
            }

            # 6) CYBERPUNK PROMPT
            "6" {
                function global:prompt {
                    $esc   = [char]27
                    $cwd   = (Get-Location).Path
                    $user  = [Environment]::UserName
                    $hostN = $env:COMPUTERNAME
                    $symbol = if ($global:IsAdmin) { "#" } else { "$" }

                    $pathPart = "$esc[96m$cwd$esc[0m"
                    $userPart = "$esc[95m$user@$hostN$esc[0m"
                    $arrow    = "$esc[91m>$esc[0m"

                    "$userPart $pathPart $arrow $symbol "
                }
                Write-Host "Cyberpunk prompt enabled." -ForegroundColor Magenta
                Read-Host "Press Enter to return..."
            }

            # 7) RESET PROMPT
            "7" {
                function global:prompt {
                    Invoke-Profile-PostInit
                    $cwd = (Get-Location).Path
                    if ($global:IsAdmin) { "[$cwd] # " } else { "[$cwd] $ " }
                }
                Write-Host "Default prompt restored." -ForegroundColor Yellow
                Read-Host "Press Enter to return..."
            }

            # 8) NEON BORDER (GRADIENT)
            "8" {
                Clear-Host
                $text = "OZ NEON SYSTEM"
                $line = "─" * ($text.Length + 4)
                $colors = @("$esc[95m","$esc[96m","$esc[94m","$esc[91m")

                $top = ""
                for ($i = 0; $i -lt $line.Length; $i++) {
                    $top += $colors[$i % $colors.Count] + $line[$i]
                }
                Write-Host $top + "$esc[0m"
                Write-Host "$esc[95m│$esc[0m $text $esc[96m│$esc[0m"
                $bottom = ""
                for ($i = 0; $i -lt $line.Length; $i++) {
                    $bottom += $colors[($i + 2) % $colors.Count] + $line[$i]
                }
                Write-Host $bottom + "$esc[0m"
                Write-Host ""
                Read-Host "Press Enter to return..."
            }
			

            # 9) TASK APP
            "9" {
                while ($true) {
                    Clear-Host
                    Write-Host "OZ TASK APP" -ForegroundColor Cyan
                    Write-Host "------------------------------------"
                    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 `
                        | Select-Object Id, CPU, WorkingSet, ProcessName
                    Write-Host ""
                    Write-Host "[K]ill process  [R]efresh  [Q]uit" -ForegroundColor Yellow
                    $choice = Read-Host "Choice"
                    switch ($choice.ToUpper()) {
                        "K" {
                            $pid = Read-Host "Enter PID to kill"
                            if ($pid) {
                                try {
                                    Stop-Process -Id [int]$pid -Force
                                    Write-Host "Killed PID $pid" -ForegroundColor Green
                                } catch {
                                    Write-Warning ("Failed to kill PID {0}: {1}" -f $pid, $_)
                                }
                                Start-Sleep -Seconds 1
                            }
                        }
                        "R" { continue }
                        "Q" { break }
                        default { }
                    }
                }
            }

            # 10) GIT APP
            "10" {
                if (-not (Test-Path ".git")) {
                    Write-Warning "No .git folder here. Not a git repo."
                    Read-Host "Press Enter to return..."
                } else {
                    while ($true) {
                        Clear-Host
                        Write-Host "OZ GIT APP" -ForegroundColor Magenta
                        Write-Host "------------------------------------"
                        git status
                        Write-Host ""
                        Write-Host "[A]dd .  [C]ommit  [P]ush  [L]og  [Q]uit" -ForegroundColor Yellow
                        $choice = Read-Host "Choice"
                        switch ($choice.ToUpper()) {
                            "A" { git add . }
                            "C" {
                                $msg = Read-Host "Commit message"
                                if ($msg) { git commit -m $msg }
                            }
                            "P" { git push }
                            "L" { git log --oneline --decorate --graph --max-count=15 | more }
                            "Q" { break }
                            default { }
                        }
                    }
                }
            }

            # 11) FILE APP
            "11" {
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

            # 12) BACK
            "12" {
                return
            }

            default {
                # ignore
            }
        }
    }
}


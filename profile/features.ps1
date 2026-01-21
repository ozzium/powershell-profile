# features.ps1 - extra goodies for Oz's modular profile

# Ensure PSProfileConfig exists
if (-not $global:PSProfileConfig) {
    $global:PSProfileConfig = [pscustomobject]@{}
}

function Set-PSProfileDefault {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value
    )
    if (-not $global:PSProfileConfig) {
        $global:PSProfileConfig = [pscustomobject]@{}
    }
    if (-not ($global:PSProfileConfig.PSObject.Properties.Name -contains $Name)) {
        Add-Member -InputObject $global:PSProfileConfig -NotePropertyName $Name -NotePropertyValue $Value
    }
}

# Default config values
Set-PSProfileDefault -Name 'PromptMode'        -Value 'Normal'
Set-PSProfileDefault -Name 'BackupRoot'        -Value (Join-Path $HOME 'Documents\PowerShell\Profile Backups')
Set-PSProfileDefault -Name 'AutoUpdateEnabled' -Value $true
Set-PSProfileDefault -Name 'BookmarksPath'     -Value (Join-Path $HOME 'Documents\PowerShell\ProfileBookmarks.xml')

# Helper: find profile root (same logic as loader, but safe)
function Get-ProfileRoot {
    $candidates = @(
        "$HOME\Documents\GitHub\powershell-profile\profile",
        "$HOME\powershell-profile\profile",
        "$HOME\Documents\powershell-profile\profile",
        "$HOME\Dev\powershell-profile\profile",
        "$HOME\Source\powershell-profile\profile"
    )

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) {
            return $c
        }
    }

    return $null
}

# =========================
# A. Visual & Prompt Goodies
# =========================

function Show-ProfileBanner {
    $user = [Environment]::UserName
    $comp = $env:COMPUTERNAME
    $date = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $pwsh = $PSVersionTable.PSVersion.ToString()
    $cwd  = (Get-Location).Path

    Write-Host ""
    Write-Host "╭───────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host ("│  Welcome, {0}@{1}" -f $user, $comp).PadRight(47) + "│" -ForegroundColor Cyan
    Write-Host ("│  PowerShell {0}" -f $pwsh).PadRight(47) + "│" -ForegroundColor Cyan
    Write-Host ("│  {0}" -f $date).PadRight(47) + "│" -ForegroundColor Cyan
    Write-Host ("│  CWD: {0}" -f $cwd).PadRight(47) + "│" -ForegroundColor Cyan
    Write-Host "╰───────────────────────────────────────────────╯" -ForegroundColor Cyan
    Write-Host ""
}

function Set-ProfilePromptMode {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Normal','Fast')]
        [string]$Mode
    )
    $global:PSProfileConfig.PromptMode = $Mode
    Write-Host "Prompt mode set to $Mode." -ForegroundColor Green
    if ($Mode -eq 'Fast') {
        Write-Host "Fast mode: skipping oh-my-posh for maximum speed." -ForegroundColor Yellow
    } else {
        Write-Host "Normal mode: full themed prompt." -ForegroundColor Yellow
    }
}
function Switch-Theme {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    if (-not (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue)) {
        Write-Warning "oh-my-posh is not installed. Install it first to use theme switching."
        return
    }

    # "default" should mean: your preferred baseline
    if ($Name -eq "default") { $Name = "cobalt2" }

    $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$Name.omp.json"

    try {
        oh-my-posh init pwsh --config $url | Invoke-Expression
        Write-Host ("Switched theme to {0}." -f $Name) -ForegroundColor Green
    } catch {
        Write-Warning ("Failed to apply theme: {0}" -f $_.Exception.Message)
    }
}

function Show-ThemeMenu {
    if (-not (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue)) {
        Write-Warning "oh-my-posh is not installed. Install it first to use theme switching."
        Read-Host "Press Enter to return..."
        return
    }

    $themes = @(
        @{ Name = 'cobalt2';        Id = 'cobalt2' },
        @{ Name = 'paradox';        Id = 'paradox' },
        @{ Name = 'atomic';         Id = 'atomic' },
        @{ Name = 'jandedobbeleer'; Id = 'jandedobbeleer' },
        @{ Name = 'agnoster';       Id = 'agnoster' },
        @{ Name = 'dracula';        Id = 'dracula' },
        @{ Name = 'tokyonight';     Id = 'tokyonight_storm' },
        @{ Name = 'night-owl';      Id = 'night-owl' },
        @{ Name = 'powerline';      Id = 'powerline' }
    )

    Clear-Host
    Write-Host "THEME ENGINE" -ForegroundColor Magenta
    Write-Host "----------------------------------------" -ForegroundColor DarkGray

    for ($i = 0; $i -lt $themes.Count; $i++) {
        Write-Host (" [{0}] {1}" -f ($i + 1), $themes[$i].Name) -ForegroundColor Yellow
    }

    Write-Host ""
    $choice = Read-Host "Choose a theme number (Enter to cancel)"
    if (-not $choice) { return }

    [int]$index = 0
    if (-not [int]::TryParse($choice, [ref]$index)) {
        Write-Warning "Invalid choice."
        Read-Host "Press Enter to return..."
        return
    }

    $idx = $index - 1
    if ($idx -lt 0 -or $idx -ge $themes.Count) {
        Write-Warning "Choice out of range."
        Read-Host "Press Enter to return..."
        return
    }

    $themeId = $themes[$idx].Id
    $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$themeId.omp.json"

    # Save preference in-session (so other scripts can reuse it)
    $global:RavenTheme = $themeId

    try {
        oh-my-posh init pwsh --config $url | Invoke-Expression
        Write-Host ("Switched theme to {0}." -f $themes[$idx].Name) -ForegroundColor Green
    } catch {
        Write-Warning ("Failed to apply theme: {0}" -f $_.Exception.Message)
    }

    Read-Host "Press Enter to continue..."
}


# =========================
# B. Backups & Updates
# =========================

function Invoke-ProfileBackup {
    $root = Get-ProfileRoot
    if (-not $root) {
        Write-Warning "Profile root not found; cannot back up."
        return
    }

    $backupRoot = $global:PSProfileConfig.BackupRoot
    if (-not $backupRoot) {
        $backupRoot = Join-Path $HOME 'Documents\PowerShell\Profile Backups'
        $global:PSProfileConfig.BackupRoot = $backupRoot
    }

    try {
        if (-not (Test-Path $backupRoot)) {
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        }

        $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
        $dest  = Join-Path $backupRoot $stamp
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        Copy-Item -Path (Join-Path $root '*.ps1') -Destination $dest -Recurse -Force
        Write-Host "Profile backed up to $dest" -ForegroundColor Green
    } catch {
        Write-Warning "Backup failed: $_"
    }
}

function Invoke-RemoteProfileUpdate {
    param(
        [switch]$NoBackup
    )

    $root = Get-ProfileRoot
    if (-not $root) {
        Write-Warning "Profile root not found; cannot update."
        return
    }

    $repo = $null
    if ($global:PSProfileConfig -and `
        ($global:PSProfileConfig.PSObject.Properties.Name -contains 'RepoRootRaw')) {
        $repo = $global:PSProfileConfig.RepoRootRaw
    }
    if (-not $repo) {
        Write-Warning "RepoRootRaw is not configured in PSProfileConfig. Cannot update."
        return
    }

    if (-not $NoBackup) {
        Invoke-ProfileBackup
    }

    $repo = $repo.TrimEnd('/')
    $files = @(
        'config.ps1',
        'init.ps1',
        'update.ps1',
        'utils.ps1',
        'completions.ps1',
        'appearance.ps1',
        'help.ps1',
        'features.ps1'
    )

    foreach ($f in $files) {
        $url = "$repo/profile/$f"
        $out = Join-Path $root $f
        try {
            Invoke-RestMethod -Uri $url -OutFile $out -ErrorAction Stop
            Write-Host "Updated $f from $url" -ForegroundColor DarkGreen
        } catch {
            Write-Warning ("Failed to update {0} from {1}: {2}" -f $f, $url, $_)
        }
    }

    Write-Host "Remote profile update complete. Run reload-profile to apply." -ForegroundColor Green
}

# =========================
# C. Project-aware helpers
# =========================

function Show-ProjectInfo {
    $cwd = Get-Location
    $markers = @(
        'package.json',
        'pnpm-lock.yaml',
        'yarn.lock',
        'bun.lockb',
        'tsconfig.json',
        'pyproject.toml',
        'requirements.txt',
        'Pipfile',
        'Pipfile.lock',
        'composer.json',
        'Cargo.toml',
        'go.mod',
        'Gemfile',
        '.git'
    )

    $found = @()
    foreach ($m in $markers) {
        if (Test-Path (Join-Path $cwd.Path $m)) {
            $found += $m
        }
    }

    Write-Host ""
    Write-Host "Project context for $($cwd.Path)" -ForegroundColor Cyan
    if ($found.Count -eq 0) {
        Write-Host "  No known project files found." -ForegroundColor DarkGray
    } else {
        Write-Host "  Detected markers:" -ForegroundColor Yellow
        $found | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
    }
}

# =========================
# D. Zoxide & bookmarks
# =========================

function zw {
    param([string]$Query)
    if (Get-Command -Name 'z' -ErrorAction SilentlyContinue) {
        if ($Query) { z $Query } else { z }
    } elseif (Get-Command -Name 'zoxide' -ErrorAction SilentlyContinue) {
        if ($Query) { zoxide query $Query } else { zoxide query --list }
    } else {
        Write-Warning "zoxide is not installed."
    }
}

function zf {
    param([string]$Filter)
    if (-not (Get-Command -Name 'zoxide' -ErrorAction SilentlyContinue)) {
        Write-Warning "zoxide is not installed."
        return
    }
    $list = zoxide query --list
    if ($Filter) {
        $list | Where-Object { $_ -like "*$Filter*" }
    } else {
        $list
    }
}

function Get-ProfileBookmarks {
    $path = $global:PSProfileConfig.BookmarksPath
    if (-not $path) { return @{} }
    if (-not (Test-Path $path)) { return @{} }

    try {
        $map = Import-Clixml -Path $path -ErrorAction Stop
        if ($map -is [hashtable]) { return $map }
        return @{}
    } catch {
        return @{}
    }
}

function Save-ProfileBookmarks {
    param(
        [Parameter(Mandatory)][hashtable]$Bookmarks
    )

    $path = $global:PSProfileConfig.BookmarksPath
    if (-not $path) {
        $path = Join-Path $HOME 'Documents\PowerShell\ProfileBookmarks.xml'
        $global:PSProfileConfig.BookmarksPath = $path
    }

    try {
        $dir = Split-Path -Parent $path
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $Bookmarks | Export-Clixml -Path $path -Force
    } catch {
        Write-Warning "Failed to save bookmarks: $_"
    }
}

function mark {
    param(
        [Parameter(Mandatory)][string]$Name
    )
    $map = Get-ProfileBookmarks
    $map[$Name] = (Get-Location).Path
    Save-ProfileBookmarks -Bookmarks $map
    Write-Host "Marked '$Name' -> $($map[$Name])" -ForegroundColor Green
}

function go {
    param(
        [Parameter(Mandatory)][string]$Name
    )
    $map = Get-ProfileBookmarks
    if ($map.ContainsKey($Name)) {
        Set-Location $map[$Name]
    } else {
        Write-Warning "No bookmark named '$Name'."
    }
}

# =========================
# E. File helpers / explorer
# =========================

function fo {
    param([string]$Path)
    if (-not $Path) { $Path = (Get-Location).Path }
    if (-not (Test-Path $Path)) {
        Write-Warning "Path not found: $Path"
        return
    }
    Start-Process explorer.exe $Path
}

function codeo {
    param([string]$Path)
    if (-not $Path) { $Path = (Get-Location).Path }
    if (-not (Test-Path $Path)) {
        Write-Warning "Path not found: $Path"
        return
    }
    if (Get-Command -Name 'code' -ErrorAction SilentlyContinue) {
        code $Path
    } else {
        Write-Warning "VS Code ('code') not found on PATH."
    }
}

function open {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Warning "Path not found: $Path"
        return
    }
    Start-Process $Path
}

function recent {
    param(
        [int]$Count = 10
    )
    Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $Count |
        Select-Object LastWriteTime, Length, FullName
}

function big {
    param(
        [int]$Count = 10
    )
    Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First $Count |
        Select-Object Length, LastWriteTime, FullName
}

# =========================
# F. Cleanup & sysadmin
# =========================

function Invoke-SystemCleanup {
    Write-Host "Cleaning temp folders..." -ForegroundColor Yellow
    $paths = @(
        $env:TEMP,
        $env:TMP,
        "$env:SystemRoot\Temp"
    )
    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) {
            try {
                Remove-Item -Path (Join-Path $p '*') -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    Write-Host "System cleanup finished (basic temp folders)." -ForegroundColor Green
}

function restart-explorer {
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

function fix-network {
    Write-Host "Running basic network repair (ipconfig /flushdns, netsh winsock reset)..." -ForegroundColor Yellow
    ipconfig /flushdns | Out-Null
    try { netsh winsock reset | Out-Null } catch {}
    Write-Host "Network repair commands executed. You may need to restart." -ForegroundColor Green
}

function Start-ProfileSafeMode {
    Write-Host "Starting PowerShell in safe mode (no profile)..." -ForegroundColor Yellow
    Start-Process pwsh -ArgumentList '-NoProfile'
}

# =========================
# G. Fun & vibes
# =========================

$script:ProfileVibesUnlocked = $false

function unlock {
    $script:ProfileVibesUnlocked = $true
    Write-Host "✨ Easter eggs unlocked. Try: fortune, vibes, matrix, rainbow 'text'" -ForegroundColor Magenta
}

function fortune {
    $lines = @(
        "You didn't break it. It was *already* cursed.",
        "Today is a good day to git commit.",
        "Your future shell is bright and strongly typed.",
        "Behind every error message is a story of growth.",
        "Take a stretch break. Your wrists will thank you."
    )
    $i = Get-Random -Minimum 0 -Maximum $lines.Count
    Write-Host $lines[$i] -ForegroundColor Cyan
}

function vibes {
    if (-not $script:ProfileVibesUnlocked) {
        Write-Host "Vibes locked. Run 'unlock' first. 🔒" -ForegroundColor DarkYellow
        return
    }
    $lines = @(
        "You are absolutely crushing this, even if it feels messy.",
        "Your future dev setup would give past-you goosebumps.",
        "You've debugged worse. You've GOT this.",
        "Tiny steps count. This one definitely did.",
        "Your attention to detail is a superpower, not a bug."
    )
    $i = Get-Random -Minimum 0 -Maximum $lines.Count
    Write-Host $lines[$i] -ForegroundColor Magenta
}

function rainbow {
    param(
        [Parameter(Mandatory)][string]$Text
    )
    $colors = @('Red','Yellow','Green','Cyan','Blue','Magenta')
    $chars  = $Text.ToCharArray()
    for ($i = 0; $i -lt $chars.Count; $i++) {
        $c = $colors[$i % $colors.Count]
        Write-Host -NoNewline $chars[$i] -ForegroundColor $c
    }
    Write-Host ""
}

function matrix {
    param(
        [int]$Lines = 30
    )
    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for ($i = 0; $i -lt $Lines; $i++) {
        $line = -join (1..80 | ForEach-Object {
            $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        })
        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 80
    }
}

function global:Invoke-MatrixRain {
    Clear-Host
    $chars = "01".ToCharArray()
    for ($i=0; $i -lt 200; $i++) {
        Write-Host ($chars | Get-Random) -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 5
        if ($i % 80 -eq 0) { Write-Host "" }
    }
}

function global:Invoke-NeonWave {
    Clear-Host
    $colors = @("`e[95m","`e[96m","`e[94m","`e[91m")
    for ($i=0; $i -lt 60; $i++) {
        $c = $colors[$i % $colors.Count]
        Write-Host (" " * ($i % 30) + "$c~~~~~$NeonReset")
        Start-Sleep -Milliseconds 30
    }
}
# =========================
# H. Cyberpunk FX & Prompt
# =========================

function global:Invoke-MatrixRain {
    param(
        [int]$Lines = 40,
        [int]$Width = 80,
        [int]$DelayMs = 60
    )

    Clear-Host
    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
    $esc   = [char]27

    for ($i = 0; $i -lt $Lines; $i++) {
        $line = -join (1..$Width | ForEach-Object {
            $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        })
        # Bright green text
        Write-Host "$esc[92m$line$esc[0m"
        Start-Sleep -Milliseconds $DelayMs
    }
}

function global:Invoke-NeonWave {
    param(
        [int]$Lines = 30,
        [int]$Width = 60
    )

    Clear-Host
    $esc = [char]27
    $colors = @("$esc[95m", "$esc[96m", "$esc[94m", "$esc[91m")

    for ($i = 0; $i -lt $Lines; $i++) {
        $offset = [int](15 * [Math]::Sin($i / 3.0))
        if ($offset -lt 0) { $offset = 0 }

        $color = $colors[$i % $colors.Count]
        $wave  = "~" * 10
        Write-Host (" " * $offset + $color + $wave + $esc + "[0m")
        Start-Sleep -Milliseconds 50
    }
}

function global:Invoke-RippleWave {
    param(
        [int]$Radius = 15
    )

    Clear-Host
    $esc = [char]27
    $colors = @("$esc[96m", "$esc[95m")
    for ($r = 1; $r -le $Radius; $r++) {
        $color = $colors[$r % $colors.Count]
        $padding = " " * ($Radius - $r)
        $body    = "~" * ($r * 2)
        Write-Host ($padding + $color + $body + $esc + "[0m")
        Start-Sleep -Milliseconds 50
    }
}

function global:Invoke-TypingBanner {
    param(
        [string]$Text = "BOOTING OZ NEON SYSTEM...",
        [int]$DelayMs = 40
    )

    Clear-Host
    $esc = [char]27
    $chars = $Text.ToCharArray()
    foreach ($c in $chars) {
        Write-Host -NoNewline "$esc[95m$c$esc[0m"
        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Host ""
}

function global:Invoke-CyberCursor {
    param(
        [int]$DurationSeconds = 5
    )

    $esc = [char]27
    $frames = @("|", "/", "-", "\")
    $sw = [Diagnostics.Stopwatch]::StartNew()

    while ($sw.Elapsed.TotalSeconds -lt $DurationSeconds) {
        foreach ($f in $frames) {
            Write-Host "`r$esc[96m$f$esc[0m" -NoNewline
            Start-Sleep -Milliseconds 80
        }
    }
    Write-Host "`r " -NoNewline
    Write-Host ""
}

function global:Show-NeonBorder {
    param(
        [string]$Text = "OZ NEON SYSTEM",
        [switch]$Gradient
    )

    $esc = [char]27
    $line = "─" * ($Text.Length + 4)

    if ($Gradient) {
        $colors = @("$esc[95m","$esc[96m","$esc[94m","$esc[91m")
        $top = ""
        for ($i = 0; $i -lt $line.Length; $i++) {
            $top += $colors[$i % $colors.Count] + $line[$i]
        }
        Write-Host $top + "$esc[0m"
        Write-Host "$esc[95m│$esc[0m $Text $esc[96m│$esc[0m"
        $bottom = ""
        for ($i = 0; $i -lt $line.Length; $i++) {
            $bottom += $colors[($i + 2) % $colors.Count] + $line[$i]
        }
        Write-Host $bottom + "$esc[0m"
    } else {
        Write-Host "┌$line┐"
        Write-Host "│  $Text  │"
        Write-Host "└$line┘"
    }
    Write-Host ""
}

function global:Set-CyberpunkPrompt {
    # cyberpunk inline prompt (doesn't rely on oh-my-posh)
    $esc = [char]27
    function global:prompt {
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
}

function global:Set-DefaultPrompt {
    function global:prompt {
        Invoke-Profile-PostInit
        $cwd = (Get-Location).Path
        if ($global:IsAdmin) { "[$cwd] # " } else { "[$cwd] $ " }
    }
    Write-Host "Default prompt restored." -ForegroundColor Yellow
}

# =========================
# I. Per-project neon vibes
# =========================

function global:Set-ProjectNeonTheme {
    $cwd = Get-Location
    $markers = @{
        "Node.js" = @("package.json","pnpm-lock.yaml","yarn.lock","bun.lockb")
        "Python"  = @("pyproject.toml","requirements.txt","Pipfile")
        "Rust"    = @("Cargo.toml")
        "Go"      = @("go.mod")
        "DotNet"  = @("*.csproj","*.sln")
    }

    $match = $null

    foreach ($k in $markers.Keys) {
        foreach ($m in $markers[$k]) {
            if (Get-ChildItem -Path $cwd.Path -Filter $m -ErrorAction SilentlyContinue) {
                $match = $k
                break
            }
        }
        if ($match) { break }
    }

    $esc = [char]27
    if (-not $match) {
        Write-Host "$esc[90mNo specific project type detected. Using neutral neon.$esc[0m"
        return
    }

    switch ($match) {
        "Node.js" { Write-Host "$esc[95m[NEON]$esc[0m Node.js project detected → magenta/teal vibes." }
        "Python"  { Write-Host "$esc[96m[NEON]$esc[0m Python project detected → cyan/blue vibes." }
        "Rust"    { Write-Host "$esc[93m[NEON]$esc[0m Rust project detected → amber/orange vibes." }
        "Go"      { Write-Host "$esc[92m[NEON]$esc[0m Go project detected → green vibes." }
        "DotNet"  { Write-Host "$esc[94m[NEON]$esc[0m .NET project detected → blue/purple vibes." }
    }
}

# =========================
# J. Tiny PowerShell "apps"
# =========================

function global:Start-TaskApp {
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

function global:Start-GitApp {
    if (-not (Test-Path ".git")) {
        Write-Warning "No .git folder here. Not a git repo."
        return
    }

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

function global:Start-FileApp {
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
# ===============================
#  RAVEN SHADOW EXTENSIONS (FX)
# ===============================

function Show-NeonBorder {
    param(
        [string]$Text = "RAVEN TERMINAL",
        [ConsoleColor]$Color = "Magenta"
    )

    $line = "─" * ($Text.Length + 4)
    Write-Host "╭$line╮" -ForegroundColor $Color
    Write-Host ("│  {0}  │" -f $Text) -ForegroundColor $Color
    Write-Host "╰$line╯" -ForegroundColor $Color
}

function Show-MatrixRain {
    param(
        [int]$Lines = 20,
        [int]$Width = 60
    )

    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for ($i = 0; $i -lt $Lines; $i++) {
        $line = -join (1..$Width | ForEach-Object {
            $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        })
        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 50
    }
}

function Show-WaveLines {
    param(
        [int]$Lines = 10,
        [int]$Width = 50
    )

    for ($i = 0; $i -lt $Lines; $i++) {
        $offset = [int](10 * [math]::Sin($i / 2.0))
        $spaces = " " * ([math]::Max($offset,0))
        $wave = "~" * $Width
        Write-Host "$spaces$wave" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 60
    }
}

# ===============================
#  RAVEN SHADOW UTILS
# ===============================

function Shadow-HashFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet("SHA256","SHA1","MD5")] [string]$Algorithm = "SHA256"
    )

    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return
    }

    Get-FileHash -Path $Path -Algorithm $Algorithm
}

function Shadow-Ports {
    Get-NetTCPConnection | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess |
        Sort-Object LocalPort
}

function Shadow-Processes {
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 |
        Format-Table -AutoSize
}

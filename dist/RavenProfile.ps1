<#
  RAVEN SINGLE-FILE BUILD
  Generated: 2026-05-22 18:10:09
  Source: C:\Users\ozzium\Documents\GitHub\powershell-profile\profile
#>


# ------------------------------
# BEGIN: config.ps1
# ------------------------------
# Central configuration object for the profile

if (-not $global:PSProfileConfig) {
    $global:PSProfileConfig = [pscustomobject]@{
        TimeFilePath   = "$HOME\.ps_profile_last_update"
        RepoRootRaw = 'https://raw.githubusercontent.com/ozzium/powershell-profile'
        UpdateInterval = 7          # days; -1 = always check, big number = rarely
        Editor         = $null      # will auto-detect if null
        Debug          = $false     # set $true to skip update checks etc.
    }
}
# ===============================
# Raven Theme Persistence
# ===============================

# Cross-platform config location (user-local; NOT in git)
$global:RavenConfigPath = Join-Path $HOME ".raven-profile.json"

function Get-RavenConfig {
    if (-not (Test-Path $global:RavenConfigPath)) {
        return @{}
    }

    try {
        $raw = Get-Content -Path $global:RavenConfigPath -Raw
        if (-not $raw.Trim()) { return @{} }
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop

        # Convert PSObject -> Hashtable for easy indexing
        $ht = @{}
        foreach ($p in $obj.PSObject.Properties) { $ht[$p.Name] = $p.Value }
        return $ht
    } catch {
        return @{}
    }
}

function Save-RavenConfig([hashtable]$cfg) {
    try {
        $cfg | ConvertTo-Json -Depth 6 | Set-Content -Path $global:RavenConfigPath -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

# Load theme preference (default is cobalt2)
$cfg = Get-RavenConfig
if ($cfg.ContainsKey("Theme") -and $cfg.Theme) {
    $global:RavenTheme = [string]$cfg.Theme
} else {
    $global:RavenTheme = "cobalt2"
}

# Theme preference (oh-my-posh theme name without .omp.json)
if (-not $global:RavenTheme) { $global:RavenTheme = "cobalt2" }

# ------------------------------
# END:   config.ps1
# ------------------------------

# ------------------------------
# BEGIN: utils.ps1
# ------------------------------
# Basic file helpers
function touch { param($File) "" | Out-File -FilePath $File -Encoding ASCII }
function nf    { param($Name) New-Item -ItemType File -Path . -Name $Name -Force | Out-Null }
function mkcd  { param($Dir)  New-Item -ItemType Directory -Path $Dir -Force | Out-Null; Set-Location $Dir }

function ff {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}

# Navigation shortcuts
function docs {
    $d = [Environment]::GetFolderPath('MyDocuments')
    if (-not $d) { $d = "$HOME\Documents" }
    Set-Location -Path $d
}
function dtop {
    $d = [Environment]::GetFolderPath('Desktop')
    if (-not $d) { $d = "$HOME\Desktop" }
    Set-Location -Path $d
}

# Processes
function k9    { param([string]$Name) Stop-Process -Name $Name -ErrorAction SilentlyContinue }
function sysinfo { Get-ComputerInfo }

# DNS / Network
function flushdns {
    try {
        Clear-DnsClientCache
        Write-Host "DNS cache cleared." -ForegroundColor Green
    } catch {
        Write-Warning "Could not clear DNS cache: $_"
    }
}

function Get-PubIP {
    try {
        (Invoke-WebRequest http://ifconfig.me/ip -UseBasicParsing -TimeoutSec 5).Content.Trim()
    } catch {
        Write-Warning "Failed to obtain public IP: $_"
    }
}

# Clipboard
function cpy { param([string]$Text) Set-Clipboard -Value $Text }
function pst { Get-Clipboard }

# Trash to Recycle Bin
function trash {
    param([Parameter(Mandatory)][string]$Path)

    try {
        $resolved = (Resolve-Path -Path $Path -ErrorAction Stop).Path
        $item     = Get-Item -LiteralPath $resolved
        $parent   = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }

        $shell    = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parent).ParseName($item.Name)
        $shellItem.InvokeVerb('delete')

        Write-Host "Item '$resolved' moved to Recycle Bin." -ForegroundColor Green
    } catch {
        Write-Warning "trash failed for '$Path': $_"
    }
}

# Uptime
function uptime {
    try {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $bootTime = Get-Uptime -Since
        } else {
            $lastBootRaw = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime    = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBootRaw)
        }

        $uptime = (Get-Date) - $bootTime
        Write-Host ("System started on: {0}" -f $bootTime) -ForegroundColor DarkGray
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f `
            $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds) -ForegroundColor Blue
    } catch {
        Write-Error "Failed to calculate uptime: $_"
    }
}
function global:reload-profile {
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    . $PROFILE
}
# Git shortcuts
function gs    { git status }
function ga    { git add . }
function gpush { git push }
function gpull { git pull }

function gc {
    param([Parameter(Mandatory)][string]$Message)
    git commit -m $Message
}

function gcom {
    param([Parameter(Mandatory)][string]$Message)
    git add .
    git commit -m $Message
}

function reload-profile {
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    & $PROFILE
}

function lazyg {
    param([Parameter(Mandatory)][string]$Message)
    git add .
    git commit -m $Message
    git push
}

# Hastebin uploader (fixed)
function hb {
    param(
        [Parameter(Mandatory)][string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "File path does not exist: $FilePath"
        return
    }

    try {
        $content  = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $response = Invoke-RestMethod -Uri "https://hastebin.com/documents" -Method POST -Body $content -ErrorAction Stop

        if ($response -and $response.key) {
            Write-Output "https://hastebin.com/$($response.key)"
        } else {
            Write-Warning "Unexpected response from hastebin: $response"
        }
    } catch {
        Write-Error "Failed to upload to hastebin: $_"
    }
}

# Reload profile quickly
function Update-Profile {
    & $PROFILE
}
function global:reload-profile {
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    . $PROFILE
}

# ------------------------------
# END:   utils.ps1
# ------------------------------

# ------------------------------
# BEGIN: update.ps1
# ------------------------------
function _Should-Run-UpdateChecks {
    param([int]$IntervalDays)

    if ($global:PSProfileConfig.Debug) { return $false }
    if ($IntervalDays -eq -1) { return $true }

    if (-not (Test-Path $global:PSProfileConfig.TimeFilePath)) { return $true }

    try {
        $last = Get-Content -Path $global:PSProfileConfig.TimeFilePath -ErrorAction Stop
        $lastDate = [datetime]::ParseExact($last.Trim(), 'yyyy-MM-dd', $null)
        return ((Get-Date).Date - $lastDate.Date).TotalDays -gt $IntervalDays
    } catch {
        return $true
    }
}

function Update-Profile {
    if (Get-Command -Name "Update-Profile_Override" -ErrorAction SilentlyContinue) {
        Update-Profile_Override
        return
    }

    if (-not $global:PSProfileConfig.RepoRootRaw) {
        Write-Warning "RepoRootRaw is not configured."
        return
    }

    $url  = "$($global:PSProfileConfig.RepoRootRaw)/powershell-profile/profile/Microsoft.PowerShell_profile.ps1"
    $temp = Join-Path $env:TEMP 'Microsoft.PowerShell_profile.ps1'

    try {
        Invoke-RestMethod -Uri $url -OutFile $temp -ErrorAction Stop
    } catch {
        Write-Warning "Profile update failed: $_"
        return
    }

    if (-not (Test-Path $PROFILE)) {
        Copy-Item -Path $temp -Destination $PROFILE
        Write-Host "Profile installed. Restart shell." -ForegroundColor Magenta
        return
    }

    $old = Get-FileHash -Path $PROFILE
    $new = Get-FileHash -Path $temp

    if ($old.Hash -ne $new.Hash) {
        Copy-Item -Path $temp -Destination $PROFILE -Force
        Write-Host "Profile updated. Restart shell." -ForegroundColor Magenta
    } else {
        Write-Host "Profile is up to date." -ForegroundColor Green
    }

    Remove-Item $temp -ErrorAction SilentlyContinue
}

function Update-PowerShell {
    if (Get-Command -Name "Update-PowerShell_Override" -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override
        return
    }

    if ($global:PSProfileConfig.Debug) {
        Write-Verbose "Skipping Update-PowerShell in debug mode"
        return
    }

    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan

        $currentVersion = [version]$PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl   = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
        $latestReleaseInfo = $null

        try {
            $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl -TimeoutSec 10 -ErrorAction Stop
        } catch {
            Write-Warning "Could not query GitHub API for PowerShell releases: $_"
        }

        $latestVersion = $null
        if ($latestReleaseInfo -and $latestReleaseInfo.tag_name) {
            $tag = $latestReleaseInfo.tag_name.TrimStart('v')
            try { $latestVersion = [version]$tag } catch { $latestVersion = $null }
        }

        $updateNeeded = $false
        if ($latestVersion -and ($currentVersion -lt $latestVersion)) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell from $currentVersion to $latestVersion..." -ForegroundColor Yellow
            try {
                Start-Process -FilePath 'powershell.exe' `
                    -ArgumentList "-NoProfile -Command winget upgrade --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" `
                    -Wait -NoNewWindow -ErrorAction Stop
                Write-Host "PowerShell has been updated. Please restart your shell." -ForegroundColor Magenta
            } catch {
                Write-Error "Failed to update PowerShell via winget: $_"
            }
        } else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor Green
        }

    } catch {
        Write-Warning "Failed to determine PowerShell update status: $_"
    }
}

# Run checks periodically, not every launch
if (_Should-Run-UpdateChecks -IntervalDays $global:PSProfileConfig.UpdateInterval) {
    Update-Profile
    Update-PowerShell
    (Get-Date -Format 'yyyy-MM-dd') | Out-File -FilePath $global:PSProfileConfig.TimeFilePath -Force
}

# ------------------------------
# END:   update.ps1
# ------------------------------

# ------------------------------
# BEGIN: completions.ps1
# ------------------------------
# Custom completions for git / npm / deno

$script:PSProfile_CustomCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $customCompletions = @{
        'git'  = @('status','add','commit','push','pull','clone','checkout')
        'npm'  = @('install','start','run','test','build')
        'deno' = @('run','compile','bundle','test','lint','fmt','cache','info','doc','upgrade')
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_,$_, 'ParameterValue', $_)
            }
    }
}

Register-ArgumentCompleter -Native -CommandName git,npm,deno -ScriptBlock $script:PSProfile_CustomCompleter

# ------------------------------
# END:   completions.ps1
# ------------------------------

# ------------------------------
# BEGIN: appearance.ps1
# ------------------------------
# PSReadLine settings
$PSReadLineOptions = @{
    EditMode                    = 'Windows'
    HistoryNoDuplicates         = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource            = 'History'
    PredictionViewStyle         = 'ListView'
    BellStyle                   = 'None'
}

try {
    Set-PSReadLineOption @PSReadLineOptions
} catch {
    # PSReadLine may not be available in some hosts
}

# Key handlers
try {
    Set-PSReadLineKeyHandler -Key UpArrow           -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow         -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab               -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d'        -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w'        -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d'         -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'  -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z'        -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y'        -Function Redo

    # Filter out sensitive history
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password','secret','token','apikey','connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match $_ }
        return ($null -eq $hasSensitive)
    }
} catch {}

# Oh-my-posh theme helpers
function Get-Theme {
    if (Get-Command -Name "Get-Theme_Override" -ErrorAction SilentlyContinue) {
        Get-Theme_Override
        return
    }

    if (-not (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue)) {
        Write-Verbose "oh-my-posh not installed."
        return
    }

    $themeName = if ($global:RavenTheme) { $global:RavenTheme } else { "cobalt2" }
    $themeUrl  = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$themeName.omp.json"

    try {
        oh-my-posh init pwsh --config $themeUrl | Invoke-Expression
        Write-Host ("Using theme: {0} (oh-my-posh)" -f $themeName) -ForegroundColor Cyan
    } catch {
        Write-Warning ("oh-my-posh init failed: {0}" -f $_.Exception.Message)
    }
}


    $themes = @{
        "cobalt2"   = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
        "jandedo"   = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json"
        "paradox"   = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json"
        "tokyo"     = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/tokyonight_storm.omp.json"
        "nightowl"  = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/night-owl.omp.json"
        "agnoster"  = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnoster.omp.json"
        "powerline" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerline.omp.json"
    }

    $key = $Name.ToLower()
    if (-not $themes.ContainsKey($key)) {
        Write-Warning "Unknown theme '$Name'. Available: $($themes.Keys -join ', ')"
        return
    }

    $url = $themes[$key]
    try {
        oh-my-posh init pwsh --config $url | Invoke-Expression
        Write-Host ("Theme set: {0}" -f $key) -ForegroundColor Cyan
    } catch {
        Write-Warning ("Theme init failed: {0}" -f $_.Exception.Message)
    }
}

# ===============================
# Fog / Drift Prompt (Optional)
# ===============================

# Global toggle
if (-not $global:RavenFogEnabled) { $global:RavenFogEnabled = $false }

# Internal fog state
$script:RavenFogIndex = 0
$script:RavenFogFrames = @(
    "  .   ",
    "   .  ",
    "    . ",
    "   .  ",
    "  .   ",
    " .    "
)

function Enable-FogPrompt {
    $global:RavenFogEnabled = $true
    Write-Host "🌫️ Fog prompt enabled." -ForegroundColor Magenta
}

function Disable-FogPrompt {
    $global:RavenFogEnabled = $false
    Write-Host "🌫️ Fog prompt disabled." -ForegroundColor DarkGray
}

function Toggle-FogPrompt {
    if ($global:RavenFogEnabled) { Disable-FogPrompt } else { Enable-FogPrompt }
}

# A helper that returns a tiny drifting fog string
function Get-RavenFog {
    $frame = $script:RavenFogFrames[$script:RavenFogIndex % $script:RavenFogFrames.Count]
    $script:RavenFogIndex++
    return $frame
}
# Wrap existing prompt once (safe)
if (-not $script:RavenPromptWrapped) {
    $script:RavenPromptWrapped = $true

    $origPrompt = (Get-Command prompt -ErrorAction SilentlyContinue).ScriptBlock

    function global:prompt {
        # keep your normal behavior
        $base = & $origPrompt

        # If oh-my-posh is active, it already renders prompt; base may be empty.
        # We'll only add fog if enabled, and we won't spam if base is null.
        if ($global:RavenFogEnabled) {
            $esc = [char]27
            $fog = Get-RavenFog

            # subtle fog color (ANSI grey)
            $fogPart = "$esc[38;5;245m$fog$esc[0m"

            return "$base$fogPart "
        }

        return $base
    }
}
# ===============================
# Fog Drift (Idle Animation)
# ===============================

if (-not $global:RavenFogEnabled) { $global:RavenFogEnabled = $false }

# Internal state
$script:RavenFogTimer = $null
$script:RavenFogFrames = @("·", "•", "∙", "○", "◌", "◍", "◎")
$script:RavenFogWave = @(
  "        ",
  "   .    ",
  "    .   ",
  "     .  ",
  "    .   ",
  "   .    ",
  "  .     ",
  " .      ",
  ".       ",
  " .      ",
  "  .     "
)
$script:RavenFogIndex = 0

function Stop-RavenFog {
    $global:RavenFogEnabled = $false

    if ($script:RavenFogTimer) {
        try {
            $script:RavenFogTimer.Stop()
            $script:RavenFogTimer.Dispose()
        } catch {}
        $script:RavenFogTimer = $null
    }

    # Clear the fog line (best-effort)
    try {
        $esc = [char]27
        Write-Host "$esc[1A$esc[2K$esc[1B" -NoNewline
    } catch {}

    Write-Host "🌫️ Fog drift stopped." -ForegroundColor DarkGray
}

function Start-RavenFog {
    # Avoid double-start
    if ($script:RavenFogTimer) { return }

    $global:RavenFogEnabled = $true

    # Use a .NET timer (lightweight)
    $timer = New-Object System.Timers.Timer
    $timer.Interval = 220   # ms (low CPU)
    $timer.AutoReset = $true

    Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier "RavenFogTick" -Action {
        if (-not $global:RavenFogEnabled) { return }

        try {
            $esc = [char]27

            $i = $script:RavenFogIndex
            $script:RavenFogIndex++

            $wave = $script:RavenFogWave[$i % $script:RavenFogWave.Count]
            $dot  = $script:RavenFogFrames[$i % $script:RavenFogFrames.Count]

            # Build a subtle fog ribbon (grey)
            $fog = "$wave$dot$wave"

            # Cursor-save, move up one line, clear it, print fog, restore cursor
            # This prints ABOVE the current input line so it won't fight oh-my-posh.
            $grey = "$esc[38;5;245m"
            $reset = "$esc[0m"

            # Save cursor position
            [Console]::Write("$esc[s")
            # Move up 1 line and clear that line
            [Console]::Write("$esc[1A$esc[2K")
            # Print fog line
            [Console]::Write("$grey$fog$reset")
            # Restore cursor
            [Console]::Write("$esc[u")
        } catch {
            # If ANSI cursor ops not supported, silently ignore
        }
    } | Out-Null

    $timer.Start()
    $script:RavenFogTimer = $timer

    Write-Host "🌫️ Fog drift started. (Run Stop-RavenFog to stop)" -ForegroundColor Magenta
}
# ===============================
# Fog Drift (PSReadLine repaint)
# ===============================

if (-not $global:RavenFogEnabled) { $global:RavenFogEnabled = $false }

$script:RavenFogFrames = @("·", "•", "∙", "○", "◌", "◍", "◎")
$script:RavenFogWave = @(
  "  ", "   ", "    ", "     ", "    ", "   ", "  ", " "
)
$script:RavenFogIndex = 0
$script:RavenFogJobRunning = $false

function Get-RavenFogGlyph {
    $i = $script:RavenFogIndex
    $script:RavenFogIndex++

    $dot  = $script:RavenFogFrames[$i % $script:RavenFogFrames.Count]
    $pad  = $script:RavenFogWave[$i % $script:RavenFogWave.Count]

    return "$pad$dot$pad"
}

function Start-RavenFog {
    if ($script:RavenFogJobRunning) { return }
    $global:RavenFogEnabled = $true
    $script:RavenFogJobRunning = $true

    Write-Host "🌫️ Fog drift started (PSReadLine repaint)." -ForegroundColor Magenta

    # Background repaint loop using a job in the same process (safe-ish)
    Start-ThreadJob -Name "RavenFog" -ScriptBlock {
        while ($global:RavenFogEnabled) {
            try {
                # repaint current input line (PSReadLine)
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            } catch {}
            Start-Sleep -Milliseconds 250
        }
    } | Out-Null
}

function Stop-RavenFog {
    $global:RavenFogEnabled = $false
    $script:RavenFogJobRunning = $false

    # Stop the thread job if present
    try {
        Get-Job -Name "RavenFog" -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
    } catch {}

    Write-Host "🌫️ Fog drift stopped." -ForegroundColor DarkGray
}

function Toggle-FogPrompt {
    if ($global:RavenFogEnabled) { Stop-RavenFog } else { Start-RavenFog }
}

function Toggle-FogPrompt {
    if ($global:RavenFogEnabled) { Stop-RavenFog } else { Start-RavenFog }
}
# ===============================
# Fog Drift (Idle Animation)
# Uses PSReadLine ForceRepaint (no ANSI cursor ops needed)
# ===============================

if (-not $global:RavenFogEnabled) { $global:RavenFogEnabled = $false }

$script:RavenFogTimer = $null
$script:RavenFogIndex = 0
$script:RavenFogFrames = @("·","•","∙","○","◌","◍","◎")
$script:RavenFogPad = @(""," ","  ","   ","  "," ","")

function Get-RavenFogGlyph {
    $i = $script:RavenFogIndex
    $script:RavenFogIndex++

    $dot = $script:RavenFogFrames[$i % $script:RavenFogFrames.Count]
    $pad = $script:RavenFogPad[$i % $script:RavenFogPad.Count]
    return "$pad$dot$pad"
}

function Start-RavenFog {
    if ($script:RavenFogTimer) { return }

    # PSReadLine must be loaded
    if (-not ([type]::GetType("Microsoft.PowerShell.PSConsoleReadLine", $false))) {
        try { Import-Module PSReadLine -ErrorAction Stop } catch {
            Write-Warning "PSReadLine not available in this host."
            return
        }
    }

    $global:RavenFogEnabled = $true

    $timer = New-Object System.Timers.Timer
    $timer.Interval = 250
    $timer.AutoReset = $true

    Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier "RavenFogTick" -Action {
        if (-not $global:RavenFogEnabled) { return }
        try {
            # bump the fog frame and repaint the line
            $null = Get-RavenFogGlyph
            [Microsoft.PowerShell.PSConsoleReadLine]::ForceRepaint()
        } catch { }
    } | Out-Null

    $timer.Start()
    $script:RavenFogTimer = $timer

    Write-Host "🌫️ Fog drift started." -ForegroundColor Magenta
}

function Stop-RavenFog {
    $global:RavenFogEnabled = $false

    if ($script:RavenFogTimer) {
        try {
            $script:RavenFogTimer.Stop()
            $script:RavenFogTimer.Dispose()
        } catch {}
        $script:RavenFogTimer = $null
    }

    try { Unregister-Event -SourceIdentifier "RavenFogTick" -ErrorAction SilentlyContinue } catch {}
    try { Remove-Event -SourceIdentifier "RavenFogTick" -ErrorAction SilentlyContinue } catch {}

    try { [Microsoft.PowerShell.PSConsoleReadLine]::ForceRepaint() } catch {}

    Write-Host "🌫️ Fog drift stopped." -ForegroundColor DarkGray
}

function Toggle-FogPrompt {
    if ($global:RavenFogEnabled) { Stop-RavenFog } else { Start-RavenFog }
}

# ------------------------------
# END:   appearance.ps1
# ------------------------------

# ------------------------------
# BEGIN: features.ps1
# ------------------------------
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

function Get-RavenRepoRoot {
    # env points to ...\powershell-profile\profile
    if (-not $env:RAVEN_PROFILE_ROOT) { return $null }

    $profileRoot = (Resolve-Path $env:RAVEN_PROFILE_ROOT -ErrorAction SilentlyContinue)?.Path
    if (-not $profileRoot) { return $null }

    $repoRoot = (Resolve-Path (Join-Path $profileRoot "..") -ErrorAction SilentlyContinue)?.Path
    if ($repoRoot -and (Test-Path (Join-Path $repoRoot ".git"))) { return $repoRoot }

    return $null
}

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
$currentTheme = if ($global:RavenTheme) { $global:RavenTheme } else { "cobalt2" }
    Clear-Host
    Write-Host "THEME ENGINE" -ForegroundColor Magenta
    Write-Host "----------------------------------------" -ForegroundColor DarkGray

   for ($i = 0; $i -lt $themes.Count; $i++) {
    $theme = $themes[$i]
    $marker = if ($theme.Id -eq $currentTheme) { " ⭐ current" } else { "" }

    Write-Host (" [{0}] {1}{2}" -f ($i + 1), $theme.Name, $marker) -ForegroundColor Yellow
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

    # Save preference (persist across sessions)
$global:RavenTheme = $themeId

$cfg = Get-RavenConfig
$cfg["Theme"] = $themeId
$ok = Save-RavenConfig $cfg

if (-not $ok) {
    Write-Warning "Could not save theme preference."
}
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
	$fog = ""
if ($global:RavenFogEnabled) {
    $esc = [char]27
    $fog = "$esc[38;5;245m$(Get-RavenFogGlyph)$esc[0m "
}
return "$fog$existingPromptText"
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

# ------------------------------
# END:   features.ps1
# ------------------------------

# ------------------------------
# BEGIN: fx.ps1
# ------------------------------
# ==========================================
#         N E O N   F X   M E N U
# ==========================================

Set-StrictMode -Off

# Shared neon colors (ANSI)
$script:NeonPink  = "`e[38;5;206m"
$script:NeonBlue  = "`e[38;5;45m"
$script:NeonCyan  = "`e[38;5;51m"
$script:NeonGreen = "`e[38;5;82m"
$script:NeonRed   = "`e[38;5;196m"
$script:Reset     = "`e[0m"

# ---------------------------------------------------------
# Neon Cursor Glow (safe)
# ---------------------------------------------------------
function Enable-NeonCursor {
    try {
        $Host.UI.RawUI.CursorSize = 100
        Write-Host "$script:NeonCyan Neon Cursor Enabled.$script:Reset"
    } catch {
        Write-Warning "Cursor size not supported in this host."
    }
}

function Disable-NeonCursor {
    try {
        $Host.UI.RawUI.CursorSize = 20
        Write-Host "$script:NeonCyan Neon Cursor Disabled.$script:Reset"
    } catch {
        Write-Warning "Cursor size not supported in this host."
    }
}

# ---------------------------------------------------------
# Matrix Rain Mode (FIXED parsing + indexing)
# ---------------------------------------------------------
function Start-MatrixRain {
    Clear-Host
    Write-Host "$script:NeonGreen Matrix mode began… Ctrl+C to stop.$script:Reset"

    $chars = @("0","1","▮","∙","•","░","▓")

    while ($true) {
        $width = Get-Random -Minimum 30 -Maximum 80
        $line  = -join (1..$width | ForEach-Object {
            $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        })

        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)
    }
}

# ---------------------------------------------------------
# Neon Ripple (safe-ish: simple)
# ---------------------------------------------------------
function Start-NeonRipple {
    Write-Host "$script:NeonBlue Ripple began… Ctrl+C to stop.$script:Reset"

    while ($true) {
        $spaces = " " * (Get-Random -Minimum 1 -Maximum 50)
        Write-Host $spaces -ForegroundColor Blue
        Start-Sleep -Milliseconds 60
    }
}

# ---------------------------------------------------------
# Typing Shadow Effect
# ---------------------------------------------------------
function Invoke-ShadowTyping {
    param([string]$Text)

    if (-not $Text) { return }

    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char -ForegroundColor DarkMagenta
        Start-Sleep -Milliseconds (Get-Random -Minimum 12 -Maximum 45)
    }
    Write-Host ""
}

# ---------------------------------------------------------
# Neon Prompt Themes
# ---------------------------------------------------------
function Set-PromptTheme-NeonBlue {
    function global:prompt {
        $cwd = (Get-Location).Path
        "$script:NeonBlue[$cwd] 🦇$script:Reset "
    }
    Write-Host "$script:NeonBlue Neon Blue prompt applied.$script:Reset"
}

function Set-PromptTheme-PastelPink {
    function global:prompt {
        $cwd = (Get-Location).Path
        "$script:NeonPink[$cwd] ✨$script:Reset "
    }
    Write-Host "$script:NeonPink Pastel Pink prompt applied.$script:Reset"
}

function Set-PromptTheme-CyberGreen {
    function global:prompt {
        $cwd = (Get-Location).Path
        "$script:NeonGreen[$cwd] ⚡$script:Reset "
    }
    Write-Host "$script:NeonGreen Cyber Green prompt applied.$script:Reset"
}

function Reset-Prompt {
    Remove-Item function:prompt -ErrorAction SilentlyContinue
    Write-Host "$script:NeonCyan Prompt reset to default.$script:Reset"
}

# ---------------------------------------------------------
# Main Neon FX Menu (loops + real actions)
# ---------------------------------------------------------
function global:Show-NeonFXMenu {
    $exit = $false

    while (-not $exit) {
        Clear-Host
        Write-Host "╭──────────────────────────────╮" -ForegroundColor Magenta
        Write-Host "│     N E O N   F X   M E N U  │" -ForegroundColor Magenta
        Write-Host "├──────────────────────────────┤" -ForegroundColor Magenta
        Write-Host "│ 1) Enable Neon Cursor        │"
        Write-Host "│ 2) Disable Neon Cursor       │"
        Write-Host "│ 3) Water Ripple Waves        │"
        Write-Host "│ 4) Pastel Pink Prompt        │"
        Write-Host "│ 5) Matrix Rain               │"
        Write-Host "│ 6) Neon Blue Prompt          │"
        Write-Host "│ 7) Cyber Green Prompt        │"
        Write-Host "│ 8) Reset Prompt              │"
        Write-Host "│ 9) Exit                      │"
        Write-Host "╰──────────────────────────────╯" -ForegroundColor Magenta

        Write-Host ""
        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" { Enable-NeonCursor; Read-Host "Press Enter..." }
            "2" { Disable-NeonCursor; Read-Host "Press Enter..." }
            "3" { Start-NeonRipple }   # Ctrl+C to stop
            "4" { Set-PromptTheme-PastelPink; Read-Host "Press Enter..." }
            "5" { Start-MatrixRain }   # Ctrl+C to stop
            "6" { Set-PromptTheme-NeonBlue; Read-Host "Press Enter..." }
            "7" { Set-PromptTheme-CyberGreen; Read-Host "Press Enter..." }
            "8" { Reset-Prompt; Read-Host "Press Enter..." }
            "9" { $exit = $true }
            default { }
        }
    }
}

# ------------------------------
# END:   fx.ps1
# ------------------------------

# ------------------------------
# BEGIN: inline.ps1
# ------------------------------
# ===============================
#   RAVEN INLINE AI SUGGESTIONS
# ===============================

function Invoke-RavenInlineSuggestion {
    param([string]$CurrentLine)

    if (-not $CurrentLine -or -not $CurrentLine.Trim()) { return $null }

    $prompt = @"
You are Raven, the AI muse embedded inside this terminal.
Complete or improve the following PowerShell command.
Return ONLY the improved command — no commentary.

Current line:
$CurrentLine
"@

    $resp = Invoke-RavenCore -Prompt $prompt
    if (-not $resp) { return $null }

    $first = $resp -split "`n" | Select-Object -First 1
    return ($first.Trim())
}

Set-PSReadLineKeyHandler -Key "Ctrl+Space" -ScriptBlock {
    param($key, $arg)

    $line = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $s = Invoke-RavenInlineSuggestion -CurrentLine $line

    if ($s) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replaces($line, $s)
    }
}

# ------------------------------
# END:   inline.ps1
# ------------------------------

# ------------------------------
# BEGIN: shadows.ps1
# ------------------------------
# ============================
#    S H A D O W  E X T E N S I O N S
# ============================

# Neon glowing cursor
$Host.UI.RawUI.CursorSize = 100
$Host.PrivateData.ErrorForegroundColor = "Magenta"
$Host.PrivateData.WarningForegroundColor = "DarkMagenta"

function Enable-MatrixRain {
    while ($true) {
        $chars = ("0","1","▮","∙","•")
        $line = -join (1..(Get-Random -Min 30 -Max 70) | ForEach-Object { $chars[Get-Random -Min 0 -Max $chars.Length] })
        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds (Get-Random -Min 20 -Max 120)
    }
}

function Start-NeonRipple {
    while ($true) {
        Write-Host (" " * (Get-Random -Min 1 -Max 50)) -BackgroundColor Black `
            -ForegroundColor Blue
        Start-Sleep -Milliseconds 50
    }
}

# ------------------------------
# END:   shadows.ps1
# ------------------------------

# ------------------------------
# BEGIN: raven.ps1
# ------------------------------
# ===============================
#      R A V E N   C O R E
# ===============================

# ===============================
#        R A V E N   B A N N E R
# ===============================

function Raven-Banner {
@"
██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗
██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║
██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝
      🦇   R A V E N   A W A K E N S   🦇
"@ | Write-Host -ForegroundColor DarkMagenta
}

# Load API key
$env:OPENAI_API_KEY = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")

function Raven-Log {
    param([string]$Content)

    $folder = Join-Path $HOME "Documents\raven-log"
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }

    $file = Join-Path $folder ("log-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $Content | Out-File -FilePath $file -Encoding UTF8
}

function Raven-Remember {
    param([string]$Note)

    $path = Join-Path $HOME "Documents\raven-memory.json"

    # SAFE load
    try {
        if (Test-Path $path -and (Get-Content $path -Raw).Trim()) {
            $raw = Get-Content $path -Raw | ConvertFrom-Json

            # If it's an object (PSCustomObject / PSObject), convert to hashtable
            if ($raw -is [System.Collections.IDictionary] -or
                $raw -is [pscustomobject])
            {
                $memory = @{}
                foreach ($prop in $raw.PSObject.Properties) {
                    $memory[$prop.Name] = $prop.Value
                }
            }
            else {
                # If it's an array or something weird → reset clean
                $memory = @{}
            }
        }
        else {
            $memory = @{}
        }
    }
    catch {
        # JSON error / corruption → reset
        $memory = @{}
    }

    # Add new memory entry
    $id = Get-Date -Format "yyyyMMddHHmmss"
    $memory[$id] = $Note

    # Save clean JSON
    $memory | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8

    Write-Host "🦇 Raven whispers: I'll remember that…" -ForegroundColor DarkMagenta
}


function Invoke-RavenCore {
    param([string]$Prompt)

    if (-not $env:OPENAI_API_KEY) {
        Write-Host "❌ No API key." -ForegroundColor Red
        return
    }

    $memoryPath = Join-Path $HOME "Documents\raven-memory.json"
    $memoryContent = (Test-Path $memoryPath) ? (Get-Content $memoryPath -Raw) : "{}"

    $persona = @"
You are Raven — an elegant, dark, hyper-intelligent muse.
You speak with velvet confidence and playful danger.
You tease, guide, and whisper brilliance in the dark.
"@

    $body = @{
        model    = "gpt-4o-mini"
        messages = @(
            @{ role="system"; content="Memory: $memoryContent" }
            @{ role="system"; content=$persona }
            @{ role="user";   content=$Prompt }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Headers @{ "Authorization"="Bearer $env:OPENAI_API_KEY" } `
            -Method POST -ContentType "application/json" `
            -Body $body

        $text = $response.choices[0].message.content

        Raven-Log -Content $text
        Write-Host "`n🦇 Raven whispers:`n" -ForegroundColor DarkMagenta
        Write-Host $text -ForegroundColor Cyan
        return $text

    } catch {
        Write-Host "❌ Raven stumbled: $_" -ForegroundColor Red
        return $null
    }
}

function raven { param([string[]]$Message) Invoke-RavenCore -Prompt ($Message -join " ") }

# ===============================
#        RAVEN TASK SYSTEM
# ===============================

function Raven-Task {
    param(
        [ValidateSet("add","list","done","clear")] [string]$Action,
        [string]$Text,
        [int]$Id
    )

    $path = Join-Path $HOME "Documents\raven-tasks.json"

    # SAFE LOAD
    try {
        if (Test-Path $path -and (Get-Content $path -Raw).Trim()) {
            $tasks = (Get-Content $path -Raw | ConvertFrom-Json)
        } else {
            $tasks = @()
        }
    } catch {
        $tasks = @()
    }

    switch ($Action) {

        "add" {
            if (-not $Text) {
                Write-Host "❌ Raven: I need a description." -ForegroundColor Red
                return
            }

            $nextId = if ($tasks) { ($tasks.Id | Measure-Object -Maximum).Maximum + 1 } else { 1 }

            $task = [pscustomobject]@{
                Id        = $nextId
                Text      = $Text
                Done      = $false
                CreatedAt = (Get-Date)
            }

            $tasks += $task

            $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8

            Write-Host ("🦇 Raven adds task #{0}: {1}" -f $nextId, $Text) -ForegroundColor DarkMagenta

        }

        "list" {
            if (-not $tasks) {
                Write-Host "🦇 Raven: No tasks yet." -ForegroundColor DarkMagenta
                return
            }
            $tasks | Sort-Object Id | Format-Table Id, Done, Text
        }

        "done" {
            if (-not $Id) {
                Write-Host "❌ Raven: Give me the task ID." -ForegroundColor Red
                return
            }

            $task = $tasks | Where-Object { $_.Id -eq $Id }
            if (-not $task) {
                Write-Host "❌ Raven: No such task." -ForegroundColor Red
                return
            }

            $task.Done = $true
            $task.DoneAt = (Get-Date)

            $tasks | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
            Write-Host "🦇 Raven marks task #$Id complete." -ForegroundColor Green
        }

        "clear" {
            "[]" | Set-Content -Path $path -Encoding UTF8
            Write-Host "🧹 Raven wipes the slate clean." -ForegroundColor DarkMagenta
        }
    }
}

# ===============================
#     PROJECT MODE DETECTION
# ===============================

$global:RavenProjectMode     = "none"
$global:RavenProjectModeIcon = ""

function Update-RavenProjectMode {
    $path = (Get-Location).Path

    if (Test-Path "$path\package.json") {
        $global:RavenProjectMode="Node";    $global:RavenProjectModeIcon="󰎙"; return
    }
    if (Test-Path "$path\requirements.txt") {
        $global:RavenProjectMode="Python";  $global:RavenProjectModeIcon=""; return
    }
    if (Get-ChildItem -Path $path -Filter *.sln -ErrorAction SilentlyContinue) {
        $global:RavenProjectMode="C#";      $global:RavenProjectModeIcon=""; return
    }
    if (Get-ChildItem -Path $path -Filter *.psd1 -ErrorAction SilentlyContinue) {
        $global:RavenProjectMode="PSModule";$global:RavenProjectModeIcon="󰨊"; return
    }
    if (Test-Path "$path\Dockerfile") {
        $global:RavenProjectMode="Docker";  $global:RavenProjectModeIcon="󰡨"; return
    }
    if (Test-Path "$path\.git") {
        $global:RavenProjectMode="GitRepo"; $global:RavenProjectModeIcon=""; return
    }

    $global:RavenProjectMode="none"
    $global:RavenProjectModeIcon=""
}

function Get-RavenGitBranch {
    try {
        $b = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $b) { return $b.Trim() }
    } catch {}
    return $null
}

function Get-RavenPromptSegments {

    Update-RavenProjectMode

    $isAdmin = (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    return [pscustomobject]@{
        IsAdmin  = $isAdmin
        Cwd      = (Get-Location).Path
        Branch   = Get-RavenGitBranch
        Mode     = $global:RavenProjectMode
        ModeIcon = $global:RavenProjectModeIcon
        User     = "$env:USERNAME@$env:COMPUTERNAME"
    }
}

# ===============================
#    INLINE AI SUGGESTIONS
# ===============================

function Invoke-RavenInlineSuggestion {
    param([string]$CurrentLine)

    if (-not $CurrentLine.Trim()) { return $null }

    $prompt = @"
Complete this PowerShell command:

$CurrentLine

Return only the completed command.
"@

    $resp = Invoke-RavenCore -Prompt $prompt
    if (-not $resp) { return $null }

    return ($resp -split "`n")[0].Trim()
}

# ===============================
#        RAVEN DASHBOARD
# ===============================

function global:Raven-Dashboard {
    while ($true) {
        Clear-Host
        Raven-Banner
        Write-Host ""
        Write-Host "╭───────────────────────────────╮"
        Write-Host "│       RAVEN DASHBOARD         │"
        Write-Host "├───────────────────────────────┤"
        Write-Host "│ 1) Chat with Raven            │"
        Write-Host "│ 2) View tasks                 │"
        Write-Host "│ 3) Add task                   │"
        Write-Host "│ 4) Mark task done             │"
        Write-Host "│ 5) Clear tasks                │"
        Write-Host "│ 6) Show memory notes          │"
        Write-Host "│ 7) Add memory note            │"
        Write-Host "│ 8) System snapshot            │"
        Write-Host "│ 9) Exit                       │"
        Write-Host "╰───────────────────────────────╯"
        Write-Host ""
        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host; Raven-Banner
                $q = Read-Host "Speak to Raven"
                if ($q) { raven $q }
                Read-Host "`nEnter to return..."
            }
            "2" { Clear-Host; Raven-Banner; Raven-Task list; Read-Host "`n..." }
            "3" {
                Clear-Host; Raven-Banner
                $t = Read-Host "Task description"
                if ($t) { Raven-Task add -Text $t }
                Read-Host "`n..."
            }
            "4" {
                Clear-Host; Raven-Banner
                $id = Read-Host "Task ID"
                if ($id) { Raven-Task done -Id ([int]$id) }
                Read-Host "`n..."
            }
            "5" { Clear-Host; Raven-Banner; Raven-Task clear; Read-Host "`n..." }
            "6" {
                Clear-Host; Raven-Banner
                $m = Join-Path $HOME "Documents\raven-memory.json"
                if (Test-Path $m) { Get-Content $m | Write-Host }
                else { Write-Host "No memory yet." }
                Read-Host "`n..."
            }
            "7" {
                Clear-Host; Raven-Banner
                $note = Read-Host "Memory note"
                if ($note) { Raven-Remember $note }
                Read-Host "`n..."
            }
            "8" {
                Clear-Host; Raven-Banner
                Write-Host "User: $env:USERNAME@$env:COMPUTERNAME"
                Write-Host "PS:   $($PSVersionTable.PSVersion)"
                Write-Host "CWD:  $((Get-Location).Path)"
                Get-Process | Sort CPU -Descending | Select -First 10 | Format-Table
                Read-Host "`n..."
            }
            "9" { break }
        }
    }
}

# ===============================
#    EXPORT PUBLIC FUNCTIONS
# ===============================

foreach ($fn in @(
    "Raven-Banner",
    "raven",
    "Raven-Task",
    "Raven-Remember",
    "Invoke-RavenInlineSuggestion",
    "Update-RavenProjectMode",
    "Get-RavenPromptSegments",
    "Raven-Dashboard"
)) {
    if (Get-Command $fn -ErrorAction SilentlyContinue) {
        Set-Item "function:\global:$fn" (Get-Command $fn).ScriptBlock -Force
    }
}

Write-Host "✔ Raven Core Loaded" -ForegroundColor DarkMagenta

# --- Ensure `raven` exists (failsafe) ---
if (-not (Get-Command raven -ErrorAction SilentlyContinue)) {
    if (Get-Command Invoke-RavenCore -ErrorAction SilentlyContinue) {
        function global:raven {
            param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Message)
            Invoke-RavenCore -Prompt ($Message -join " ") | Out-Null
        }
    }
}

# ------------------------------
# END:   raven.ps1
# ------------------------------

# ------------------------------
# BEGIN: dashboard.ps1
# ------------------------------
# ====================================
#       R A V E N   D A S H B O A R D
# ====================================

function global:Raven-Dashboard {
    while ($true) {
        Clear-Host
        Raven-Banner
        Write-Host ""
        Write-Host "╭──────────────────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
        Write-Host "│                    RAVEN DASHBOARD                      │" -ForegroundColor DarkMagenta
        Write-Host "├──────────────────────────────────────────────────────────┤" -ForegroundColor DarkMagenta
        Write-Host "│ 1) Chat with Raven                                       │"
        Write-Host "│ 2) Tasks (view/add/done/clear)                           │"
        Write-Host "│ 3) Memory (view/add)                                     │"
        Write-Host "│ 4) Project Mode Info                                     │"
        Write-Host "│ 5) Git Status (if repo)                                  │"
        Write-Host "│ 6) System Snapshot                                       │"
        Write-Host "│ 7) Exit                                                  │"
        Write-Host "╰──────────────────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
        Write-Host ""
        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host
                Raven-Banner
                $q = Read-Host "Ask Raven"
                if ($q) { raven $q }
                Read-Host "`nPress Enter..."
            }

            "2" {
                Clear-Host
                Raven-Banner
                Write-Host "[Tasks Mode]" -ForegroundColor DarkMagenta
                Raven-Task -Action list
                $sub = Read-Host "`n(a)dd  (d)one  (c)lear  (b)ack"
                switch ($sub) {
                    "a" { Raven-Task add (Read-Host "Task") }
                    "d" { Raven-Task done (Read-Host "Id") }
                    "c" { Raven-Task clear }
                }
            }

            "3" {
                Clear-Host
                Raven-Banner
                Write-Host "[Memory Mode]" -ForegroundColor DarkMagenta
                $memPath = Join-Path $HOME "Documents\raven-memory.json"
                if (Test-Path $memPath) {
                    Get-Content $memPath | Write-Host
                }
                $sub = Read-Host "`n(a)dd  (b)ack"
                if ($sub -eq "a") {
                    Raven-Remember (Read-Host "Note")
                }
            }

            "4" {
                Clear-Host
                Raven-Banner
                $info = Get-RavenPromptSegments
                $info | Format-List
                Read-Host "`nPress Enter..."
            }

            "5" {
                Clear-Host
                Raven-Banner
                git status
                Read-Host "`nPress Enter..."
            }

            "6" {
                Clear-Host
                Raven-Banner
                Write-Host "CPU / RAM Snapshot:" -ForegroundColor Cyan
                Get-Process | Sort-Object CPU -Descending | Select-Object -First 12 |
                    Format-Table -AutoSize
                Read-Host "`nPress Enter..."
            }

            "7" { break }
        }
    }
}

# ------------------------------
# END:   dashboard.ps1
# ------------------------------

# ------------------------------
# BEGIN: menu.ps1
# ------------------------------
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


# ------------------------------
# END:   menu.ps1
# ------------------------------

# ------------------------------
# BEGIN: help.ps1
# ------------------------------
function Show-Help {
    $editor = $global:PSProfileConfig.Editor
    Write-Host ""
    Write-Host "PowerShell Profile Help" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Yellow

    Write-Host "Core:" -ForegroundColor Green
    Write-Host "  Update-Profile           - Update this profile from GitHub"
    Write-Host "  Update-PowerShell        - Check and update PowerShell using winget"
    Write-Host "  ep (Edit-Profile)        - Edit your profile with: $editor"
    Write-Host "  reload-profile           - Reload the current profile"

    Write-Host ""
    Write-Host "Git Shortcuts:" -ForegroundColor Green
    Write-Host "  gs                       - git status"
    Write-Host "  ga                       - git add ."
    Write-Host "  gc ""msg""                 - git commit -m ""msg"""
    Write-Host "  gcom ""msg""               - add + commit"
    Write-Host "  lazyg ""msg""              - add + commit + push"
    Write-Host "  gpush / gpull            - git push / pull"

    Write-Host ""
    Write-Host "Filesystem & Misc:" -ForegroundColor Green
    Write-Host "  touch <file>             - create empty file"
    Write-Host "  nf <file>                - new file in current directory"
    Write-Host "  mkcd <dir>               - make directory then cd into it"
    Write-Host "  docs / dtop              - go to Documents / Desktop"
    Write-Host "  ff <name>                - find files matching name"
    Write-Host "  trash <path>             - send file/dir to Recycle Bin"
    Write-Host "  uptime                   - show system uptime"
    Write-Host "  sysinfo                  - show system info"

    Write-Host ""
    Write-Host "Network & Clipboard:" -ForegroundColor Green
    Write-Host "  flushdns                 - clear DNS cache"
    Write-Host "  Get-PubIP                - show public IP address"
    Write-Host "  cpy ""text""               - copy text to clipboard"
    Write-Host "  pst                      - paste from clipboard"

    Write-Host ""
    Write-Host "Utilities:" -ForegroundColor Green
    Write-Host "  hb <file>                - upload file to hastebin and print URL"
    Write-Host "  Get-Theme                - initialize oh-my-posh cobalt2 theme"
    Write-Host "  Switch-Theme [name]      - switch theme (cobalt2 default)"

    Write-Host ""
    Write-Host "Use 'Show-Help' anytime to see this again." -ForegroundColor Yellow
}

# ------------------------------
# END:   help.ps1
# ------------------------------

# ------------------------------
# BEGIN: init.ps1
# ------------------------------
# Admin check (fixed)
$global:IsAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Window title
$adminSuffix = if ($global:IsAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"

try {
  if ((Get-Location).Path -like "C:\Windows\System32*") {
    Set-Location $HOME
  }
} catch {}

# Editor detection (only runs once)
if (-not $global:PSProfileConfig.Editor) {
    $candidates = @('nvim','pvim','vim','vi','code','codium','notepad++','sublime_text')
    foreach ($c in $candidates) {
        if (Get-Command -Name $c -ErrorAction SilentlyContinue) {
            $global:PSProfileConfig.Editor = $c
            break
        }
    }
    if (-not $global:PSProfileConfig.Editor) {
        $global:PSProfileConfig.Editor = 'notepad'
    }
}

Set-Alias -Name vim -Value $global:PSProfileConfig.Editor -ErrorAction SilentlyContinue

function Edit-Profile {
    & $global:PSProfileConfig.Editor $PROFILE
}
Set-Alias -Name ep -Value Edit-Profile -ErrorAction SilentlyContinue

# Lazy one-time init for heavier stuff (themes, icons, zoxide)
$script:ProfilePostInitRegistered = $false

function Invoke-Profile-PostInit {
    if ($script:ProfilePostInitRegistered) { return }
    $script:ProfilePostInitRegistered = $true

    Start-Sleep -Milliseconds 50
# Apply persisted theme once
if (-not $script:RavenThemeApplied) {
    $script:RavenThemeApplied = $true
    if (Get-Command Get-Theme -ErrorAction SilentlyContinue) { Get-Theme }
}
    # Terminal-Icons (optional)
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }

    # oh-my-posh (optional)
    if (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue) {
        try {
            $ompConfig = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json'
            oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
        } catch {
            Write-Warning "oh-my-posh failed to initialize: $_"
        }
    }

    # zoxide (optional)
    if (Get-Command -Name 'zoxide' -ErrorAction SilentlyContinue) {
        try {
            Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
        } catch {
            Write-Warning "zoxide init failed: $_"
        }
    }

    # Optional: auto-load external user functions from modules/Functions
    $funcFolder = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\modules\Functions'
    $funcFolder = (Resolve-Path $funcFolder -ErrorAction SilentlyContinue)?.Path
    if ($funcFolder -and (Test-Path $funcFolder)) {
        $files = Get-ChildItem -Path $funcFolder -Filter *.ps1 -File -ErrorAction SilentlyContinue
        $i = 1
        foreach ($f in $files) {
            try {
                . $f.FullName
                Write-Host "$i : $($f.Name) loaded" -ForegroundColor Yellow -BackgroundColor DarkMagenta
                $i++
            } catch {
                Write-Warning "Failed to load function file $($f.Name): $_"
            }
        }
    }
}

# Prompt uses lazy init
function prompt {
    Invoke-Profile-PostInit
    $cwd = (Get-Location).Path
    if ($global:IsAdmin) { "[$cwd] # " } else { "[$cwd] $ " }
	
}
if (-not $script:RavenFogPromptWrapped) {
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
# Inject fog into the prompt (works with oh-my-posh too)
if (-not $script:RavenFogPromptWrapped) {
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

# ------------------------------
# END:   init.ps1
# ------------------------------


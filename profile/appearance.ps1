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

function Toggle-FogPrompt {
    if ($global:RavenFogEnabled) { Stop-RavenFog } else { Start-RavenFog }
}

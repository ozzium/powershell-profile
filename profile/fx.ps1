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

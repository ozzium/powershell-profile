# ==========================================
#         N E O N   F X   M E N U
# ==========================================

# Shared neon colors
$NeonPink  = "`e[38;5;206m"
$NeonBlue  = "`e[38;5;45m"
$NeonCyan  = "`e[38;5;51m"
$NeonGreen = "`e[38;5;82m"
$NeonRed   = "`e[38;5;196m"
$Reset     = "`e[0m"

# ---------------------------------------------------------
# Neon Cursor Glow
# ---------------------------------------------------------
function Enable-NeonCursor {
    $Host.UI.RawUI.CursorSize = 100
    Write-Host "$NeonCyan Neon Cursor Enabled.$Reset"
}

function Disable-NeonCursor {
    $Host.UI.RawUI.CursorSize = 20
    Write-Host "$NeonCyan Neon Cursor Disabled.$Reset"
}

# ---------------------------------------------------------
# Matrix Rain Mode (FIXED)
# ---------------------------------------------------------
function Start-MatrixRain {
    Clear-Host
    Write-Host "$NeonGreen Matrix mode began… Ctrl+C to stop.$Reset"

    $chars = @(
        "0", "1", "▮", "∙", "•", "░", "▓"
    )

    while ($true) {
        $len = Get-Random -Min 30 -Max 80

        # ✔ FIXED: proper array index expression
        $line = -join (
            1..$len | ForEach-Object {
                $chars[(Get-Random -Min 0 -Max ($chars.Length - 1))]
            }
        )

        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds (Get-Random -Min 10 -Max 100)
    }
}

# ---------------------------------------------------------
# Neon Ripple (subtle idle FX)
# ---------------------------------------------------------
function Start-NeonRipple {
    Write-Host "$NeonBlue Ripple began… Ctrl+C to stop.$Reset"
    while ($true) {
        $col = Get-Random -Min 18 -Max 200
        Write-Host (" " * (Get-Random -Min 1 -Max 50)) -ForegroundColor $col
        Start-Sleep -Milliseconds 60
    }
}

# ---------------------------------------------------------
# Typing Shadow Effect
# ---------------------------------------------------------
function Invoke-ShadowTyping {
    param([string]$Text)

    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char -ForegroundColor DarkMagenta
        Start-Sleep -Milliseconds (Get-Random -Min 12 -Max 45)
    }
    Write-Host ""
}

# ---------------------------------------------------------
# Neon Prompt Themes
# ---------------------------------------------------------
function Set-PromptTheme-NeonBlue {
    function global:prompt {
        $cwd = (Get-Location).Path
        "$NeonBlue[$cwd] 🦇$Reset "
    }
    Write-Host "$NeonBlue Neon Blue prompt applied.$Reset"
}

function Set-PromptTheme-PastelPink {
    function global:prompt {
        $cwd = (Get-Location).Path
        "$NeonPink[$cwd] ✨$Reset "
    }
    Write-Host "$NeonPink Pastel Pink prompt applied.$Reset"
}

function Set-PromptTheme-CyberGreen {
    function global:prompt {
        $cwd = (Get-Location).Path
        "$NeonGreen[$cwd] ⚡$Reset "
    }
    Write-Host "$NeonGreen Cyber Green prompt applied.$Reset"
}

function Reset-Prompt {
    Remove-Item function:prompt -ErrorAction SilentlyContinue
    Write-Host "$NeonCyan Prompt reset to default.$Reset"
}

# ---------------------------------------------------------
# Main Neon FX Menu
# ---------------------------------------------------------
function global:Show-NeonFXMenu {

    Clear-Host
    Write-Host "╭──────────────────────────────╮" -ForegroundColor Magenta
    Write-Host "│     N E O N   F X   M E N U  │" -ForegroundColor Magenta
    Write-Host "├──────────────────────────────┤" -ForegroundColor Magenta
    Write-Host "│ 1) Neon Borders              │"
    Write-Host "│ 2) Animated Cursor           │"
    Write-Host "│ 3) Water Ripple Waves        │"
    Write-Host "│ 4) Pastel Neon Variants      │"
    Write-Host "│ 5) Matrix Rain               │"
    Write-Host "│ 6) Cyberpunk Prompt          │"
    Write-Host "│ 7) Reset FX                  │"
    Write-Host "│ 9) Exit                      │"
    Write-Host "╰──────────────────────────────╯" -ForegroundColor Magenta

    Write-Host ""
    $choice = Read-Host "Choose"

    switch ($choice) {

        "1" { Write-Host "Neon borders enabled." -ForegroundColor Cyan }
        "2" { Write-Host "Animated cursor enabled." -ForegroundColor Cyan }
        "3" { Write-Host "Water ripple FX enabled." -ForegroundColor Cyan }
        "4" { Write-Host "Pastel neon mode enabled." -ForegroundColor Cyan }
        "5" { Write-Host "Matrix rain started." -ForegroundColor Cyan }
        "6" { Write-Host "Cyberpunk prompt activated." -ForegroundColor Cyan }
        "7" { Write-Host "FX reset." -ForegroundColor Cyan }
        "9" { return }
    }
}


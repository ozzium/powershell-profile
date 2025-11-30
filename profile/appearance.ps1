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
	
	# ===============================
#  RAVEN INLINE SUGGESTION KEY
# ===============================
try {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Space' -ScriptBlock {
        $line   = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        $suggest = Invoke-RavenInlineSuggestion -CurrentLine $line
        if ($suggest) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $suggest)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($suggest.Length)
        }
    } -BriefDescription "Raven AI Suggest" -Description "Ask Raven to complete / improve current line."
} catch {}


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

    $themeUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json'
    Write-Host "Using theme: cobalt2 (oh-my-posh)" -ForegroundColor Cyan
    try {
        oh-my-posh init pwsh --config $themeUrl | Invoke-Expression
    } catch {
        Write-Warning "oh-my-posh init failed: $_"
    }
}

function Switch-Theme {
    param([string]$Name = 'cobalt2')

    switch ($Name.ToLower()) {
        'cobalt2' { Get-Theme }
        default   { Write-Warning "Unknown theme: $Name" }
    }
}
function global:Switch-Theme {
    param([string]$Name)

    switch ($Name.ToLower()) {

        "cobalt2" {
            $themeUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json'
            oh-my-posh init pwsh --config $themeUrl | Invoke-Expression
            Write-Host "Theme set: cobalt2" -ForegroundColor Cyan
        }

        "default" {
            # clears oh-my-posh; returns to normal PS prompt
            oh-my-posh disable
            Write-Host "Theme set: default PowerShell" -ForegroundColor Yellow
        }

        default {
            Write-Warning "Unknown theme: $Name"
        }
    }
}
# ===============================
#  RAVEN EVOLVED PROMPT
# ===============================

function global:Set-RavenPrompt {
    $segments = Get-RavenPromptSegments

    function global:prompt {
        $s = Get-RavenPromptSegments

        $adminTag = if ($s.IsAdmin) { " ADMIN " } else { "" }
        $branchTag = if ($s.Branch) { "  $($s.Branch)" } else { "" }
        $modeTag = if ($s.Mode -ne "none") { " $($s.ModeIcon) [$($s.Mode)]" } else { "" }

        $cwdShort = $s.Cwd.Replace($HOME, "~")

        Write-Host "" -NoNewline
        Write-Host "" -ForegroundColor DarkMagenta -NoNewline
        Write-Host "$cwdShort" -ForegroundColor Cyan -NoNewline
        Write-Host "$branchTag" -ForegroundColor Yellow -NoNewline
        Write-Host "$modeTag" -ForegroundColor Magenta -NoNewline
        if ($adminTag) {
            Write-Host " $adminTag" -ForegroundColor Red -NoNewline
        }
        Write-Host ""  # newline
        return "🦇  "
    }
}

# Enable Raven prompt by default
try { Set-RavenPrompt } catch {}

# ===============================
# Raven Appearance
# PSReadLine + Oh-My-Posh theme
# ===============================

$PSReadLineOptions = @{
    EditMode                      = 'Windows'
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'History'
    PredictionViewStyle           = 'ListView'
    BellStyle                     = 'None'
}

try {
    if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
        Set-PSReadLineOption @PSReadLineOptions
    }
} catch {}

try {
    if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
        Set-PSReadLineKeyHandler -Key UpArrow             -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow           -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab                 -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord 'Ctrl+d'          -Function DeleteChar
        Set-PSReadLineKeyHandler -Chord 'Ctrl+w'          -Function BackwardDeleteWord
        Set-PSReadLineKeyHandler -Chord 'Alt+d'           -Function DeleteWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'  -Function BackwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+z'          -Function Undo
        Set-PSReadLineKeyHandler -Chord 'Ctrl+y'          -Function Redo

        Set-PSReadLineOption -AddToHistoryHandler {
            param($line)
            $sensitive = @('password','secret','token','apikey','connectionstring')
            $hasSensitive = $sensitive | Where-Object { $line -match $_ }
            return ($null -eq $hasSensitive)
        }
    }
} catch {}

# PSReadLine setup...

function global:Apply-RavenTheme {
    param(
        [string]$ThemeId = $global:RavenTheme,
        [switch]$Quiet
    )

    if (-not $ThemeId) { $ThemeId = "cobalt2" }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        if (-not $Quiet) { Write-Warning "oh-my-posh not found." }
        return
    }

    $themeRoots = @()

    if ($env:POSH_THEMES_PATH) {
        $themeRoots += $env:POSH_THEMES_PATH
    }

    $themeRoots += @(
        "/opt/homebrew/opt/oh-my-posh/themes",
        "/usr/local/opt/oh-my-posh/themes",
        "/usr/local/share/oh-my-posh/themes",
        "/opt/homebrew/share/oh-my-posh/themes",
        "$HOME/.cache/oh-my-posh/themes",
        "$env:LOCALAPPDATA/Programs/oh-my-posh/themes"
    )

    $brewCellars = @(
        "/usr/local/Cellar/oh-my-posh",
        "/opt/homebrew/Cellar/oh-my-posh"
    )

    foreach ($cellar in $brewCellars) {
        $brewThemeDir = Get-ChildItem $cellar -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1

        if ($brewThemeDir) {
            $themeRoots += (Join-Path $brewThemeDir.FullName "themes")
        }
    }

    $themeRoots = $themeRoots |
        Where-Object { $_ -and (Test-Path $_) } |
        Select-Object -Unique

    $themeFile = $null

    foreach ($root in $themeRoots) {
        $candidate = Join-Path $root "$ThemeId.omp.json"
        if (Test-Path $candidate) {
            $themeFile = $candidate
            break
        }
    }

    if (-not $themeFile) {
        if (-not $Quiet) {
            Write-Warning "Theme file not found for: $ThemeId"
            Write-Warning "Checked: $($themeRoots -join ', ')"
        }
        return
    }

    $global:RavenTheme = $ThemeId
    oh-my-posh init pwsh --config $themeFile | Invoke-Expression
}
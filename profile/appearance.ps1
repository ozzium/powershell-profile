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
    } catch {
        Write-Warning ("oh-my-posh init failed: {0}" -f $_.Exception.Message)
    }
}
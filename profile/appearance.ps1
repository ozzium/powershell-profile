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

    if (-not (Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue)) {
        Write-Warning "oh-my-posh not installed."
        return
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


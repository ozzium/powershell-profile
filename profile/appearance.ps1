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

function global:Get-RavenSettingsPath {
    $repoRoot = $null

    if (Get-Command Get-RavenRepoRoot -ErrorAction SilentlyContinue) {
        $repoRoot = Get-RavenRepoRoot
    }

    if (-not $repoRoot) {
        $possibleRepoRoots = @(
            "$HOME/Documents/GitHub/powershell-profile",
            "$HOME\Documents\GitHub\powershell-profile"
        )

        foreach ($possibleRepoRoot in $possibleRepoRoots) {
            if (Test-Path $possibleRepoRoot) {
                $repoRoot = $possibleRepoRoot
                break
            }
        }
    }

    if (-not $repoRoot) {
        return $null
    }

    return Join-Path $repoRoot "profile/raven-settings.json"
}

function global:Get-RavenSettings {
    $path = Get-RavenSettingsPath

    if (-not $path -or -not (Test-Path $path)) {
        return [pscustomobject]@{
            theme    = "cobalt2-custom"
            fastMode = $false
        }
    }

    try {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            theme    = "cobalt2-custom"
            fastMode = $false
        }
    }
}

function global:Save-RavenSettings {
    param(
        [string]$Theme,
        [Nullable[bool]]$FastMode
    )

    $path = Get-RavenSettingsPath

    if (-not $path) {
        return
    }

    $current = Get-RavenSettings

    $data = [ordered]@{
        theme    = if ($Theme) { $Theme } else { $current.theme }
        fastMode = if ($null -ne $FastMode) { [bool]$FastMode } else { [bool]$current.fastMode }
    }

    $data |
        ConvertTo-Json -Depth 5 |
        Set-Content -Path $path -Encoding UTF8
}

# PSReadLine setup...

function global:Apply-RavenTheme {
    param(
        [string]$ThemeId = $global:RavenTheme,
        [switch]$Quiet
    )

    if (-not $ThemeId) {
        $ThemeId = "cobalt2-custom"
    }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        if (-not $Quiet) {
            Write-Warning "oh-my-posh not found."
        }
        return $false
    }

    $repoRoot = $null

    if (Get-Command Get-RavenRepoRoot -ErrorAction SilentlyContinue) {
        $repoRoot = Get-RavenRepoRoot
    }

    if (-not $repoRoot) {
        $possibleRepoRoots = @(
            "$HOME/Documents/GitHub/powershell-profile",
            "$HOME\Documents\GitHub\powershell-profile"
        )

        foreach ($possibleRepoRoot in $possibleRepoRoots) {
            if (Test-Path $possibleRepoRoot) {
                $repoRoot = $possibleRepoRoot
                break
            }
        }
    }

    $themeRoots = @()

    if ($repoRoot) {
        $themeRoots += @(
            Join-Path $repoRoot "modules/Themes"
            Join-Path $repoRoot "themes"
            Join-Path $repoRoot "profile/themes"
            Join-Path $repoRoot "profile/oh-my-posh"
            Join-Path $repoRoot "oh-my-posh"
        )
    }

    if ($env:POSH_THEMES_PATH) {
        $themeRoots += $env:POSH_THEMES_PATH
    }

    $themeRoots += @(
        "/opt/homebrew/opt/oh-my-posh/themes",
        "/usr/local/opt/oh-my-posh/themes",
        "/usr/local/share/oh-my-posh/themes",
        "/opt/homebrew/share/oh-my-posh/themes",
        "$HOME/.cache/oh-my-posh/themes",
        "$env:LOCALAPPDATA/Programs/oh-my-posh/themes",
        "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
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

    $possibleThemeNames = @(
        "$ThemeId.omp.json",
        "$ThemeId.json"
    )

    foreach ($root in $themeRoots) {
        foreach ($themeName in $possibleThemeNames) {
            $candidate = Join-Path $root $themeName

            if (Test-Path $candidate) {
                $themeFile = $candidate
                break
            }
        }

        if ($themeFile) {
            break
        }
    }

    if (-not $themeFile) {
    $themeFile = $ThemeId
}

    $global:RavenTheme = $ThemeId
    $global:RavenThemeFile = $themeFile
    
    if (-not $Quiet) {
    Save-RavenSettings -Theme $ThemeId
}

$ompInit = oh-my-posh init pwsh --config $themeFile

Invoke-Expression $ompInit

if (Get-Command prompt -ErrorAction SilentlyContinue) {
    $localPrompt = Get-Command prompt

    if ($localPrompt.ScriptBlock) {
        Set-Item -Path Function:\global:prompt -Value $localPrompt.ScriptBlock
    }
}

    if (-not $Quiet) {
        Write-Host "Applied theme: $ThemeId" -ForegroundColor Green
        Write-Host $themeFile -ForegroundColor DarkGray
    }

    return $true
}

function global:Get-RavenThemeRoots {
    $repoRoot = $null

    if (Get-Command Get-RavenRepoRoot -ErrorAction SilentlyContinue) {
        $repoRoot = Get-RavenRepoRoot
    }

    if (-not $repoRoot) {
        $possibleRepoRoots = @(
            "$HOME/Documents/GitHub/powershell-profile",
            "$HOME\Documents\GitHub\powershell-profile"
        )

        foreach ($possibleRepoRoot in $possibleRepoRoots) {
            if (Test-Path $possibleRepoRoot) {
                $repoRoot = $possibleRepoRoot
                break
            }
        }
    }

    $roots = @()

    if ($repoRoot) {
        $roots += @(
            Join-Path $repoRoot "modules/Themes"
            Join-Path $repoRoot "themes"
            Join-Path $repoRoot "profile/themes"
            Join-Path $repoRoot "profile/oh-my-posh"
            Join-Path $repoRoot "oh-my-posh"
        )
    }

    if ($env:POSH_THEMES_PATH) {
        $roots += $env:POSH_THEMES_PATH
    }

    $roots += @(
        "$env:LOCALAPPDATA/Programs/oh-my-posh/themes",
        "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
        "/opt/homebrew/opt/oh-my-posh/themes",
        "/usr/local/opt/oh-my-posh/themes",
        "/usr/local/share/oh-my-posh/themes",
        "/opt/homebrew/share/oh-my-posh/themes",
        "$HOME/.cache/oh-my-posh/themes"
    )

    return $roots |
        Where-Object { $_ -and (Test-Path $_) } |
        Select-Object -Unique
}


function global:Get-RavenAvailableThemes {
    $themes = @()

    foreach ($root in Get-RavenThemeRoots) {
        $themes += Get-ChildItem $root -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '\.omp\.json$|\.json$' } |
            ForEach-Object {
                $id = $_.Name
                $id = $id -replace '\.omp\.json$', ''
                $id = $id -replace '\.json$', ''

                [pscustomobject]@{
                    Id   = $id
                    Name = $id
                    Path = $_.FullName
                }
            }
    }

$builtInThemes = @(
    "cobalt2",
    "jandedobbeleer",
    "zash",
    "agnoster",
    "atomic",
    "bubbles",
    "catppuccin",
    "clean-detailed",
    "dracula",
    "emodipt",
    "gruvbox",
    "huvix",
    "iterm2",
    "kali",
    "marcduiker",
    "montys",
    "multiverse-neon",
    "negligible",
    "night-owl",
    "paradox",
    "powerlevel10k_classic",
    "pure",
    "robbyrussell",
    "spaceship",
    "star",
    "thecyberden",
    "tokyonight_storm",
    "ys"
)

        foreach ($themeName in $builtInThemes) {
            $themes += [pscustomobject]@{
                Id   = $themeName
                Name = "$themeName [built-in]"
                Path = $themeName
            }
        }

    return $themes | Sort-Object Id -Unique
}

function global:Switch-RavenTheme {
    Clear-Host

    if (Get-Command Show-RavenMenuHeader -ErrorAction SilentlyContinue) {
        Show-RavenMenuHeader
    }

    Write-Host "Switch Theme" -ForegroundColor Cyan
    Write-Host "------------" -ForegroundColor DarkGray
    Write-Host ""

    $themes = @(Get-RavenAvailableThemes)

    if (-not $themes -or $themes.Count -eq 0) {
        Write-Host "No theme files found." -ForegroundColor Red
        Write-Host ""
        Write-Host "Checked these folders:" -ForegroundColor Yellow

        foreach ($root in Get-RavenThemeRoots) {
            Write-Host " - $root" -ForegroundColor DarkGray
        }

        Read-Host "Press Enter to continue..."
        return
    }

    for ($i = 0; $i -lt $themes.Count; $i++) {
        Write-Host ("{0,2} • {1}" -f ($i + 1), $themes[$i].Id)
    }

    Write-Host ""
    Write-Host "Enter to cancel." -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "Choose a theme number"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return
    }

    [int]$idx = 0
    if (-not [int]::TryParse($choice, [ref]$idx)) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return
    }

    $realIndex = $idx - 1

    if ($realIndex -lt 0 -or $realIndex -ge $themes.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return
    }

    $selected = $themes[$realIndex]

    $applied = Apply-RavenTheme -ThemeId $selected.Id

    if ($applied) {
        Write-Host "Switched theme to $($selected.Id)." -ForegroundColor Green
    }
    else {
        Write-Host "Theme switch failed. No changes were made." -ForegroundColor Red
    }

    Read-Host "Press Enter to continue..."
}

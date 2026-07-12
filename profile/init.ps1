# Raven v3 - Init
# Lightweight shell startup helpers only.
# Theme logic lives in appearance.ps1.
# Editor logic lives in editors.ps1.

$global:RavenInitTimings = @()

function Add-RavenInitTiming {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Script
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        & $Script
    }
    catch {
        Write-Warning "$Name failed: $($_.Exception.Message)"
    }
    finally {
        $sw.Stop()

        $global:RavenInitTimings += [pscustomobject]@{
            Step = $Name
            Ms   = $sw.ElapsedMilliseconds
        }
    }
}

function global:raven-init-time {
    $global:RavenInitTimings |
        Sort-Object Ms -Descending |
        Format-Table Step, Ms -AutoSize
}

# Load Raven settings early so Fast Mode affects startup helpers.
Add-RavenInitTiming "Load settings" {
    $global:RavenFastMode = $false

    if (Get-Command Get-RavenSettings -ErrorAction SilentlyContinue) {
        $settings = Get-RavenSettings

        if ($null -ne $settings.fastMode) {
            $global:RavenFastMode = [bool]$settings.fastMode
        }

        if ($settings.theme) {
            $global:RavenTheme = $settings.theme
        }
    }
}

# Admin check
Add-RavenInitTiming "Admin check" {
    if ($IsWindows) {
        $global:IsAdmin = (New-Object Security.Principal.WindowsPrincipal(
            [Security.Principal.WindowsIdentity]::GetCurrent()
        )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        $global:IsAdmin = $false
    }
}

# Window title
Add-RavenInitTiming "Window title" {
    $adminSuffix = if ($global:IsAdmin) { " [ADMIN]" } else { "" }
    $Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"
}

# Avoid opening in System32 on Windows
Add-RavenInitTiming "Set location" {
    if ($IsWindows -and (Get-Location).Path -like "C:\Windows\System32*") {
        Set-Location $HOME
    }
}

function global:Reload-RavenProfile {
    . $PROFILE
    Write-Host "Raven profile reloaded." -ForegroundColor Green
}

Set-Alias -Name reload-profile -Value Reload-RavenProfile -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name reload-raven -Value Reload-RavenProfile -Scope Global -ErrorAction SilentlyContinue

function global:Edit-Profile {
    if (Get-Command Open-RavenFileWithEditor -ErrorAction SilentlyContinue) {
        $saved = Get-RavenSavedEditor

        if ($saved) {
            Open-RavenFileWithEditor -Path $PROFILE -Editor ([pscustomobject]@{
                Name       = $saved.name
                Command    = $saved.command
                LaunchMode = $saved.launchMode
            })
            return
        }
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $PROFILE
        return
    }

    if ($IsWindows) {
        notepad.exe $PROFILE
        return
    }

    if ($IsMacOS) {
        & "/usr/bin/open" -a "TextEdit" $PROFILE
        return
    }

    nano $PROFILE
}

Set-Alias -Name ep -Value Edit-Profile -Scope Global -ErrorAction SilentlyContinue

# Optional Terminal-Icons
Add-RavenInitTiming "Terminal-Icons" {
    if (-not $global:RavenFastMode) {
        if (Get-Module -ListAvailable -Name Terminal-Icons) {
            Import-Module Terminal-Icons -ErrorAction SilentlyContinue
        }
    }
}

# Optional zoxide
Add-RavenInitTiming "zoxide" {
    if (-not $global:RavenFastMode) {
        if (Get-Command zoxide -ErrorAction SilentlyContinue) {
            Invoke-Expression (& { zoxide init --cmd z powershell | Out-String })
        }
    }
}

# Optional external function folder
Add-RavenInitTiming "External functions" {
    $repoRoot = $null

    if (Get-Command Get-RavenRepoRoot -ErrorAction SilentlyContinue) {
        $repoRoot = Get-RavenRepoRoot
    }

    if ($repoRoot) {
        $funcFolder = Join-Path $repoRoot "modules/Functions"

        if (Test-Path $funcFolder) {
            Get-ChildItem -Path $funcFolder -Filter *.ps1 -File -ErrorAction SilentlyContinue |
                ForEach-Object {
                    try {
                        . $_.FullName
                    }
                    catch {
                        Write-Warning "Failed to load function file $($_.Name): $($_.Exception.Message)"
                    }
                }
        }
    }
}

# Apply saved Raven theme last
Add-RavenInitTiming "Apply theme" {
    if (-not $global:RavenFastMode) {
        if (Get-Command Apply-RavenTheme -ErrorAction SilentlyContinue) {
            Apply-RavenTheme -ThemeId $global:RavenTheme -Quiet | Out-Null
        }
    }
}
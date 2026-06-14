# Raven v3 - Init
# Lightweight shell startup helpers only.
# Theme logic lives in appearance.ps1.
# Editor logic lives in editors.ps1.

# Admin check
try {
    if ($IsWindows) {
        $global:IsAdmin = (New-Object Security.Principal.WindowsPrincipal(
            [Security.Principal.WindowsIdentity]::GetCurrent()
        )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        $global:IsAdmin = $false
    }
}
catch {
    $global:IsAdmin = $false
}

# Window title
try {
    $adminSuffix = if ($global:IsAdmin) { " [ADMIN]" } else { "" }
    $Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"
}
catch {}

# Avoid opening in System32 on Windows
try {
    if ($IsWindows -and (Get-Location).Path -like "C:\Windows\System32*") {
        Set-Location $HOME
    }
}
catch {}

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
try {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }
}
catch {}

# Optional zoxide
try {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Invoke-Expression (& { zoxide init --cmd z powershell | Out-String })
    }
}
catch {
    Write-Warning "zoxide init failed: $_"
}

# Optional external function folder
try {
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
                        Write-Warning "Failed to load function file $($_.Name): $_"
                    }
                }
        }
    }
}
catch {}

# Apply saved Raven theme last
try {
    try {
    if (Get-Command Apply-RavenTheme -ErrorAction SilentlyContinue) {
        $settings = Get-RavenSettings

        try {
    if (Get-Command Get-RavenSettings -ErrorAction SilentlyContinue) {
        $settings = Get-RavenSettings
        $global:RavenFastMode = [bool]$settings.fastMode
    }
}
catch {
    $global:RavenFastMode = $false
}

        if ($settings.theme) {
            $global:RavenTheme = $settings.theme
        }

        Apply-RavenTheme -ThemeId $global:RavenTheme -Quiet | Out-Null
    }
}
catch {
    Write-Warning "Failed to apply Raven theme: $_"
}
}
catch {
    Write-Warning "Failed to apply Raven theme: $_"
}
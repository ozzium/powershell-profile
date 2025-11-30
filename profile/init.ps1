# Write-Host "Loading PowerShell Profile..."
# Show-RavenBanner
# Show-SystemHeader

# Admin check
$global:IsAdmin = (
    [Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Window title
$adminSuffix = if ($global:IsAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"

# Editor detection (only runs once)
if (-not $global:PSProfileConfig.Editor) {
    $candidates = @('nvim','pvim','vim','vi','code','codium','notepad++','sublime_text')
    foreach ($c in $candidates) {
        if (Get-Command -Name $c -ErrorAction SilentlyContinue) {
            $global:PSProfileConfig.Editor = $c
            break
        }
    }
    if (-not $global:PSProfileConfig.Editor) {
        $global:PSProfileConfig.Editor = 'notepad'
    }
}

Set-Alias -Name vim -Value $global:PSProfileConfig.Editor -ErrorAction SilentlyContinue

function Edit-Profile {
    & $global:PSProfileConfig.Editor $PROFILE
}
Set-Alias -Name ep -Value Edit-Profile -ErrorAction SilentlyContinue

$script:ProfilePostInitRegistered = $false

function Invoke-Profile-PostInit {
    if ($script:ProfilePostInitRegistered) { return }
    $script:ProfilePostInitRegistered = $true

    Start-Sleep -Milliseconds 50

    # Determine prompt mode (Normal/Fast) if configured
    $mode = $null
    if ($global:PSProfileConfig -and `
        ($global:PSProfileConfig.PSObject.Properties.Name -contains 'PromptMode')) {
        $mode = $global:PSProfileConfig.PromptMode
    }
    if (-not $mode) { $mode = 'Normal' }

    # oh-my-posh (optional, skipped in Fast mode)
    if ($mode -ne 'Fast' -and `
        (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue)) {
        try {
            $ompConfig = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json'
            oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
        } catch {
            Write-Warning "oh-my-posh failed to initialize: $_"
        }
    }

   # Write-Host "Loading PowerShell Profile..."
# Show-RavenBanner
# Show-SystemHeader
    }
}

function prompt {
    Invoke-Profile-PostInit
    $cwd = (Get-Location).Path
    if ($global:IsAdmin) { "[$cwd] # " } else { "[$cwd] $ " }
}

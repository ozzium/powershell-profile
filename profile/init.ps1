# Admin check (fixed)
$global:IsAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Window title
$adminSuffix = if ($global:IsAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"

try {
  if ((Get-Location).Path -like "C:\Windows\System32*") {
    Set-Location $HOME
  }
} catch {}

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

# Lazy one-time init for heavier stuff (themes, icons, zoxide)
$script:ProfilePostInitRegistered = $false

function Invoke-Profile-PostInit {
    if ($script:ProfilePostInitRegistered) { return }
    $script:ProfilePostInitRegistered = $true

    Start-Sleep -Milliseconds 50

    # Terminal-Icons (optional)
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }

    # oh-my-posh (optional)
    if (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue) {
        try {
            $ompConfig = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json'
            oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
        } catch {
            Write-Warning "oh-my-posh failed to initialize: $_"
        }
    }

    # zoxide (optional)
    if (Get-Command -Name 'zoxide' -ErrorAction SilentlyContinue) {
        try {
            Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
        } catch {
            Write-Warning "zoxide init failed: $_"
        }
    }

    # Optional: auto-load external user functions from modules/Functions
    $funcFolder = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\modules\Functions'
    $funcFolder = (Resolve-Path $funcFolder -ErrorAction SilentlyContinue)?.Path
    if ($funcFolder -and (Test-Path $funcFolder)) {
        $files = Get-ChildItem -Path $funcFolder -Filter *.ps1 -File -ErrorAction SilentlyContinue
        $i = 1
        foreach ($f in $files) {
            try {
                . $f.FullName
                Write-Host "$i : $($f.Name) loaded" -ForegroundColor Yellow -BackgroundColor DarkMagenta
                $i++
            } catch {
                Write-Warning "Failed to load function file $($f.Name): $_"
            }
        }
    }
}

# Prompt uses lazy init
function prompt {
    Invoke-Profile-PostInit
    $cwd = (Get-Location).Path
    if ($global:IsAdmin) { "[$cwd] # " } else { "[$cwd] $ " }
}

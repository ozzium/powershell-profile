# Basic file helpers
function touch { param($File) "" | Out-File -FilePath $File -Encoding ASCII }
function nf    { param($Name) New-Item -ItemType File -Path . -Name $Name -Force | Out-Null }
function mkcd  { param($Dir)  New-Item -ItemType Directory -Path $Dir -Force | Out-Null; Set-Location $Dir }

function ff {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}

# Navigation shortcuts
function docs {
    $d = [Environment]::GetFolderPath('MyDocuments')
    if (-not $d) { $d = "$HOME\Documents" }
    Set-Location -Path $d
}
function dtop {
    $d = [Environment]::GetFolderPath('Desktop')
    if (-not $d) { $d = "$HOME\Desktop" }
    Set-Location -Path $d
}

# Processes
function k9    { param([string]$Name) Stop-Process -Name $Name -ErrorAction SilentlyContinue }
function sysinfo { Get-ComputerInfo }

# DNS / Network
function flushdns {
    try {
        Clear-DnsClientCache
        Write-Host "DNS cache cleared." -ForegroundColor Green
    } catch {
        Write-Warning "Could not clear DNS cache: $_"
    }
}

function Get-PubIP {
    try {
        (Invoke-WebRequest http://ifconfig.me/ip -UseBasicParsing -TimeoutSec 5).Content.Trim()
    } catch {
        Write-Warning "Failed to obtain public IP: $_"
    }
}

# Clipboard
function cpy { param([string]$Text) Set-Clipboard -Value $Text }
function pst { Get-Clipboard }

# Trash to Recycle Bin
function trash {
    param([Parameter(Mandatory)][string]$Path)

    try {
        $resolved = (Resolve-Path -Path $Path -ErrorAction Stop).Path
        $item     = Get-Item -LiteralPath $resolved
        $parent   = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }

        $shell    = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parent).ParseName($item.Name)
        $shellItem.InvokeVerb('delete')

        Write-Host "Item '$resolved' moved to Recycle Bin." -ForegroundColor Green
    } catch {
        Write-Warning "trash failed for '$Path': $_"
    }
}

# Uptime
function uptime {
    try {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $bootTime = Get-Uptime -Since
        } else {
            $lastBootRaw = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime    = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBootRaw)
        }

        $uptime = (Get-Date) - $bootTime
        Write-Host ("System started on: {0}" -f $bootTime) -ForegroundColor DarkGray
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f `
            $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds) -ForegroundColor Blue
    } catch {
        Write-Error "Failed to calculate uptime: $_"
    }
}
function global:reload-profile {
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    . $PROFILE
}
# Git shortcuts
function gs    { git status }
function ga    { git add . }
function gpush { git push }
function gpull { git pull }

function gc {
    param([Parameter(Mandatory)][string]$Message)
    git commit -m $Message
}

function gcom {
    param([Parameter(Mandatory)][string]$Message)
    git add .
    git commit -m $Message
}

function reload-profile {
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    & $PROFILE
}

function lazyg {
    param([Parameter(Mandatory)][string]$Message)
    git add .
    git commit -m $Message
    git push
}

# Hastebin uploader (fixed)
function hb {
    param(
        [Parameter(Mandatory)][string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "File path does not exist: $FilePath"
        return
    }

    try {
        $content  = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $response = Invoke-RestMethod -Uri "https://hastebin.com/documents" -Method POST -Body $content -ErrorAction Stop

        if ($response -and $response.key) {
            Write-Output "https://hastebin.com/$($response.key)"
        } else {
            Write-Warning "Unexpected response from hastebin: $response"
        }
    } catch {
        Write-Error "Failed to upload to hastebin: $_"
    }
}

# Reload profile quickly
function Update-Profile {
    & $PROFILE
}
function global:reload-profile {
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    . $PROFILE
}

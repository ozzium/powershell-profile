# Raven Profile Bootstrap
. "C:\Users\ozzium\Documents\GitHub\powershell-profile\bootstrap\loader.ps1"

oh-my-posh init pwsh --strict | Invoke-Expression

# VARIABLES -------------------------------------------------------------------
$PROFILE_DIR = Split-Path -Path $PROFILE
$CACHE_DIR = if ($IsWindows) {
    "$HOME\AppData\Local\Temp"
}
else {
    "$HOME/.cache"
}
$WT_CONFIG = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# UTILITY FUNCTIONS -----------------------------------------------------------
function Test-CommandExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Command
    )
    [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function New-CachedScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$CacheSubDir,
        [Parameter(Mandatory)]
        [scriptblock]$Generator
    )

    $cacheDir = Join-Path $CACHE_DIR $CacheSubDir
    $scriptPath = Join-Path $cacheDir "Start-$Name.ps1"

    if (-not (Test-Path $scriptPath)) {
        New-Item -ItemType Directory -Force $cacheDir | Out-Null
        & $Generator | Out-File -FilePath $scriptPath -Encoding utf8
    }

    . $scriptPath
}

# Set default editor
$env:EDITOR = @(
    @( 'npp' ),
    @('np4', '--wait'),
    @('code', '--wait'),
    @( 'nano' )
    @( 'vim' )
    @( 'ted' )
) | Where-Object { Test-CommandExists $_[0] } | Select-Object -First 1

# Get public IP (uses ipify.org API)
function Get-PubIP {
    (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip
}

# APPEARANCE ------------------------------------------------------------------
$PSStyle.FileInfo.Directory = $PSStyle.Bold + $PSStyle.Foreground.Blue
Set-PSReadLineOption -Colors @{
    Default          = $PSStyle.Reset
    InlinePrediction = $PSStyle.Italic + $PSStyle.Foreground.BrightBlack
    Operator         = $PSStyle.Reset
    Parameter        = $PSStyle.Reset
};

# LS_COLORS (dircolors compatible)
$env:LS_COLORS = 'rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.7z=01;31:*.ace=01;31:*.alz=01;31:*.apk=01;31:*.arc=01;31:*.arj=01;31:*.bz=01;31:*.bz2=01;31:*.cab=01;31:*.cpio=01;31:*.crate=01;31:*.deb=01;31:*.drpm=01;31:*.dwm=01;31:*.dz=01;31:*.ear=01;31:*.egg=01;31:*.esd=01;31:*.gz=01;31:*.jar=01;31:*.lha=01;31:*.lrz=01;31:*.lz=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.lzo=01;31:*.pyz=01;31:*.rar=01;31:*.rpm=01;31:*.rz=01;31:*.sar=01;31:*.swm=01;31:*.t7z=01;31:*.tar=01;31:*.taz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tgz=01;31:*.tlz=01;31:*.txz=01;31:*.tz=01;31:*.tzo=01;31:*.tzst=01;31:*.udeb=01;31:*.war=01;31:*.whl=01;31:*.wim=01;31:*.xz=01;31:*.z=01;31:*.zip=01;31:*.zoo=01;31:*.zst=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.jxl=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.crdownload=00;90:*.dpkg-dist=00;90:*.dpkg-new=00;90:*.dpkg-old=00;90:*.dpkg-tmp=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:*.swp=00;90:*.tmp=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:'

# FZF theme
$env:FZF_DEFAULT_OPTS = @(
    '--highlight-line',
    '--color=fg:#cdcbdd',
    '--color=bg:#181624',
    '--color=gutter:#181624',
    '--color=border:#52abcf',
    '--color=separator:#52abcf',
    '--color=scrollbar:#625f7e',
    '--color=hl:#e97294',
    '--color=hl+:#e97294',
    '--color=fg+:#cdcbdd',
    '--color=bg+:#2b3b51',
    '--color=pointer:#e9b5b3',
    '--color=prompt:#e9b5b3',
    '--color=spinner:#e9b5b3',
    '--color=marker:#e9b5b3',
    '--color=header:#52abcf',
    '--color=info:#8e8aac',
    '--color=preview-border:#52abcf',
    '--color=preview-scrollbar:#625f7e'
) -join ' '

# Interactive directory navigation with fzf
function cdf {
    $excludeDirs = @(
        '.affinity',
        '.bun',
        '.cache',
        '.dotnet',
        '.git',
        '.gradle',
        '.nuget',
        '.vscode',
        'go',
        'node_modules',
        'scoop',
        'vendor'
    )

    $fzfArgs = @(
        '--height=50%',
        '--cycle',
        '--prompt=Go to> ',
        '--scheme=path',
        '--layout=reverse',
        '--walker=dir,hidden',
        "--walker-skip=$($excludeDirs -join ',')"
    )

    $dir = & fzf @fzfArgs
    if ($LASTEXITCODE -eq 0 -and $dir) {
        Set-Location -LiteralPath $dir
    }
}

function pstui {
    Import-Module PSTui -Force -ErrorAction Stop
    Write-Host "PSTui loaded." -ForegroundColor Green
}
	
function Start-AdminSession { Start-Process pwsh -Verb RunAs }
Set-Alias -Name admin -Value Start-AdminSession

function GitAliases {
	Import-Module GitAliases -Force -ErrorAction Stop
	Write-Host "GitAliases loaded." -ForegroundColor Green
}
	
function Invoke-PowerShellDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('Modules', 'Functions', 'Cmdlets', 'Aliases', 'DotNetStatic')]
        [string]$Type = 'Aliases',

        # New switch to isolate your personal shortcuts
        [switch]$OnlyCustom
)

    $Title = "Select items and click OK to copy them to your clipboard"

    switch ($Type) {
        'Aliases' {
            if ($OnlyCustom) {
                # Filters out aliases owned by core system modules
                $Data = Get-Alias | Where-Object { 
                    $_.Source -notmatch 'Microsoft.PowerShell' -and $_.ModuleName -notmatch 'Microsoft.PowerShell' 
                }
            } else {
                $Data = Get-Alias
            }
            $Data | Out-GridView -PassThru -Title "Aliases | $Title" | Set-Clipboard
        }
        'Modules' {
            Get-Module -ListAvailable | Out-GridView -PassThru -Title "Modules | $Title" | Set-Clipboard
        }
        'Functions' {
            Get-Command -CommandType Function | Out-GridView -PassThru -Title "Functions | $Title" | Set-Clipboard
        }
        'Cmdlets' {
            Get-Command -CommandType Cmdlet | Out-GridView -PassThru -Title "Cmdlets | $Title" | Set-Clipboard
        }
        'DotNetStatic' {
            [AppDomain]::CurrentDomain.GetAssemblies() | 
                ForEach-Object { try { $_.GetTypes() } catch {} } | 
                ForEach-Object { try { $_.GetMethods() } catch {} } | 
                Where-Object { $_.IsStatic } | 
                Select-Object DeclaringType, Name | 
                Out-GridView -PassThru -Title "DotNet | $Title" | Set-Clipboard
        }
    }
}

function New-PermanentAlias {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Value
    )

    # 1. Create it in the active session right now
    Set-Alias -Name $Name -Value $Value -Scope Global

    # 2. Format the string to append permanently to the script file
    $LineToAppend = "`nSet-Alias -Name '$Name' -Value '$Value'"

    # 3. Append to the physical profile document
    $LineToAppend | Add-Content -Path $PROFILE

    Write-Host "Success! Alias '$Name' -> '$Value' is now active and permanently saved to your profile." -ForegroundColor Cyan
}

# Create a short, ultra-fast alias to trigger this creator function
Set-Alias -Name npa -Value New-PermanentAlias
Set-Alias -Name 'omp' -Value 'oh-my-posh'
Set-Alias -Name 'gtft' -Value 'Get-FolderTree'
Set-Alias npp "C:\Program Files\Notepad++\notepad++.exe"
Set-Alias np4 "C:\mytools\Notepad4_HD\Notepad4.exe"
Set-Alias e++ "C:\mytools\Explorer++.exe"
Set-Alias e explorer.exe
Set-Alias god "C:\mytools\God Mode\All Tasks.lnk"
Set-Alias wint "C:\mytools\God Mode\Windows Tools.lnk"
Set-Alias exec "C:\mytools\Executor64bit\Executor.exe"
Set-Alias geek "C:\mytools\GeekUninstallerPortable\App\GeekUninstaller\geek.exe"
Set-Alias path "C:\mytools\windowspatheditor-1.7\WindowsPathEditor.exe"
Set-Alias mem "C:\mytools\ReduceMemory\ReduceMemory_x64.exe"
Set-Alias hosts "C:\mytools\HostsEditor_v1.6\hEdit_x64.exe"
Set-Alias snap "C:\mytools\MWSnap.exe"
Set-Alias run "C:\mytools\Run-Command_x64_p.exe"
Set-Alias ted "C:\mytools\TedNPad.exe"
Set-Alias fontview "C:\PortableApps\AMPFontViewer\App\AMPFontViewer\FontViewer.exe"
Set-Alias code "C:\Program Files\Microsoft VS Code\Code.exe"
Set-Alias nft "New-FolderTree"
Set-Alias bcu "C:\Program Files\BCUninstaller\BCUninstaller.exe"
Set-Alias -Name pshelp -Value Invoke-PowerShellDiscovery

function Switch-Profile {
    <#
    .SYNOPSIS
        Interactively switches or reloads PowerShell environment profiles.
    #>
    param (
        [string]$ProfileName
    )

    # Define the directory where your alternative profiles live
    $ProfileDir = Join-Path (Split-Path $PROFILE) "AlternativeProfiles"
    
    # Create the directory if it doesn't exist
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }

    # If a specific profile name is provided, load it directly
    if ($ProfileName) {
        $Path = Join-Path $ProfileDir "$ProfileName.ps1"
        if (Test-Path $Path) {
            . $Path
            Write-Host "Successfully loaded profile: $ProfileName" -ForegroundColor Green
            return
        } else {
            Write-Error "Profile '$ProfileName' not found in $ProfileDir"
            return
        }
    }

    # Otherwise, scan the folder and present a choice menu
    $Files = Get-ChildItem -Path $ProfileDir -Filter *.ps1
    
    if ($Files.Count -eq 0) {
        Write-Host "No alternative profiles found. Place your .ps1 configurations in:" -ForegroundColor Yellow
        Write-Host $ProfileDir -ForegroundColor Cyan
        return
    }

    Write-Host "--- Available PowerShell Profiles ---" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Files.Count; $i++) {
        Write-Host "[$i] $($Files[$i].BaseName)"
    }
    Write-Host "-------------------------------------"

    $Choice = Read-Host "Select a profile number to load"
    
    if ($Choice -match '^\d+$' -and [int]$Choice -lt $Files.Count) {
        $SelectedFile = $Files[[int]$Choice].FullName
        . $SelectedFile
        Write-Host "Successfully loaded profile: $($Files[[int]$Choice].BaseName)" -ForegroundColor Green
    } else {
        Write-Host "Invalid selection. No changes made." -ForegroundColor Red
    }
}


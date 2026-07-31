# Raven Profile Bootstrap (Doctor v2)
. "C:\Users\ozzium\Documents\GitHub\powershell-profile\bootstrap\loader.ps1"

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
Set-Alias font "C:\PortableApps\AMPFontViewer\App\AMPFontViewer\FontViewer.exe"
Set-Alias code "C:\Program Files\Microsoft VS Code\Code.exe"
Set-Alias nft "New-FolderTree"
Set-Alias bcu "C:\Program Files\BCUninstaller\BCUninstaller.exe"

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
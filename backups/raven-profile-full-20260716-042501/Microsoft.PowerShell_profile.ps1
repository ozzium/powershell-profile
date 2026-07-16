# Raven Profile Bootstrap (Doctor v2)
. "C:\Users\ozz\Documents\GitHub\powershell-profile\bootstrap\loader.ps1"

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
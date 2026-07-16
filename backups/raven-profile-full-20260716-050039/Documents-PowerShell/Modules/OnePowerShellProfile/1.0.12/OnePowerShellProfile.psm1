function Test-InstalledProgram {
    $Name = $args[0]

    if ($null -eq $Name -or $Name -eq '') {
        Write-Error 'Parameter not found. Provide a variation of the installed program name as an argument.'
    }

    $localMachineKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $currentUserKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"

    $getLocalMachineKey = Get-ItemProperty $localMachineKey |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object { $_.DisplayName -match $Name }
    $getCurrentUserKey = Get-ItemProperty $currentUserKey |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object { $_.DisplayName -match $Name }

    if ($null -ne $getLocalMachineKey) {
        Write-Output "Found registry match in HKLM (local machine) for program '$Name'"
        $getLocalMachineKey
        return $true
    }
    elseif ($null -ne $getCurrentUserKey) {
        Write-Output "Found registry match in HKCU (current user) for program '$Name'"
        $getCurrentUserKey
        return $true
    }
    else {
        Write-Output "Registry match not found '$Name'." -Foreground Red
        return $false
    }
}

function Invoke-ProfileConfiguration {
    param(
        [string] $Type
    )
    try {
        $File = ''

        if ($Type -eq "Public" -or $Type -eq "Private")
        {
            $ModuleBase = (Get-Module OnePowerShellProfile -ListAvailable).ModuleBase
            $File = Join-Path $ModuleBase "\Profile\$Type.ps1"
        }
        else {
            throw "Parameter 'Type' is expecting profile type values of 'Public' or 'Private'"
        }

        if ((Test-InstalledProgram { Visual Studio Code }) -eq $true) {
            Write-Output "Opening '$File' in Visual Studio Code"
            code $File
        }
        else {
            Write-Output "Opening '$File' in default text editor"
            Invoke-Item $File
        }
    }
    catch {
        throw
    }


}

function Set-Profile {
    [CmdletBinding(SupportsShouldProcess=$True)]
    param(
        [boolean] $IncludePrivate = $False,
        [boolean] $ArchiveOldProfile = $False
    )
    try {
        $PSProfileRootPath = $env:USERPROFILE

        # Check for valid Documents path w/ PowerShell modules
        $DocumentsOneDrive = $env:USERPROFILE + '\OneDrive'
        $DocumentsLocal = $env:USERPROFILE + '\Documents'

        # Resolve target `Documents` path (OneDrive (if available) preceeds local)
        if (!(Test-Path $DocumentsOneDrive)) {
            Write-Output "[NOTICE] Using '$DocumentsOneDrive' to reference PowerShell profiles"
            $PSProfileRootPath = $env:USERPROFILE + '\OneDrive - Microsoft\Documents'
        }
        else {
            Write-Output "[NOTICE] Using '$DocumentsLocal' to reference PowerShell profiles"
            $PSProfileRootPath = $env:USERPROFILE + '\Documents'
        }

        if ($PSCmdlet.ShouldProcess($PSProfileRootPath, "Create new directories")) {
            New-Item -ItemType Directory -Name "WindowsPowerShell" -Path $PSProfileRootPath -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Name "PowerShell" -Path $PSProfileRootPath -ErrorAction SilentlyContinue
        }

        $ISE = $PSProfileRootPath + '\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1'
        $Desktop = $PSProfileRootPath + '\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
        $Core = $PSProfileRootPath + '\PowerShell\Microsoft.PowerShell_profile.ps1'

        $PSProfiles = $ISE, $Desktop, $Core

        foreach ($TargetProfile in $PSProfiles) {
            $TargetProfilePath = Split-Path $TargetProfile
            $TargetProfileFileName = Split-Path $TargetProfile -Leaf

            if (!(Test-Path $TargetProfile)) {
                if ($PSCmdlet.ShouldProcess($TargetProfile, "Create new file"))
                {
                    New-Item -ItemType File -Name (Split-Path $TargetProfile -Leaf) -Path $TargetProfilePath
                }
            }

            if ($ArchiveOldProfile -eq $True)
            {
                if (!(Test-Path ($TargetProfilePath + "\Archived"))) {
                    if ($PSCmdlet.ShouldProcess($TargetProfilePath + "\Archived", "Create new directory")) {
                        New-Item -ItemType Directory -Name "Archived" -Path $TargetProfilePath
                    }
                }
                else {
                    $Timestamp = $timestamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
                    $ArchivedFileName = $Timestamp + "_" + $TargetProfileFileName
                    if ($PSCmdlet.ShouldProcess($TargetProfile, "Archive file")) {
                        Copy-Item $TargetProfile ($TargetProfilePath + "\Archived\" + $ArchivedFileName)
                    }
                    Write-Output "Archived $ArchivedFileName at $TargetProfileFileName"
                }
            }

            $ModuleBase = (Get-Module OnePowerShellProfile -ListAvailable).ModuleBase
            $PublicProfile = Join-Path $ModuleBase "\Profile\Public.ps1"
            $PrivateProfile = Join-Path $ModuleBase "\Profile\Private.ps1"

            Get-Content $PublicProfile > $TargetProfile

            if ($IncludePrivate -eq $true) {
                Get-Content $PrivateProfile >> $TargetProfile
                Write-Output "Appended $PrivateProfile to $TargetProfile"
            }

            Write-Output "[DONE] Updated '$TargetProfile'"
        }

        Write-Output "[NOTICE] Restart a new session, or invoke '. `$PROFILE' to source the latest profile in this session"
    }
    catch {
        throw
    }
}
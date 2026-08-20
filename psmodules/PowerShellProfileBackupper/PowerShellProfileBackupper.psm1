function Compress-Profile {
    [CmdletBinding()]
    param (
        [string]$BackupLocation = (Join-Path -Path $HOME -ChildPath "Documents\PowerShellProfileBackup")
    )

    $profilePath        = $PROFILE
    $repoPath           = Join-Path -Path $HOME -ChildPath "Documents\Github\powershell-profile"
    $customizationsPath = Join-Path -Path $HOME -ChildPath "Documents\PowerShell"

    $itemsToCompress = @($profilePath, $repoPath, $customizationsPath)

    if (-not (Test-Path -Path $BackupLocation)) {
        New-Item -ItemType Directory -Path $BackupLocation -Force | Out-Null
    }

    $timestamp   = Get-Date -Format 'yyyyMMddHHmmss'
    $zipFileName = "PowerShellProfileBackup_$timestamp.zip"
    $zipFilePath = Join-Path -Path $BackupLocation -ChildPath $zipFileName

    $tempStagingPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "PSProfileBackup_$timestamp"
    New-Item -ItemType Directory -Path $tempStagingPath -Force | Out-Null

    try {
        foreach ($item in $itemsToCompress) {
            if (-not [string]::IsNullOrWhiteSpace($item) -and (Test-Path -Path $item)) {
                $destination = Join-Path -Path $tempStagingPath -ChildPath (Split-Path -Path $item -Leaf)
                Copy-Item -Path $item -Destination $destination -Recurse -Force
            }
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $tempStagingPath,
            $zipFilePath,
            [System.IO.Compression.CompressionLevel]::Optimal,
            $false
        )

        Write-Host "Backup successfully created at: $zipFilePath" -ForegroundColor Green
    }
    finally {
        if (Test-Path -Path $tempStagingPath) {
            Remove-Item -Path $tempStagingPath -Recurse -Force
        }
    }
}

Export-ModuleMember -Function Compress-Profile
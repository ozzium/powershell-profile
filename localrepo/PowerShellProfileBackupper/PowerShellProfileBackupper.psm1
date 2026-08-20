function Compress-Profile {
    param (
        [string]$BackupLocation = "%USERPROFILE%\Documents\PowerShellProfileBackup"
    )

    # Define paths
    $profilePath = $PROFILE.Path
    $repoPath = "%USERPROFILE%\Documents\Github\powershell-profile"  # Change this to your actual repo path
    $customizationsPath = "%USERPROFILE%\Documents\PowerShell"

    # Create a list of paths to compress
    $pathsToCompress = @($profilePath, $repoPath, $customizationsPath)

    # Create backup directory if it doesn't exist
    if (-not (Test-Path -Path $BackupLocation)) {
        New-Item -ItemType Directory -Path $BackupLocation
    }

    # Create the zip file name with timestamp
    $zipFileName = "PowerShellProfileBackup_$(Get-Date -Format 'yyyyMMddHHmmss').zip"
    $zipFilePath = Join-Path -Path $BackupLocation -ChildPath $zipFileName

    # Compress files
    [System.IO.Compression.ZipFile]::CreateFromDirectory($pathsToCompress[1], $zipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

    foreach ($item in $pathsToCompress) {
        if (Test-Path -Path $item) {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($item, $zipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
        }
    }

    Write-Host "Backup created at: $zipFilePath"
}

Export-ModuleMember -Function Compress-Profile
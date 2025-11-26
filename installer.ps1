Write-Host "Installing Oz's PowerShell profile..." -ForegroundColor Cyan

$repoUrl  = "https://github.com/ozzium/powershell-profile.git"
$destPath = Join-Path $HOME "powershell-profile"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning "git is not installed or not in PATH. Please clone $repoUrl manually into $destPath."
    return
}

if (Test-Path $destPath) {
    Write-Host "Existing profile repo detected. Pulling latest..." -ForegroundColor Yellow
    git -C $destPath pull
} else {
    Write-Host "Cloning profile repo..." -ForegroundColor Yellow
    git clone $repoUrl $destPath
}

# Create bootstrap profile that calls the repo loader
$loaderPath = Join-Path $destPath "profile\Microsoft.PowerShell_profile.ps1"

if (-not (Test-Path $loaderPath)) {
    Write-Error "Loader profile not found at $loaderPath"
    return
}

if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak"
    Copy-Item -Path $PROFILE -Destination $backup -Force
    Write-Host "Existing profile backed up to: $backup" -ForegroundColor DarkYellow
}

$bootstrap = @"
# Bootstrap to Oz's PowerShell profile
& "$loaderPath"
"@

$bootstrap | Out-File -FilePath $PROFILE -Encoding UTF8 -Force

Write-Host "Profile installed. Restart PowerShell to use it." -ForegroundColor Green

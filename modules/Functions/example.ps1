function Write-HelloOz {
    param([string]$Name = "Oz")
    Write-Host "Hello, $Name! Your profile modules are loading correctly." -ForegroundColor Cyan
}

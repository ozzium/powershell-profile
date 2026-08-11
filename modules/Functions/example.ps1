function Write-Hello {
    param([string]$Name = "You!")
    Write-Host "Hello, $Name! Your profile modules are loading correctly." -ForegroundColor Cyan
}

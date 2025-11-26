function Show-Help {
    $editor = $global:PSProfileConfig.Editor
    Write-Host ""
    Write-Host "PowerShell Profile Help" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Yellow

    Write-Host "Core:" -ForegroundColor Green
    Write-Host "  Update-Profile           - Update this profile from GitHub"
    Write-Host "  Update-PowerShell        - Check and update PowerShell using winget"
    Write-Host "  ep (Edit-Profile)        - Edit your profile with: $editor"
    Write-Host "  reload-profile           - Reload the current profile"

    Write-Host ""
    Write-Host "Git Shortcuts:" -ForegroundColor Green
    Write-Host "  gs                       - git status"
    Write-Host "  ga                       - git add ."
    Write-Host "  gc ""msg""                 - git commit -m ""msg"""
    Write-Host "  gcom ""msg""               - add + commit"
    Write-Host "  lazyg ""msg""              - add + commit + push"
    Write-Host "  gpush / gpull            - git push / pull"

    Write-Host ""
    Write-Host "Filesystem & Misc:" -ForegroundColor Green
    Write-Host "  touch <file>             - create empty file"
    Write-Host "  nf <file>                - new file in current directory"
    Write-Host "  mkcd <dir>               - make directory then cd into it"
    Write-Host "  docs / dtop              - go to Documents / Desktop"
    Write-Host "  ff <name>                - find files matching name"
    Write-Host "  trash <path>             - send file/dir to Recycle Bin"
    Write-Host "  uptime                   - show system uptime"
    Write-Host "  sysinfo                  - show system info"

    Write-Host ""
    Write-Host "Network & Clipboard:" -ForegroundColor Green
    Write-Host "  flushdns                 - clear DNS cache"
    Write-Host "  Get-PubIP                - show public IP address"
    Write-Host "  cpy ""text""               - copy text to clipboard"
    Write-Host "  pst                      - paste from clipboard"

    Write-Host ""
    Write-Host "Utilities:" -ForegroundColor Green
    Write-Host "  hb <file>                - upload file to hastebin and print URL"
    Write-Host "  Get-Theme                - initialize oh-my-posh cobalt2 theme"
    Write-Host "  Switch-Theme [name]      - switch theme (cobalt2 default)"

    Write-Host ""
    Write-Host "Use 'Show-Help' anytime to see this again." -ForegroundColor Yellow
}

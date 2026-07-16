# Oz's PowerShell Profile

A fast-loading, modular, GitHub-ready PowerShell profile with:

- Lazy-loaded visual goodies (Terminal-Icons, oh-my-posh, zoxide)
- Safe, version-aware `Update-PowerShell`
- `Update-Profile` for pulling latest profile from GitHub
- Git shortcuts, navigation helpers, uptime/system info, hastebin uploader
- Clean structure designed to live in a repo

## Structure

```text
powershell-profile/
  profile/
    Microsoft.PowerShell_profile.ps1
    config.ps1
    init.ps1
    update.ps1
    utils.ps1
    completions.ps1
    appearance.ps1
    help.ps1
  modules/
    Functions/
      example.ps1
    Themes/
      cobalt2-custom.omp.json
  installer.ps1
  README.md
  LICENSE
## To Install:
git clone https://github.com/ozzium/powershell-profile.git
cd powershell-profile
.\installer.ps1

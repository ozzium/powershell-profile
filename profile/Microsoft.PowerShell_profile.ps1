Param()

# Root of the profile folder inside the repo
$ProfileRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $ProfileRoot 'config.ps1')
. (Join-Path $ProfileRoot 'init.ps1')
. (Join-Path $ProfileRoot 'update.ps1')
. (Join-Path $ProfileRoot 'utils.ps1')
. (Join-Path $ProfileRoot 'completions.ps1')
. (Join-Path $ProfileRoot 'appearance.ps1')
. (Join-Path $ProfileRoot 'help.ps1')

# Central configuration object for the profile

if (-not $global:PSProfileConfig) {
    $global:PSProfileConfig = [pscustomobject]@{
        TimeFilePath   = "$HOME\.ps_profile_last_update"
        RepoRootRaw    = 'https://raw.githubusercontent.com/ozzium/powershell-profile/update.ps1'
        UpdateInterval = 7          # days; -1 = always check, big number = rarely
        Editor         = $null      # will auto-detect if null
        Debug          = $false     # set $true to skip update checks etc.
    }
}

# Central configuration object for the profile

if (-not $global:PSProfileConfig) {
    $global:PSProfileConfig = [pscustomobject]@{
        TimeFilePath   = "$HOME\.ps_profile_last_update"
        RepoRootRaw = 'https://raw.githubusercontent.com/ozzium/powershell-profile'
        UpdateInterval = 7          # days; -1 = always check, big number = rarely
        Editor         = $null      # will auto-detect if null
        Debug          = $false     # set $true to skip update checks etc.
    }
}

# Theme preference (oh-my-posh theme name without .omp.json)
if (-not $global:RavenTheme) { $global:RavenTheme = "cobalt2" }

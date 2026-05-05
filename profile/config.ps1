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
# ===============================
# Raven Theme Persistence
# ===============================

# Cross-platform config location (user-local; NOT in git)
$global:RavenConfigPath = Join-Path $HOME ".raven-profile.json"

function Get-RavenConfig {
    if (-not (Test-Path $global:RavenConfigPath)) {
        return @{}
    }

    try {
        $raw = Get-Content -Path $global:RavenConfigPath -Raw
        if (-not $raw.Trim()) { return @{} }
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop

        # Convert PSObject -> Hashtable for easy indexing
        $ht = @{}
        foreach ($p in $obj.PSObject.Properties) { $ht[$p.Name] = $p.Value }
        return $ht
    } catch {
        return @{}
    }
}

function Save-RavenConfig([hashtable]$cfg) {
    try {
        $cfg | ConvertTo-Json -Depth 6 | Set-Content -Path $global:RavenConfigPath -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

# Load theme preference (default is cobalt2)
$cfg = Get-RavenConfig
if ($cfg.ContainsKey("Theme") -and $cfg.Theme) {
    $global:RavenTheme = [string]$cfg.Theme
} else {
    $global:RavenTheme = "cobalt2"
}

# Theme preference (oh-my-posh theme name without .omp.json)
if (-not $global:RavenTheme) { $global:RavenTheme = "cobalt2" }

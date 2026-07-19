function _Should-Run-UpdateChecks {
    param([int]$IntervalDays)

    if ($global:PSProfileConfig.Debug) { return $false }
    if ($IntervalDays -eq -1) { return $true }

    if (-not (Test-Path $global:PSProfileConfig.TimeFilePath)) { return $true }

    try {
        $last = Get-Content -Path $global:PSProfileConfig.TimeFilePath -ErrorAction Stop
        $lastDate = [datetime]::ParseExact($last.Trim(), 'yyyy-MM-dd', $null)
        return ((Get-Date).Date - $lastDate.Date).TotalDays -gt $IntervalDays
    } catch {
        return $true
    }
}

function Update-Profile {
    if (Get-Command -Name "Update-Profile_Override" -ErrorAction SilentlyContinue) {
        Update-Profile_Override
        return
    }

    if (-not $global:PSProfileConfig.RepoRootRaw) {
        Write-Warning "RepoRootRaw is not configured."
        return
    }

    $url  = "$($global:PSProfileConfig.RepoRootRaw)/powershell-profile/profile/Microsoft.PowerShell_profile.ps1"
    $temp = Join-Path $env:TEMP 'Microsoft.PowerShell_profile.ps1'

    try {
        Invoke-RestMethod -Uri $url -OutFile $temp -ErrorAction Stop
    } catch {
        Write-Warning "Profile update failed: $_"
        return
    }

    if (-not (Test-Path $PROFILE)) {
        Copy-Item -Path $temp -Destination $PROFILE
        Write-Host "Profile installed. Restart shell." -ForegroundColor Magenta
        return
    }

    $old = Get-FileHash -Path $PROFILE
    $new = Get-FileHash -Path $temp

    if ($old.Hash -ne $new.Hash) {
        Copy-Item -Path $temp -Destination $PROFILE -Force
        Write-Host "Profile updated. Restart shell." -ForegroundColor Magenta
    } else {
        Write-Host "Profile is up to date." -ForegroundColor Green
    }

    Remove-Item $temp -ErrorAction SilentlyContinue
}

function Update-PowerShell {
    if (Get-Command -Name "Update-PowerShell_Override" -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override
        return
    }

    if ($global:PSProfileConfig.Debug) {
        Write-Verbose "Skipping Update-PowerShell in debug mode"
        return
    }

    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan

        $currentVersion = [version]$PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl   = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
        $latestReleaseInfo = $null

        try {
            $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl -TimeoutSec 10 -ErrorAction Stop
        } catch {
            Write-Warning "Could not query GitHub API for PowerShell releases: $_"
        }

        $latestVersion = $null
        if ($latestReleaseInfo -and $latestReleaseInfo.tag_name) {
            $tag = $latestReleaseInfo.tag_name.TrimStart('v')
            try { $latestVersion = [version]$tag } catch { $latestVersion = $null }
        }

        $updateNeeded = $false
        if ($latestVersion -and ($currentVersion -lt $latestVersion)) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell from $currentVersion to $latestVersion..." -ForegroundColor Yellow
            try {
                Start-Process -FilePath 'powershell.exe' `
                    -ArgumentList "-NoProfile -Command winget upgrade --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" `
                    -Wait -NoNewWindow -ErrorAction Stop
                Write-Host "PowerShell has been updated. Please restart your shell." -ForegroundColor Magenta
            } catch {
                Write-Error "Failed to update PowerShell via winget: $_"
            }
        } else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor Green
        }

    } catch {
        Write-Warning "Failed to determine PowerShell update status: $_"
    }
}

# Run checks periodically, not every launch
if (_Should-Run-UpdateChecks -IntervalDays $global:PSProfileConfig.UpdateInterval) {
    Update-Profile
    Update-PowerShell
    (Get-Date -Format 'yyyy-MM-dd') | Out-File -FilePath $global:PSProfileConfig.TimeFilePath -Force
}

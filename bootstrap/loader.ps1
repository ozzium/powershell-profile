# Raven v3 - Bootstrap Loader

$global:RavenLoaderStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$global:RavenLoadTimings = @()
$global:RavenLoopOverheadTimings = @()
$global:RavenFileLoopTotalMs = 0
$global:RavenLoaderTotalMs = 0

function global:Get-RavenRepoRoot {
    if ($PSScriptRoot) {
        return (Split-Path -Parent $PSScriptRoot)
    }

    return "$HOME\Documents\GitHub\powershell-profile"
}

$repoRoot = Get-RavenRepoRoot
$profileRoot = Join-Path $repoRoot "profile"

if (-not (Test-Path $profileRoot)) {
    Write-Warning "Raven profile folder not found: $profileRoot"
    return
}

$files = @(
    "config.ps1"
    "appearance.ps1"
    "editors.ps1"
    "features.ps1"
    "raven.ps1"
    "dashboard.ps1"
    "git-tools.ps1"
    "menu.ps1"
    "module-manager.ps1"
    "help.ps1"
    "init.ps1"
)

$swFileLoopTotal = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $files) {
    $swWholeItem = [System.Diagnostics.Stopwatch]::StartNew()

    $path = Join-Path $profileRoot $file

    if (-not (Test-Path $path)) {
        Write-Warning "Raven file not found: $file"
        continue
    }

    $swSource = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        . $path
    }
    catch {
        Write-Warning "Failed to load $file`: $($_.Exception.Message)"
    }

    $swSource.Stop()
    $swWholeItem.Stop()

    $global:RavenLoadTimings += [pscustomobject]@{
        File = $file
        Ms   = $swSource.ElapsedMilliseconds
    }

    $global:RavenLoopOverheadTimings += [pscustomobject]@{
        File        = $file
        SourceMs    = $swSource.ElapsedMilliseconds
        WholeItemMs = $swWholeItem.ElapsedMilliseconds
        OverheadMs  = $swWholeItem.ElapsedMilliseconds - $swSource.ElapsedMilliseconds
    }
}

$swFileLoopTotal.Stop()
$global:RavenFileLoopTotalMs = $swFileLoopTotal.ElapsedMilliseconds

# Avoid starting in System32 when elevated on Windows.
try {
    if ($IsWindows -and (Get-Location).Path -like "C:\Windows\System32*") {
        Set-Location $HOME
    }
}
catch {}

function global:raven-loadtime {
    Write-Host "Raven file timings:" -ForegroundColor Cyan

    $global:RavenLoadTimings |
        Sort-Object Ms -Descending |
        Format-Table File, Ms -AutoSize

    Write-Host ""
    Write-Host "Loop overhead timings:" -ForegroundColor Cyan

    $global:RavenLoopOverheadTimings |
        Sort-Object OverheadMs -Descending |
        Format-Table File, SourceMs, WholeItemMs, OverheadMs -AutoSize

    Write-Host ""

    $sum = ($global:RavenLoadTimings | Measure-Object Ms -Sum).Sum

    Write-Host "File timing sum: $sum ms" -ForegroundColor DarkGray
    Write-Host "File loop total: $global:RavenFileLoopTotalMs ms" -ForegroundColor Yellow
    Write-Host "Loader total: $global:RavenLoaderTotalMs ms" -ForegroundColor Yellow
}

$global:RavenLoaderStopwatch.Stop()
$global:RavenLoaderTotalMs = $global:RavenLoaderStopwatch.ElapsedMilliseconds

Write-Host "✔ Raven Core Loaded" -ForegroundColor Green
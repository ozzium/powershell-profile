<#
    UNIVERSAL POWERSELL PROFILE LOADER
    ----------------------------------
    Works in:
      - PowerShell 7+
      - Windows PowerShell 5.1
      - Windows Terminal
      - VSCode Integrated Terminal
      - ISE (if you want)
    Loads your repo-based modular profile with:
      - Auto-detection
      - Fallback scanning
      - Nice error messages
      - No breaking on startup
#>

Write-Host "Loading Oz's Universal PowerShell Profile..." -ForegroundColor Yellow -BackgroundColor DarkMagenta

# ---------------------------------------------------------
# 1. Detect possible repo locations
# ---------------------------------------------------------
$PossibleRoots = @(
    "$HOME\powershell-profile\profile",         # Recommended location
    "$HOME\Documents\powershell-profile\profile", 
    "$HOME\Documents\GitHub\powershell-profile\profile",
    "$HOME\Dev\powershell-profile\profile",
    "$HOME\Source\powershell-profile\profile"
)

# Pick the first one that exists
$ProfileRoot = $PossibleRoots | Where-Object { Test-Path $_ } | Select-Object -First 1

# ---------------------------------------------------------
# 2. If not found, warn gracefully but DO NOT THROW
# ---------------------------------------------------------
if (-not $ProfileRoot) {
    Write-Host ""
    Write-Host "⚠️  WARNING: Your modular profile was not found!" -ForegroundColor Red
    Write-Host "   Expected in one of:" -ForegroundColor Yellow
    $PossibleRoots | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkYellow }
    Write-Host ""
    Write-Host "   Your shell will still start normally." -ForegroundColor Cyan
    Write-Host ""
    return
}

# ---------------------------------------------------------
# 3. List required module files (clean and scalable)
# ---------------------------------------------------------
$Files = @(
    "config.ps1",
    "init.ps1",
    "update.ps1",
    "utils.ps1",
    "completions.ps1",
    "appearance.ps1",
    "help.ps1"
)

# ---------------------------------------------------------
# 4. Load modules safely and beautifully
# ---------------------------------------------------------
foreach ($f in $Files) {
    $path = Join-Path $ProfileRoot $f

    if (Test-Path $path) {
        try {
            . $path
        } catch {
            Write-Host "❌ Failed loading $f: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ Missing file: $path" -ForegroundColor DarkYellow
    }
}

Write-Host "✔ Modular PowerShell profile loaded." -ForegroundColor Green
Write-Host ""

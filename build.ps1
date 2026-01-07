param(
    [string]$ProfileDir = (Join-Path $PSScriptRoot "profile"),
    [string]$OutDir     = (Join-Path $PSScriptRoot "dist"),
    [string]$OutFile    = "RavenProfile.ps1"
)

if (-not (Test-Path $ProfileDir)) {
    throw "ProfileDir not found: $ProfileDir"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$outPath = Join-Path $OutDir $OutFile

# IMPORTANT: order matters (your loader expects these features)
$files = @(
  "config.ps1","utils.ps1","update.ps1","completions.ps1",
  "appearance.ps1","features.ps1","fx.ps1","inline.ps1",
  "shadows.ps1","raven.ps1","dashboard.ps1","menu.ps1",
  "help.ps1","init.ps1"
)

$sb = New-Object System.Text.StringBuilder

$null = $sb.AppendLine("<#")
$null = $sb.AppendLine("  RAVEN SINGLE-FILE BUILD")
$null = $sb.AppendLine("  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$null = $sb.AppendLine("  Source: $ProfileDir")
$null = $sb.AppendLine("#>")
$null = $sb.AppendLine("")

foreach ($f in $files) {
    $p = Join-Path $ProfileDir $f
    if (-not (Test-Path $p)) {
        Write-Warning "Missing: $f"
        continue
    }

    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("# ------------------------------")
    $null = $sb.AppendLine("# BEGIN: $f")
    $null = $sb.AppendLine("# ------------------------------")

    $content = Get-Content -Path $p -Raw -ErrorAction Stop
    $null = $sb.AppendLine($content)

    $null = $sb.AppendLine("# ------------------------------")
    $null = $sb.AppendLine("# END:   $f")
    $null = $sb.AppendLine("# ------------------------------")
}

Set-Content -Path $outPath -Value $sb.ToString() -Encoding UTF8
Write-Host "✅ Built: $outPath" -ForegroundColor Green
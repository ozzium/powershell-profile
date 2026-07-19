# ============================
#    S H A D O W  E X T E N S I O N S
# ============================

# Neon glowing cursor
$Host.UI.RawUI.CursorSize = 100
$Host.PrivateData.ErrorForegroundColor = "Magenta"
$Host.PrivateData.WarningForegroundColor = "DarkMagenta"

function Enable-MatrixRain {
    while ($true) {
        $chars = ("0","1","▮","∙","•")
        $line = -join (1..(Get-Random -Min 30 -Max 70) | ForEach-Object { $chars[Get-Random -Min 0 -Max $chars.Length] })
        Write-Host $line -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds (Get-Random -Min 20 -Max 120)
    }
}

function Start-NeonRipple {
    while ($true) {
        Write-Host (" " * (Get-Random -Min 1 -Max 50)) -BackgroundColor Black `
            -ForegroundColor Blue
        Start-Sleep -Milliseconds 50
    }
}

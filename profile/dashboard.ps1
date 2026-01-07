# ====================================
#       R A V E N   D A S H B O A R D
# ====================================

function global:Raven-Dashboard {
    while ($true) {
        Clear-Host
        Raven-Banner
        Write-Host ""
        Write-Host "╭──────────────────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
        Write-Host "│                    RAVEN DASHBOARD                      │" -ForegroundColor DarkMagenta
        Write-Host "├──────────────────────────────────────────────────────────┤" -ForegroundColor DarkMagenta
        Write-Host "│ 1) Chat with Raven                                       │"
        Write-Host "│ 2) Tasks (view/add/done/clear)                           │"
        Write-Host "│ 3) Memory (view/add)                                     │"
        Write-Host "│ 4) Project Mode Info                                     │"
        Write-Host "│ 5) Git Status (if repo)                                  │"
        Write-Host "│ 6) System Snapshot                                       │"
        Write-Host "│ 7) Exit                                                  │"
        Write-Host "╰──────────────────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
        Write-Host ""
        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host
                Raven-Banner
                $q = Read-Host "Ask Raven"
                if ($q) { raven $q }
                Read-Host "`nPress Enter..."
            }

            "2" {
                Clear-Host
                Raven-Banner
                Write-Host "[Tasks Mode]" -ForegroundColor DarkMagenta
                Raven-Task -Action list
                $sub = Read-Host "`n(a)dd  (d)one  (c)lear  (b)ack"
                switch ($sub) {
                    "a" { Raven-Task add (Read-Host "Task") }
                    "d" { Raven-Task done (Read-Host "Id") }
                    "c" { Raven-Task clear }
                }
            }

            "3" {
                Clear-Host
                Raven-Banner
                Write-Host "[Memory Mode]" -ForegroundColor DarkMagenta
                $memPath = Join-Path $HOME "Documents\raven-memory.json"
                if (Test-Path $memPath) {
                    Get-Content $memPath | Write-Host
                }
                $sub = Read-Host "`n(a)dd  (b)ack"
                if ($sub -eq "a") {
                    Raven-Remember (Read-Host "Note")
                }
            }

            "4" {
                Clear-Host
                Raven-Banner
                $info = Get-RavenPromptSegments
                $info | Format-List
                Read-Host "`nPress Enter..."
            }

            "5" {
                Clear-Host
                Raven-Banner
                git status
                Read-Host "`nPress Enter..."
            }

            "6" {
                Clear-Host
                Raven-Banner
                Write-Host "CPU / RAM Snapshot:" -ForegroundColor Cyan
                Get-Process | Sort-Object CPU -Descending | Select-Object -First 12 |
                    Format-Table -AutoSize
                Read-Host "`nPress Enter..."
            }

            "7" { break }
        }
    }
}

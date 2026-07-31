# Raven v3 - Dashboard
# Lightweight dashboard for Raven core actions.

function global:Get-RavenNotesPath {
    $root = $global:RavenRepoRoot

    if (-not $root) {
        $root = $env:RAVEN_REPO_ROOT
    }

    if (-not $root) {
        $root = $env:RAVEN_PROFILE_ROOT
    }

    if (-not $root) {
        $root = "$HOME\Documents\GitHub\powershell-profile"
    }

    $dataRoot = Join-Path $root "data"

    if (-not (Test-Path $dataRoot)) {
        New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
    }

    Join-Path $dataRoot "raven-notes.json"
}

function global:Get-RavenNotes {
    $path = Get-RavenNotesPath

    if (-not (Test-Path $path)) {
        return @()
    }

    try {
        $items = Get-Content $path -Raw | ConvertFrom-Json

        if ($null -eq $items) {
            return @()
        }

        return @($items)
    }
    catch {
        Write-Warning "Could not read Raven notes: $($_.Exception.Message)"
        return @()
    }
}

function global:Save-RavenNotes {
    param(
        [AllowEmptyCollection()]
        [array]$Notes = @()
    )

    $path = Get-RavenNotesPath

    if ($null -eq $Notes) {
        $Notes = @()
    }

    @($Notes) |
        ConvertTo-Json -Depth 10 |
        Set-Content -Path $path -Encoding UTF8
}

function global:Add-RavenSideNote {
    Clear-Host
    Write-Host "Add Side Note" -ForegroundColor Cyan
    Write-Host ""

    $text = Read-Host "Note"

    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Warning "No note entered."
        Read-Host "Press Enter to continue..."
        return
    }

    $notes = @(Get-RavenNotes)

    $nextId = if ($notes.Count -gt 0) {
        (($notes | Measure-Object -Property Id -Maximum).Maximum) + 1
    }
    else {
        1
    }

    $notes += [pscustomobject]@{
        Id        = [int]$nextId
        CreatedAt = (Get-Date).ToString("s")
        UpdatedAt = (Get-Date).ToString("s")
        Text      = $text
    }

    Save-RavenNotes -Notes $notes

    Write-Host ""
    Write-Host "Note saved." -ForegroundColor Green
    Read-Host "Press Enter to continue..."
}

function global:Show-RavenCommandHistory {
    while ($true) {
        Clear-Host
        Write-Host "Command History" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1) This session"
        Write-Host "2) PSReadLine saved history"
        Write-Host "3) Search saved history"
        Write-Host "4) Back"
        Write-Host ""

        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host
                Write-Host "This Session History" -ForegroundColor Cyan
                Write-Host ""

                Get-History |
                    Select-Object Id, CommandLine |
                    Format-Table -AutoSize

                Read-Host "Press Enter to continue..."
            }

            "2" {
                Clear-Host
                Write-Host "Saved PSReadLine History" -ForegroundColor Cyan
                Write-Host ""

                $historyPath = (Get-PSReadLineOption).HistorySavePath

                if (Test-Path $historyPath) {
                    Get-Content $historyPath -Tail 100
                }
                else {
                    Write-Warning "PSReadLine history file not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "3" {
                Clear-Host
                $query = Read-Host "Search history for"

                if ([string]::IsNullOrWhiteSpace($query)) {
                    continue
                }

                $historyPath = (Get-PSReadLineOption).HistorySavePath

                if (Test-Path $historyPath) {
                    Select-String -Path $historyPath -Pattern $query -SimpleMatch |
                        Select-Object -Last 50 |
                        ForEach-Object { $_.Line }
                }
                else {
                    Write-Warning "PSReadLine history file not found."
                }

                Read-Host "Press Enter to continue..."
            }

            "4" {
                return
            }

            default {
                Write-Warning "Invalid option."
                Read-Host "Press Enter to continue..."
            }
        }
    }
}

function global:Backup-RavenProfileFull {
    Clear-Host
    Write-Host "Full Profile Backup" -ForegroundColor Cyan
    Write-Host ""

    $repoRoot = $global:RavenRepoRoot

    if (-not $repoRoot) {
        $repoRoot = $env:RAVEN_REPO_ROOT
    }

    if (-not $repoRoot) {
        $repoRoot = $env:RAVEN_PROFILE_ROOT
    }

    if (-not $repoRoot -or -not (Test-Path $repoRoot)) {
        Write-Warning "Raven repo root not found."
        Read-Host "Press Enter to continue..."
        return
    }

    $backupRoot = Join-Path $repoRoot "backups"

    if (-not (Test-Path $backupRoot)) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $dest = Join-Path $backupRoot "raven-profile-full-$stamp"

    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    $items = @(
        "bootstrap",
        "profile",
        "modules",
        "themes",
        "data",
        "RAVEN_V3_CONTEXT.md",
        "README.md"
    )

    foreach ($item in $items) {
        $source = Join-Path $repoRoot $item

        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Recurse -Force
        }
    }

		# Back up actual PowerShell user profile folder too.
		$userPowerShellRoot = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell"

		if (Test-Path $userPowerShellRoot) {
			Copy-Item -Path $userPowerShellRoot -Destination (Join-Path $dest "Documents-PowerShell") -Recurse -Force
		}

		# Back up current profile explicitly.
		if (Test-Path $PROFILE) {
			Copy-Item -Path $PROFILE -Destination (Join-Path $dest "Microsoft.PowerShell_profile.ps1") -Force
		}

    # Also back up the actual PowerShell profile stub.
    if (Test-Path $PROFILE) {
        Copy-Item -Path $PROFILE -Destination (Join-Path $dest "Microsoft.PowerShell_profile.ps1") -Force
    }

    Write-Host "Backup created:" -ForegroundColor Green
    Write-Host $dest
    Read-Host "Press Enter to continue..."
}

function global:Manage-RavenNotes {
    while ($true) {
        Clear-Host
        Write-Host "Manage Notes" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1) Show notes"
        Write-Host "2) Edit note"
        Write-Host "3) Delete note"
        Write-Host "4) Back"
        Write-Host ""

        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host
                Write-Host "Raven Notes" -ForegroundColor Cyan
                Write-Host ""

                $notes = @(Get-RavenNotes)

                if ($notes.Count -eq 0) {
                    Write-Host "No notes found." -ForegroundColor DarkGray
                }
                else {
                    $notes |
                        Sort-Object Id |
                        Format-Table Id, CreatedAt, UpdatedAt, Text -Wrap -AutoSize
                }

                Read-Host "Press Enter to continue..."
            }

            "2" {
                Clear-Host
                $notes = @(Get-RavenNotes)

                if ($notes.Count -eq 0) {
                    Write-Warning "No notes to edit."
                    Read-Host "Press Enter to continue..."
                    continue
                }

                $notes | Format-Table Id, Text -Wrap -AutoSize

                $id = Read-Host "Note ID to edit"
                $note = $notes | Where-Object { $_.Id -eq [int]$id } | Select-Object -First 1

                if (-not $note) {
                    Write-Warning "Note not found."
                    Read-Host "Press Enter to continue..."
                    continue
                }

                Write-Host ""
                Write-Host "Current note:" -ForegroundColor DarkGray
                Write-Host $note.Text
                Write-Host ""

                $newText = Read-Host "New text"

                if ([string]::IsNullOrWhiteSpace($newText)) {
                    Write-Warning "No text entered. Note unchanged."
                    Read-Host "Press Enter to continue..."
                    continue
                }

                $note.Text = $newText
                $note.UpdatedAt = (Get-Date).ToString("s")

                Save-RavenNotes -Notes $notes

                Write-Host "Note updated." -ForegroundColor Green
                Read-Host "Press Enter to continue..."
            }

            "3" {
                Clear-Host
                $notes = @(Get-RavenNotes)

                if ($notes.Count -eq 0) {
                    Write-Warning "No notes to delete."
                    Read-Host "Press Enter to continue..."
                    continue
                }

                $notes | Format-Table Id, Text -Wrap -AutoSize

                $id = Read-Host "Note ID to delete"
                $note = $notes | Where-Object { $_.Id -eq [int]$id } | Select-Object -First 1

                if (-not $note) {
                    Write-Warning "Note not found."
                    Read-Host "Press Enter to continue..."
                    continue
                }

                $confirm = Read-Host "Delete note ${id}? Type YES"

                if ($confirm -eq "YES") {
                    $notes = @($notes | Where-Object { $_.Id -ne [int]$id })
                    Save-RavenNotes -Notes $notes
                    Write-Host "Note deleted." -ForegroundColor Yellow
                }
                else {
                    Write-Host "Delete cancelled." -ForegroundColor DarkGray
                }

                Read-Host "Press Enter to continue..."
            }

            "4" {
                return
            }

            default {
                Write-Warning "Invalid option."
                Read-Host "Press Enter to continue..."
            }
        }
    }
}

function global:Invoke-RavenAISearch {
    Clear-Host
    Write-Host "AI Search" -ForegroundColor Cyan
    Write-Host ""

    $query = Read-Host "Search or ask"

    if ([string]::IsNullOrWhiteSpace($query)) {
        return
    }

    $notes = @(Get-RavenNotes)
    $historyPath = $null

    try {
        $historyPath = (Get-PSReadLineOption).HistorySavePath
    }
    catch {}

    $historyMatches = @()

    if ($historyPath -and (Test-Path $historyPath)) {
        $historyMatches = @(Select-String -Path $historyPath -Pattern $query -SimpleMatch -ErrorAction SilentlyContinue |
            Select-Object -Last 20 |
            ForEach-Object { $_.Line })
    }

    $noteMatches = @($notes | Where-Object { $_.Text -like "*$query*" })

    $context = @"
Search query:
$query

Matching notes:
$($noteMatches | ForEach-Object { "[$($_.Id)] $($_.Text)" } | Out-String)

Matching command history:
$($historyMatches | Out-String)
"@

    if (Get-Command Invoke-RavenCore -ErrorAction SilentlyContinue) {
        Invoke-RavenCore -Prompt "Use this Raven local context to answer or summarize the user's search. Be concise.`n`n$context" | Out-Null
    }
    elseif (Get-Command raven -ErrorAction SilentlyContinue) {
        raven "Use this Raven local context to answer or summarize the user's search. Be concise.`n`n$context"
    }
    else {
        Write-Warning "Raven AI command not found. Showing plain search results instead."
        Write-Host ""
        Write-Host $context
    }

    Read-Host "Press Enter to continue..."
}

function global:Raven-Dashboard {
    while ($true) {
        Clear-Host

        Write-Host "╭────────────────────────────────────────╮" -ForegroundColor DarkMagenta
        Write-Host "│             RAVEN COMMAND              │" -ForegroundColor DarkMagenta
        Write-Host "├────────────────────────────────────────┤" -ForegroundColor DarkMagenta
        Write-Host "│ 1) Ask Raven                           │" -ForegroundColor DarkMagenta
        Write-Host "│ 2) Command History                     │" -ForegroundColor DarkMagenta
        Write-Host "│ 3) Full Profile Backup                 │" -ForegroundColor DarkMagenta
        Write-Host "│ 4) Add Side Note                       │" -ForegroundColor DarkMagenta
        Write-Host "│ 5) Manage Notes                        │" -ForegroundColor DarkMagenta
        Write-Host "│ 6) AI Search                           │" -ForegroundColor DarkMagenta
        Write-Host "│ 7) Profile Menu                        │" -ForegroundColor DarkMagenta
        Write-Host "│ 8) Exit                                │" -ForegroundColor DarkMagenta
        Write-Host "╰────────────────────────────────────────╯" -ForegroundColor DarkMagenta
        Write-Host ""

        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                $q = Read-Host "Ask Raven"

                if (-not [string]::IsNullOrWhiteSpace($q)) {
                    if (Get-Command raven -ErrorAction SilentlyContinue) {
                        raven $q
                    }
                    elseif (Get-Command Invoke-RavenCore -ErrorAction SilentlyContinue) {
                        Invoke-RavenCore -Prompt $q | Out-Null
                    }
                    else {
                        Write-Warning "Raven command not found."
                    }
                }

                Read-Host "Press Enter to continue..."
            }

            "2" {
                Show-RavenCommandHistory
            }

            "3" {
                Backup-RavenProfileFull
            }

            "4" {
                Add-RavenSideNote
            }

            "5" {
                Manage-RavenNotes
            }

            "6" {
                Invoke-RavenAISearch
            }

            "7" {
                if (Get-Command profile-menu -ErrorAction SilentlyContinue) {
                    profile-menu
                }
                else {
                    Write-Warning "Profile menu not found."
                    Read-Host "Press Enter to continue..."
                }
            }

            "8" {
                return
            }

            default {
                Write-Warning "Invalid option."
                Read-Host "Press Enter to continue..."
            }
        }
    }
}
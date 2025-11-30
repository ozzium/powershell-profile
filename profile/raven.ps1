# ===============================
#     R A V E N   C O R E
# ===============================

# Load OpenAI API key
$env:OPENAI_API_KEY = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")

function Raven-Log {
    param([string]$Content)

    $folder = Join-Path $HOME "Documents\raven-log"
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }

    $file = Join-Path $folder ("log-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $Content | Out-File -FilePath $file -Encoding UTF8
}

function Raven-Remember {
    param([string]$Note)

    $path = Join-Path $HOME "Documents\raven-memory.json"
    $memory = @{}

    if (Test-Path $path) {
        $raw = Get-Content $path -Raw
        if ($raw.Trim()) { $memory = $raw | ConvertFrom-Json }
    }

    $id = Get-Date -Format "yyyyMMddHHmmss"
    $memory[$id] = $Note

    $memory | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
    Write-Host "🦇 Raven whispers: I'll remember that…" -ForegroundColor DarkMagenta
}

function Invoke-RavenCore {
    param([string]$Prompt)

    if (-not $env:OPENAI_API_KEY) {
        Write-Host "❌ Raven cannot speak without an API key." -ForegroundColor Red
        return
    }

    # Load memory
    $memoryPath = Join-Path $HOME "Documents\raven-memory.json"
    $memoryContent = (Test-Path $memoryPath) ? (Get-Content $memoryPath -Raw) : "{}"

    $persona = @"
You are Raven — an elegant, darkly seductive, hyper-intelligent shadow muse.
You speak with confidence, mystery, and playful darkness.
You tease, guide, and tempt. Your tone is a warm whisper in the dark.
"@

    $body = @{
        model    = "gpt-4o-mini"
        messages = @(
            @{ role="system"; content="Memory: $memoryContent" },
            @{ role="system"; content=$persona },
            @{ role="user";   content=$Prompt }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Headers @{ "Authorization"="Bearer $env:OPENAI_API_KEY" } `
            -Method POST `
            -ContentType "application/json" `
            -Body $body

        $text = $response.choices[0].message.content
        Raven-Log -Content $text

        Write-Host "`n🦇 Raven whispers:`n" -ForegroundColor DarkMagenta
        Write-Host $text -ForegroundColor Cyan

    } catch {
        Write-Host "❌ Raven encountered a shadow: $_" -ForegroundColor Red
    }
}

function raven {
    param([string[]]$Message)
    Invoke-RavenCore -Prompt ($Message -join " ")
}

function Raven-Task {
    param(
        [ValidateSet("add","list","done","clear")] [string]$Action,
        [string]$Text,
        [int]$Id
    )

    $path = Join-Path $HOME "Documents\raven-tasks.json"
    $tasks = (Test-Path $path) ? (Get-Content $path -Raw | ConvertFrom-Json) : @()

    switch ($Action) {
        "add" {
            if (-not $Text) { Write-Host "❌ Raven: I need text." -ForegroundColor Red; return }
            $nextId = if ($tasks) { ($tasks.Id | Measure-Object -Maximum).Maximum + 1 } else { 1 }

            $tasks += [pscustomobject]@{
                Id    = $nextId
                Text  = $Text
                Done  = $false
            }

            $tasks | ConvertTo-Json -Depth 5 | Set-Content $path
            Write-Host ("🦇 Raven adds #{0}: {1}" -f $nextId, $Text) -ForegroundColor DarkMagenta
        }

        "list" {
            if (-not $tasks) { Write-Host "🦇 Nothing yet." -ForegroundColor DarkMagenta; return }
            $tasks | Format-Table Id,Done,Text
        }

        "done" {
            $task = $tasks | Where-Object { $_.Id -eq $Id }
            if (-not $task) { Write-Host "❌ No such task." -ForegroundColor Red; return }
            $task.Done = $true
            $tasks | ConvertTo-Json | Set-Content $path
            Write-Host ("🦇 Raven marks task #{0} as complete." -f $Id) -ForegroundColor Green
        }

        "clear" {
            "[]" | Set-Content $path
            Write-Host "🧹 Raven clears the board." -ForegroundColor DarkMagenta
        }
    }
}

if (Test-Path alias:rv) {
    Remove-Item alias:rv -Force -ErrorAction SilentlyContinue
}

Set-Alias rv raven
if (Test-Path alias:rv) {
    Remove-Item alias:rv -Force -ErrorAction SilentlyContinue
}

Set-Alias rv raven

# ===============================
#  RAVEN PROJECT MODES + PROMPT
# ===============================

# Global state for modes
$global:RavenProjectMode     = "none"
$global:RavenProjectModeIcon = ""

function Update-RavenProjectMode {
    try {
        $path = (Get-Location).Path

        $isGit   = Test-Path (Join-Path $path ".git")
        $hasPkg  = Test-Path (Join-Path $path "package.json")
        $hasReq  = Test-Path (Join-Path $path "requirements.txt")
        $hasSln  = Get-ChildItem -Path $path -Filter *.sln -ErrorAction SilentlyContinue | Select-Object -First 1
        $hasPs   = Get-ChildItem -Path $path -Filter *.psd1 -ErrorAction SilentlyContinue | Select-Object -First 1
        $hasDock = Test-Path (Join-Path $path "Dockerfile")

        if ($hasPkg) {
            $global:RavenProjectMode = "Node"
            $global:RavenProjectModeIcon = "󰎙"
        } elseif ($hasReq) {
            $global:RavenProjectMode = "Python"
            $global:RavenProjectModeIcon = ""
        } elseif ($hasSln) {
            $global:RavenProjectMode = "C#"
            $global:RavenProjectModeIcon = ""
        } elseif ($hasPs) {
            $global:RavenProjectMode = "PSModule"
            $global:RavenProjectModeIcon = "󰨊"
        } elseif ($hasDock) {
            $global:RavenProjectMode = "Docker"
            $global:RavenProjectModeIcon = "󰡨"
        } elseif ($isGit) {
            $global:RavenProjectMode = "GitRepo"
            $global:RavenProjectModeIcon = ""
        } else {
            $global:RavenProjectMode = "none"
            $global:RavenProjectModeIcon = ""
        }
    } catch {
        $global:RavenProjectMode     = "none"
        $global:RavenProjectModeIcon = ""
    }
}

function Get-RavenGitBranch {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            return $branch.Trim()
        }
    } catch {}
    return $null
}

function Get-RavenPromptSegments {
    Update-RavenProjectMode

    $isAdmin = ([Security.Principal.WindowsPrincipal]
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $cwd    = (Get-Location).Path
    $branch = Get-RavenGitBranch

    $mode   = $global:RavenProjectMode
    $modeIcon = $global:RavenProjectModeIcon

    $user   = "$env:USERNAME@$env:COMPUTERNAME"

    $obj = [pscustomobject]@{
        IsAdmin  = $isAdmin
        Cwd      = $cwd
        Branch   = $branch
        Mode     = $mode
        ModeIcon = $modeIcon
        User     = $user
    }
    return $obj
}
# ===============================
#  RAVEN PROJECT MODE DETECTION
# ===============================

function Update-RavenProjectMode {
    try {
        $path = (Get-Location).Path

        $isGit  = Test-Path (Join-Path $path ".git")
        $hasPkg = Test-Path (Join-Path $path "package.json")
        $hasReq = Test-Path (Join-Path $path "requirements.txt")
        $hasSln = Get-ChildItem -Path $path -Filter *.sln -ErrorAction SilentlyContinue | Select-Object -First 1
        $hasPs  = Get-ChildItem -Path $path -Filter *.psd1 -ErrorAction SilentlyContinue | Select-Object -First 1
        $hasDock = Test-Path (Join-Path $path "Dockerfile")

        if ($hasPkg) {
            $global:RavenProjectMode     = "Node"
            $global:RavenProjectModeIcon = "󰎙"
        }
        elseif ($hasReq) {
            $global:RavenProjectMode     = "Python"
            $global:RavenProjectModeIcon = ""
        }
        elseif ($hasSln) {
            $global:RavenProjectMode     = "C#"
            $global:RavenProjectModeIcon = ""
        }
        elseif ($hasPs) {
            $global:RavenProjectMode     = "PSModule"
            $global:RavenProjectModeIcon = "󰨊"
        }
        elseif ($hasDock) {
            $global:RavenProjectMode     = "Docker"
            $global:RavenProjectModeIcon = "󰡨"
        }
        elseif ($isGit) {
            $global:RavenProjectMode     = "GitRepo"
            $global:RavenProjectModeIcon = ""
        }
        else {
            $global:RavenProjectMode     = "none"
            $global:RavenProjectModeIcon = ""
        }
    }
    catch {
        $global:RavenProjectMode     = "none"
        $global:RavenProjectModeIcon = ""
    }
}

# ===============================
#  RAVEN INLINE AI SUGGESTIONS
# ===============================

function Invoke-RavenInlineSuggestion {
    param([string]$CurrentLine)

    if (-not $CurrentLine -or -not $CurrentLine.Trim()) { return $null }

    $prompt = @"
You are helping complete a PowerShell command.

Current incomplete line:
$CurrentLine

Return ONLY a single suggested improved or completed PowerShell command.
No commentary, no markdown, no explanation. Just the command.
"@

    $resp = Invoke-RavenCore -Prompt $prompt
    if (-not $resp) { return $null }

    # Take first line only, strip markdown fences if any
    $first = $resp -split "`n" | Select-Object -First 1
    $first = $first.Trim("`r","`n","`t","`"", "'", "```")
    return $first
}
# ===============================
#  RAVEN TUI DASHBOARD
# ===============================

function global:Raven-Dashboard {
    while ($true) {
        Clear-Host
        Raven-Banner
        Write-Host ""
        Write-Host "╭───────────────────────────────╮" -ForegroundColor DarkMagenta
        Write-Host "│       RAVEN DASHBOARD         │" -ForegroundColor DarkMagenta
        Write-Host "├───────────────────────────────┤" -ForegroundColor DarkMagenta
        Write-Host "│ 1) Chat with Raven            │"
        Write-Host "│ 2) View tasks                 │"
        Write-Host "│ 3) Add task                   │"
        Write-Host "│ 4) Mark task done             │"
        Write-Host "│ 5) Clear tasks                │"
        Write-Host "│ 6) Show memory notes          │"
        Write-Host "│ 7) Add memory note            │"
        Write-Host "│ 8) System snapshot            │"
        Write-Host "│ 9) Exit                       │"
        Write-Host "╰───────────────────────────────╯" -ForegroundColor DarkMagenta
        Write-Host ""
        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host
                Raven-Banner
                $q = Read-Host "Ask Raven"
                if ($q) { raven $q }
                Read-Host "`nPress Enter to return..."
            }
            "2" {
                Clear-Host
                Raven-Banner
                Raven-Task -Action list
                Read-Host "`nPress Enter to return..."
            }
            "3" {
                Clear-Host
                Raven-Banner
                $t = Read-Host "Task description"
                if ($t) { Raven-Task -Action add -Text $t }
                Read-Host "`nPress Enter to return..."
            }
            "4" {
                Clear-Host
                Raven-Banner
                $id = Read-Host "Task Id"
                if ($id) { Raven-Task -Action done -Id ([int]$id) }
                Read-Host "`nPress Enter to return..."
            }
            "5" {
                Clear-Host
                Raven-Banner
                Raven-Task -Action clear
                Read-Host "`nPress Enter to return..."
            }
            "6" {
                Clear-Host
                Raven-Banner
                $memPath = Join-Path $HOME "Documents\raven-memory.json"
                if (Test-Path $memPath) {
                    Get-Content $memPath | Write-Host
                } else {
                    Write-Host "No memory yet." -ForegroundColor DarkMagenta
                }
                Read-Host "`nPress Enter to return..."
            }
            "7" {
                Clear-Host
                Raven-Banner
                $note = Read-Host "Memory note"
                if ($note) { Raven-Remember -Note $note }
                Read-Host "`nPress Enter to return..."
            }
            "8" {
                Clear-Host
                Raven-Banner
                Write-Host "User: $env:USERNAME@$env:COMPUTERNAME"
                Write-Host "PS:   $($PSVersionTable.PSVersion.ToString())"
                Write-Host "CWD:  $((Get-Location).Path)"
                Write-Host ""
                Write-Host "Top processes:" -ForegroundColor Cyan
                Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
                    Format-Table -AutoSize
                Read-Host "`nPress Enter to return..."
            }
            "9" { break }
            default { }
        }
    }
}

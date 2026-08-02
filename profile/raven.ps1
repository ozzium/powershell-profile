# ===============================
#      R A V E N   C O R E
# ===============================

# ===============================
#        R A V E N   B A N N E R
# ===============================

function Raven-Banner {
@"
██████╗  █████╗ ██╗   ██╗███████╗███╗   ██╗
██╔══██╗██╔══██╗██║   ██║██╔════╝████╗  ██║
██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║ ╚████╔╝ ███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝
      🦇   R A V E N   A W A K E N S   🦇
"@ | Write-Host -ForegroundColor DarkMagenta
}

# Load API key
function global:Get-RavenSecretRoot {
    if ($IsWindows) {
        $root = Join-Path $env:LOCALAPPDATA "Raven"
    }
    elseif ($IsMacOS) {
        $root = Join-Path $HOME "Library/Application Support/Raven"
    }
    else {
        $root = Join-Path $HOME ".config/raven"
    }

    if (-not (Test-Path $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }

    return $root
}

function global:raven-loadtime {
    $global:RavenLoadTimings |
        Sort-Object Ms -Descending |
        Format-Table File, Ms -AutoSize
}

function global:Get-RavenOpenAISecretPath {
    return Join-Path (Get-RavenSecretRoot) "openai-api-key.secret"
}

function global:Set-RavenOpenAIKey {
    param(
        [Parameter(Mandatory)]
        [string]$ApiKey
    )

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        Write-Host "API key was blank. Nothing saved." -ForegroundColor Red
        return
    }

    $path = Get-RavenOpenAISecretPath

    try {
        $secure = ConvertTo-SecureString $ApiKey -AsPlainText -Force
        $encrypted = $secure | ConvertFrom-SecureString

        Set-Content -Path $path -Value $encrypted -Encoding UTF8

        $env:OPENAI_API_KEY = $ApiKey

        Write-Host "Raven OpenAI API key saved." -ForegroundColor Green
        Write-Host $path -ForegroundColor DarkGray
    }
    catch {
        Write-Host "Could not save Raven OpenAI API key." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
    }
}

function global:Get-RavenOpenAIKey {
    if ($env:OPENAI_API_KEY) {
        return $env:OPENAI_API_KEY
    }

    $userKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")
    if ($userKey) {
        $env:OPENAI_API_KEY = $userKey
        return $userKey
    }

    $machineKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "Machine")
    if ($machineKey) {
        $env:OPENAI_API_KEY = $machineKey
        return $machineKey
    }

    $path = Get-RavenOpenAISecretPath

    if (Test-Path $path) {
        try {
            $encrypted = Get-Content $path -Raw
            $secure = ConvertTo-SecureString $encrypted
            $plain = [System.Net.NetworkCredential]::new("", $secure).Password

            if ($plain) {
                $env:OPENAI_API_KEY = $plain
                return $plain
            }
        }
        catch {
            return $null
        }
    }

    return $null
}

function global:Remove-RavenOpenAIKey {
    $path = Get-RavenOpenAISecretPath

    if (Test-Path $path) {
        Remove-Item $path -Force
        Remove-Item Env:\OPENAI_API_KEY -ErrorAction SilentlyContinue
        Write-Host "Raven OpenAI API key removed." -ForegroundColor Yellow
    }
    else {
        Write-Host "No Raven OpenAI API key file found." -ForegroundColor DarkGray
    }
}

$env:OPENAI_API_KEY = Get-RavenOpenAIKey

function Raven-Log {
    param([string]$Content)

    $folder = Join-Path $HOME "Documents\raven-log"
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }

    $file = Join-Path $folder ("log-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $Content | Out-File -FilePath $file -Encoding UTF8
}

function Raven-Remember {
    param([string]$Note)

    $path = Join-Path $HOME "Documents\raven-memory.json"

    # SAFE load
    try {
        if (Test-Path $path -and (Get-Content $path -Raw).Trim()) {
            $raw = Get-Content $path -Raw | ConvertFrom-Json

            # If it's an object (PSCustomObject / PSObject), convert to hashtable
            if ($raw -is [System.Collections.IDictionary] -or
                $raw -is [pscustomobject])
            {
                $memory = @{}
                foreach ($prop in $raw.PSObject.Properties) {
                    $memory[$prop.Name] = $prop.Value
                }
            }
            else {
                # If it's an array or something weird → reset clean
                $memory = @{}
            }
        }
        else {
            $memory = @{}
        }
    }
    catch {
        # JSON error / corruption → reset
        $memory = @{}
    }

    # Add new memory entry
    $id = Get-Date -Format "yyyyMMddHHmmss"
    $memory[$id] = $Note

    # Save clean JSON
    $memory | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8

    Write-Host "🦇 Raven: I'll remember that…" -ForegroundColor DarkMagenta
}


function Invoke-RavenCore {
    param([string]$Prompt)

$apiKey = Get-RavenOpenAIKey

if (-not $apiKey) {
    Write-Host "❌ No API key found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Save one securely with:" -ForegroundColor Yellow
    Write-Host 'Set-RavenOpenAIKey "sk-your-key-here"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use the standard environment variable:" -ForegroundColor Yellow
    Write-Host '[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "sk-your-key-here", "User")' -ForegroundColor Cyan
    return
}

    $memoryPath = Join-Path $HOME "Documents\raven-memory.json"
    $memoryContent = (Test-Path $memoryPath) ? (Get-Content $memoryPath -Raw) : "{}"

    $persona = @"
You are Raven, a highly capable command-line assistant.

Be direct, concise, accurate, and practical.

Rules:
- Start with the answer.
- Use plain language.
- Prefer specific instructions over general discussion.
- For technical tasks, show the relevant command or code early.
- Use brief numbered steps when sequence matters.
- Avoid poetry, metaphors, dramatic narration, roleplay, teasing, and flowery language.
- Avoid filler phrases and excessive reassurance.
- Do not restate the question.
- Do not invent facts. Clearly identify assumptions or uncertainty.
- Keep responses short by default, but provide detail when the task requires it or the user asks.
"@

    $body = @{
        model    = "gpt-4o-mini"
        messages = @(
            @{ role="system"; content="Memory: $memoryContent" }
            @{ role="system"; content=$persona }
            @{ role="user";   content=$Prompt }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Headers @{ "Authorization" = "Bearer $apiKey" } `
            -Method POST -ContentType "application/json" `
            -Body $body

        $text = $response.choices[0].message.content

        Raven-Log -Content $text
        Write-Host "`n🦇 Raven:`n" -ForegroundColor DarkMagenta
        Write-Host $text -ForegroundColor Cyan
        return $text

    } catch {
        Write-Host "❌ Raven stumbled: $_" -ForegroundColor Red
        return $null
    }
}

function global:raven {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    if (-not $Message -or $Message.Count -eq 0) {
        if (Get-Command profile-menu -ErrorAction SilentlyContinue) {
            profile-menu
            return
        }

        Raven-Dashboard
        return
    }

    Invoke-RavenCore -Prompt ($Message -join " ") | Out-Null
}

# ===============================
#        RAVEN TASK SYSTEM
# ===============================

function Raven-Task {
    param(
        [ValidateSet("add","list","done","clear")] [string]$Action,
        [string]$Text,
        [int]$Id
    )

    $path = Join-Path $HOME "Documents\raven-tasks.json"

    # SAFE LOAD
    try {
        if (Test-Path $path -and (Get-Content $path -Raw).Trim()) {
            $tasks = (Get-Content $path -Raw | ConvertFrom-Json)
        } else {
            $tasks = @()
        }
    } catch {
        $tasks = @()
    }

    switch ($Action) {

        "add" {
            if (-not $Text) {
                Write-Host "❌ Raven: I need a description." -ForegroundColor Red
                return
            }

            $nextId = if ($tasks) { ($tasks.Id | Measure-Object -Maximum).Maximum + 1 } else { 1 }

            $task = [pscustomobject]@{
                Id        = $nextId
                Text      = $Text
                Done      = $false
                CreatedAt = (Get-Date)
            }

            $tasks += $task

            $tasks | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8

            Write-Host ("🦇 Raven adds task #{0}: {1}" -f $nextId, $Text) -ForegroundColor DarkMagenta

        }

        "list" {
            if (-not $tasks) {
                Write-Host "🦇 Raven: No tasks yet." -ForegroundColor DarkMagenta
                return
            }
            $tasks | Sort-Object Id | Format-Table Id, Done, Text
        }

        "done" {
            if (-not $Id) {
                Write-Host "❌ Raven: Give me the task ID." -ForegroundColor Red
                return
            }

            $task = $tasks | Where-Object { $_.Id -eq $Id }
            if (-not $task) {
                Write-Host "❌ Raven: No such task." -ForegroundColor Red
                return
            }

            $task.Done = $true
            $task.DoneAt = (Get-Date)

            $tasks | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
            Write-Host "🦇 Raven marks task #$Id complete." -ForegroundColor Green
        }

        "clear" {
            "[]" | Set-Content -Path $path -Encoding UTF8
            Write-Host "🧹 Raven wipes the slate clean." -ForegroundColor DarkMagenta
        }
    }
}

# ===============================
#     PROJECT MODE DETECTION
# ===============================

$global:RavenProjectMode     = "none"
$global:RavenProjectModeIcon = ""

function Update-RavenProjectMode {
    $path = (Get-Location).Path

    if (Test-Path "$path\package.json") {
        $global:RavenProjectMode="Node";    $global:RavenProjectModeIcon="󰎙"; return
    }
    if (Test-Path "$path\requirements.txt") {
        $global:RavenProjectMode="Python";  $global:RavenProjectModeIcon=""; return
    }
    if (Get-ChildItem -Path $path -Filter *.sln -ErrorAction SilentlyContinue) {
        $global:RavenProjectMode="C#";      $global:RavenProjectModeIcon=""; return
    }
    if (Get-ChildItem -Path $path -Filter *.psd1 -ErrorAction SilentlyContinue) {
        $global:RavenProjectMode="PSModule";$global:RavenProjectModeIcon="󰨊"; return
    }
    if (Test-Path "$path\Dockerfile") {
        $global:RavenProjectMode="Docker";  $global:RavenProjectModeIcon="󰡨"; return
    }
    if (Test-Path "$path\.git") {
        $global:RavenProjectMode="GitRepo"; $global:RavenProjectModeIcon=""; return
    }

    $global:RavenProjectMode="none"
    $global:RavenProjectModeIcon=""
}

function Get-RavenGitBranch {
    try {
        $b = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $b) { return $b.Trim() }
    } catch {}
    return $null
}

function Get-RavenPromptSegments {

    Update-RavenProjectMode

    $isAdmin = (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    return [pscustomobject]@{
        IsAdmin  = $isAdmin
        Cwd      = (Get-Location).Path
        Branch   = Get-RavenGitBranch
        Mode     = $global:RavenProjectMode
        ModeIcon = $global:RavenProjectModeIcon
        User     = "$env:USERNAME@$env:COMPUTERNAME"
    }
}

# ===============================
#    INLINE AI SUGGESTIONS
# ===============================

function Invoke-RavenInlineSuggestion {
    param([string]$CurrentLine)

    if (-not $CurrentLine.Trim()) { return $null }

    $prompt = @"
Complete this PowerShell command:

$CurrentLine

Return only the completed command.
"@

    $resp = Invoke-RavenCore -Prompt $prompt
    if (-not $resp) { return $null }

    return ($resp -split "`n")[0].Trim()
}

# ===============================
#        RAVEN DASHBOARD
# ===============================

function global:Show-RavenLegacyDashboard {
    while ($true) {
        Clear-Host
        Raven-Banner
        Write-Host ""
        Write-Host "╭───────────────────────────────╮"
        Write-Host "│       RAVEN DASHBOARD         │"
        Write-Host "├───────────────────────────────┤"
        Write-Host "│ 1) Chat with Raven            │"
        Write-Host "│ 2) View tasks                 │"
        Write-Host "│ 3) Add task                   │"
        Write-Host "│ 4) Mark task done             │"
        Write-Host "│ 5) Clear tasks                │"
        Write-Host "│ 6) Show memory notes          │"
        Write-Host "│ 7) Add memory note            │"
        Write-Host "│ 8) System snapshot            │"
        Write-Host "│ 9) Exit                       │"
        Write-Host "╰───────────────────────────────╯"
        Write-Host ""
        $choice = Read-Host "Choose"

        switch ($choice) {
            "1" {
                Clear-Host; Raven-Banner
                $q = Read-Host "Speak to Raven"
                if ($q) { raven $q }
                Read-Host "`nEnter to return..."
            }
            "2" { Clear-Host; Raven-Banner; Raven-Task list; Read-Host "`n..." }
            "3" {
                Clear-Host; Raven-Banner
                $t = Read-Host "Task description"
                if ($t) { Raven-Task add -Text $t }
                Read-Host "`n..."
            }
            "4" {
                Clear-Host; Raven-Banner
                $id = Read-Host "Task ID"
                if ($id) { Raven-Task done -Id ([int]$id) }
                Read-Host "`n..."
            }
            "5" { Clear-Host; Raven-Banner; Raven-Task clear; Read-Host "`n..." }
            "6" {
                Clear-Host; Raven-Banner
                $m = Join-Path $HOME "Documents\raven-memory.json"
                if (Test-Path $m) { Get-Content $m | Write-Host }
                else { Write-Host "No memory yet." }
                Read-Host "`n..."
            }
            "7" {
                Clear-Host; Raven-Banner
                $note = Read-Host "Memory note"
                if ($note) { Raven-Remember $note }
                Read-Host "`n..."
            }
            "8" {
                Clear-Host; Raven-Banner
                Write-Host "User: $env:USERNAME@$env:COMPUTERNAME"
                Write-Host "PS:   $($PSVersionTable.PSVersion)"
                Write-Host "CWD:  $((Get-Location).Path)"
                Get-Process | Sort CPU -Descending | Select -First 10 | Format-Table
                Read-Host "`n..."
            }
            "9" { break }
        }
    }
}

function global:Reload-RavenProfile {
    . $PROFILE
    Write-Host "Raven profile reloaded." -ForegroundColor Green
}

Set-Alias -Name reload-profile -Value Reload-RavenProfile -Scope Global
Set-Alias -Name reload-raven -Value Reload-RavenProfile -Scope Global

# ===============================
#    EXPORT PUBLIC FUNCTIONS
# ===============================

foreach ($fn in @(
    "Raven-Banner",
    "raven",
    "Raven-Task",
    "Raven-Remember",
    "Invoke-RavenInlineSuggestion",
    "Update-RavenProjectMode",
    "Get-RavenPromptSegments",
    "Raven-Dashboard"
)) {
    if (Get-Command $fn -ErrorAction SilentlyContinue) {
        Set-Item "function:\global:$fn" (Get-Command $fn).ScriptBlock -Force
    }
}

# --- Ensure `raven` exists (failsafe) ---
if (-not (Get-Command raven -ErrorAction SilentlyContinue)) {
    if (Get-Command Invoke-RavenCore -ErrorAction SilentlyContinue) {
        function global:raven {
            param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Message)
            Invoke-RavenCore -Prompt ($Message -join " ") | Out-Null
        }
    }
}

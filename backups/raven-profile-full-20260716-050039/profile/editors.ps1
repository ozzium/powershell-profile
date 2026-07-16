<#
==========================================
 Raven Editor Tools
 Cross-platform editor picker/launcher
==========================================
#>

function global:Get-RavenEditorPreferencePath {
    $profileRoot = Get-RavenProfileRoot
    if (-not $profileRoot) {
        return $null
    }

    return Join-Path $profileRoot "editor-preference.json"
}

function global:Get-RavenSavedEditor {
    $path = Get-RavenEditorPreferencePath

    if (-not $path -or -not (Test-Path $path)) {
        return $null
    }

    try {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function global:Save-RavenEditorPreference {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$LaunchMode
    )

    $path = Get-RavenEditorPreferencePath
    if (-not $path) {
        return
    }

    [ordered]@{
        name       = $Name
        command    = $Command
        launchMode = $LaunchMode
    } |
        ConvertTo-Json -Depth 5 |
        Set-Content -Path $path -Encoding UTF8
}

function global:Get-RavenEditorCandidates {
    $editors = @()

    if ($IsWindows) {
        $editors += @(
            [pscustomobject]@{ Name = "VS Code";          Command = "code";          LaunchMode = "command" }
            [pscustomobject]@{ Name = "VS Code Insiders"; Command = "code-insiders"; LaunchMode = "command" }
            [pscustomobject]@{ Name = "Sublime Text";     Command = "subl";          LaunchMode = "command" }
            [pscustomobject]@{ Name = "Phoenix Code";     Command = "phoenix-code";  LaunchMode = "command" }
            [pscustomobject]@{ Name = "Notepad++";        Command = "notepad++";     LaunchMode = "command" }
            [pscustomobject]@{ Name = "Notepad3";         Command = "notepad3";      LaunchMode = "command" }
            [pscustomobject]@{ Name = "TedNPad";          Command = "TedNPad";       LaunchMode = "command" }
            [pscustomobject]@{ Name = "Notepad";          Command = "notepad.exe";   LaunchMode = "command" }
        )

        $windowsPaths = @(
            [pscustomobject]@{ Name = "Notepad++";    Command = "$env:ProgramFiles\Notepad++\notepad++.exe"; LaunchMode = "path" }
            [pscustomobject]@{ Name = "Notepad++";    Command = "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"; LaunchMode = "path" }
            [pscustomobject]@{ Name = "Notepad3";     Command = "$env:ProgramFiles\Notepad3\Notepad3.exe"; LaunchMode = "path" }
            [pscustomobject]@{ Name = "Sublime Text"; Command = "$env:ProgramFiles\Sublime Text\sublime_text.exe"; LaunchMode = "path" }
        )

        foreach ($item in $windowsPaths) {
            if ($item.Command -and (Test-Path $item.Command)) {
                $editors += $item
            }
        }
    }
    elseif ($IsMacOS) {
        $editors += @(
            [pscustomobject]@{ Name = "ZITEXT Editor";    Command = "/Applications/ZITEXT Editor.app"; LaunchMode = "mac-app-path" }
            [pscustomobject]@{ Name = "Zed";              Command = "zed";                            LaunchMode = "command" }
            [pscustomobject]@{ Name = "VS Code";          Command = "code";                           LaunchMode = "command" }
            [pscustomobject]@{ Name = "VS Code Insiders"; Command = "code-insiders";                  LaunchMode = "command" }
            [pscustomobject]@{ Name = "Sublime Text";     Command = "subl";                           LaunchMode = "command" }
            [pscustomobject]@{ Name = "CotEditor";        Command = "CotEditor";                      LaunchMode = "mac-app" }
            [pscustomobject]@{ Name = "TextMate";         Command = "TextMate";                       LaunchMode = "mac-app" }
            [pscustomobject]@{ Name = "TextEdit";         Command = "TextEdit";                       LaunchMode = "mac-app" }
            [pscustomobject]@{ Name = "nano";             Command = "nano";                           LaunchMode = "command" }
            [pscustomobject]@{ Name = "vim";              Command = "vim";                            LaunchMode = "command" }
        )
    }
    else {
        $editors += @(
            [pscustomobject]@{ Name = "VS Code";          Command = "code";          LaunchMode = "command" }
            [pscustomobject]@{ Name = "VS Code Insiders"; Command = "code-insiders"; LaunchMode = "command" }
            [pscustomobject]@{ Name = "Sublime Text";     Command = "subl";          LaunchMode = "command" }
            [pscustomobject]@{ Name = "Kate";             Command = "kate";          LaunchMode = "command" }
            [pscustomobject]@{ Name = "Gedit";            Command = "gedit";         LaunchMode = "command" }
            [pscustomobject]@{ Name = "Xed";              Command = "xed";           LaunchMode = "command" }
            [pscustomobject]@{ Name = "Mousepad";         Command = "mousepad";      LaunchMode = "command" }
            [pscustomobject]@{ Name = "nano";             Command = "nano";          LaunchMode = "command" }
            [pscustomobject]@{ Name = "vim";              Command = "vim";           LaunchMode = "command" }
        )
    }

    $available = @()

    foreach ($editor in $editors) {
        switch ($editor.LaunchMode) {
            "command" {
                if (Get-Command $editor.Command -ErrorAction SilentlyContinue) {
                    $available += $editor
                }
            }

            "path" {
                if (Test-Path $editor.Command) {
                    $available += $editor
                }
            }

            "mac-app" {
                if ($IsMacOS) {
                    $systemApp = "/Applications/$($editor.Command).app"
                    $userApp   = "$HOME/Applications/$($editor.Command).app"

                    if ((Test-Path $systemApp) -or (Test-Path $userApp)) {
                        $available += $editor
                    }
                }
            }

            "mac-app-path" {
                if ($IsMacOS -and (Test-Path $editor.Command)) {
                    $available += $editor
                }
            }
        }
    }

    return $available | Sort-Object Name, Command -Unique
}

function global:Open-RavenFileWithEditor {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $Editor
    )

    if (-not (Test-Path $Path)) {
        Write-Host "File not found: $Path" -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return
    }

    $resolvedPath = (Resolve-Path $Path).Path

    try {
        switch ($Editor.LaunchMode) {
            "command" {
                & $Editor.Command $resolvedPath
            }

            "path" {
                & $Editor.Command $resolvedPath
            }

            "mac-app" {
                & "/usr/bin/open" -a $Editor.Command $resolvedPath
            }

            "mac-app-path" {
                & "/usr/bin/open" -a $Editor.Command $resolvedPath
            }

            default {
                Write-Host "Unknown launch mode: $($Editor.LaunchMode)" -ForegroundColor Red
                Read-Host "Press Enter to continue..."
            }
        }
    }
    catch {
        Write-Host ""
        Write-Host "Editor failed to launch." -ForegroundColor Red
        Write-Host "Editor: $($Editor.Name)" -ForegroundColor Yellow
        Write-Host "Command: $($Editor.Command)" -ForegroundColor Yellow
        Write-Host "Launch mode: $($Editor.LaunchMode)" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
        Read-Host "Press Enter to continue..."
    }
}

function global:Select-RavenEditor {
    param(
        [switch]$AllowSavedDefault
    )

    $editors = @(Get-RavenEditorCandidates)
    $saved = Get-RavenSavedEditor

    if ($editors.Count -eq 0) {
        Write-Host ""
        Write-Host "No supported editors were found." -ForegroundColor Red
        Write-Host "Install one or add its command to PATH." -ForegroundColor Yellow
        Read-Host "Press Enter to continue..."
        return $null
    }

    while ($true) {
        Clear-Host
        Show-RavenMenuHeader

        Write-Host "Select Editor" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkGray
        Write-Host ""

        if ($saved -and $AllowSavedDefault) {
            Write-Host " D) Use default: $($saved.name)" -ForegroundColor Green
            Write-Host ""
        }

        for ($i = 0; $i -lt $editors.Count; $i++) {
            Write-Host ("{0,2}) {1}" -f ($i + 1), $editors[$i].Name)
            Write-Host ("    {0}" -f $editors[$i].Command) -ForegroundColor DarkGray
        }

        Write-Host ""
        Write-Host " B) Back" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select editor"

        if ($choice -match '^(b|back|q|quit)$') {
            return $null
        }

        if ($saved -and $AllowSavedDefault -and $choice -match '^(d|default)$') {
            return [pscustomobject]@{
                Name       = $saved.name
                Command    = $saved.command
                LaunchMode = $saved.launchMode
            }
        }

        [int]$idx = 0
        if (-not [int]::TryParse($choice, [ref]$idx)) {
            continue
        }

        $realIndex = $idx - 1

        if ($realIndex -lt 0 -or $realIndex -ge $editors.Count) {
            continue
        }

        $selected = $editors[$realIndex]

        Write-Host ""
        $remember = Read-Host "Remember $($selected.Name) as default editor? Y/N"

        if ($remember -match '^(y|yes)$') {
            Save-RavenEditorPreference `
                -Name $selected.Name `
                -Command $selected.Command `
                -LaunchMode $selected.LaunchMode
        }

        return $selected
    }
}

function global:Show-RavenEditProfileFiles {
    while ($true) {
        Clear-Host
        Show-RavenMenuHeader

        $profileRoot = Get-RavenProfileRoot
        if (-not $profileRoot) {
            Write-Warning "Profile folder not found."
            Read-Host "Press Enter to continue..."
            return
        }

        $repoRoot = Get-RavenRepoRoot

        $files = @()

        if ($repoRoot) {
            $bootstrap = Join-Path $repoRoot "bootstrap/loader.ps1"
            if (Test-Path $bootstrap) {
                $files += Get-Item $bootstrap
            }
        }

        $files += Get-ChildItem $profileRoot -File |
            Where-Object { $_.Extension -in ".ps1", ".json" } |
            Sort-Object Name

        Write-Host "Edit Profile Files" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $files.Count; $i++) {
            $displayPath = if ($repoRoot) {
                $files[$i].FullName.Replace($repoRoot, "").TrimStart("/", "\")
            }
            else {
                $files[$i].Name
            }

            Write-Host ("{0,2}) {1}" -f ($i + 1), $displayPath)
        }

        Write-Host ""
        Write-Host " B) Back" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Select file number"

        if ($choice -match '^(b|back|q|quit)$') {
            return
        }

        [int]$idx = 0
        if (-not [int]::TryParse($choice, [ref]$idx)) {
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            continue
        }

        $realIndex = $idx - 1

        if ($realIndex -lt 0 -or $realIndex -ge $files.Count) {
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            continue
        }

        $selectedFile = $files[$realIndex]
        $editor = Select-RavenEditor -AllowSavedDefault

        if (-not $editor) {
            continue
        }

        Open-RavenFileWithEditor -Path $selectedFile.FullName -Editor $editor
    }
}

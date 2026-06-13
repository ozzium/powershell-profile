# ==========================================
# Raven Module Manager
# ==========================================

function global:Show-RavenModuleMenu {
    while ($true) {
        Clear-Host
        Write-Host "╭──────────────────────────────────────────────╮" -ForegroundColor DarkMagenta
        Write-Host "│ 🦇 Raven Module Manager                       │" -ForegroundColor Magenta
        Write-Host "╰──────────────────────────────────────────────╯" -ForegroundColor DarkMagenta
        Write-Host ""

        Write-Host "1) Show Installed Modules"
        Write-Host "2) Add module to Raven list manually"
        Write-Host "3) Search PSGallery / Install"
        Write-Host "4) Back"
        Write-Host ""

        $c = Read-Host "Choose"

        switch ($c) {
            "1" { Show-RavenInstalledModulesMenu }

            "2" {
                $n = Read-Host "Module name"
                if ($n) { Add-RavenModule -Name $n }
                [void](Read-Host "Press Enter...")
            }

            "3" { Show-RavenGallerySearchMenu }

            "4" { return }

            default {
                Write-Host "Invalid option." -ForegroundColor Red
                Start-Sleep -Milliseconds 600
            }
        }
    }
}

function global:Get-RavenModulesFile {
    Join-Path $env:RAVEN_PROFILE_ROOT "profile/modules.json"
}

function global:Get-RavenModuleList {
    $file = Get-RavenModulesFile

    if (-not (Test-Path $file)) {
        @() | ConvertTo-Json | Set-Content $file -Encoding UTF8
    }

    try {
        @(Get-Content $file -Raw | ConvertFrom-Json)
    } catch {
        Write-Warning "modules.json is invalid."
        @()
    }
}

function global:Save-RavenModuleList {
    param([array]$Modules)

    $file = Get-RavenModulesFile
    $Modules | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
}

function global:Import-RavenModules {
    $modules = @(Get-RavenModuleList)

    if (-not $modules.Count) {
        Write-Host "No modules listed in modules.json." -ForegroundColor Yellow
        return
    }

    foreach ($m in $modules) {
        $name = [string]$m.Name
        if (-not $name) { continue }

        if (-not $m.Enabled) {
            Write-Host "Skipping disabled module: $name" -ForegroundColor DarkGray
            continue
        }

        Write-Host "Checking module: $name" -ForegroundColor Cyan

        if (-not (Get-Module -ListAvailable -Name $name)) {
            if ($m.InstallIfMissing) {
                try {
                    Write-Host "Installing missing module: $name" -ForegroundColor Yellow
                    Install-Module -Name $name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                } catch {
                    Write-Warning "Could not install $name`: $($_.Exception.Message)"
                    continue
                }
            } else {
                Write-Warning "Module not installed: $name"
                continue
            }
        }

        try {
            Import-Module $name -ErrorAction Stop
            Write-Host "Imported: $name" -ForegroundColor Green
        } catch {
            Write-Warning "Could not import $name`: $($_.Exception.Message)"
        }
    }
}

function global:Add-RavenModule {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$InstallIfMissing,
        [switch]$Disabled
    )

    $modules = @(Get-RavenModuleList)

    if ($modules.Name -contains $Name) {
        Write-Warning "$Name already exists in modules.json."
        return
    }

    $modules += [pscustomobject]@{
        Name             = $Name
        Enabled          = -not $Disabled
        InstallIfMissing = [bool]$InstallIfMissing
    }

    Save-RavenModuleList $modules
    Write-Host "Added module: $Name" -ForegroundColor Green
}

function global:Remove-RavenModule {
    param([Parameter(Mandatory)][string]$Name)

    $modules = @(Get-RavenModuleList) | Where-Object { $_.Name -ne $Name }
    Save-RavenModuleList $modules
    Write-Host "Removed module from Raven list: $Name" -ForegroundColor Yellow
}

function global:Enable-RavenModule {
    param([Parameter(Mandatory)][string]$Name)

    $modules = @(Get-RavenModuleList)
    $found = $false

    foreach ($m in $modules) {
        if ($m.Name -eq $Name) {
            $m.Enabled = $true
            $found = $true
        }
    }

    if (-not $found) {
        $modules += [pscustomobject]@{
            Name             = $Name
            Enabled          = $true
            InstallIfMissing = $false
        }
        Write-Host "Added and enabled: $Name" -ForegroundColor Green
    } else {
        Write-Host "Enabled: $Name" -ForegroundColor Green
    }

    Save-RavenModuleList $modules

    try {
        Import-Module $Name -Force -ErrorAction Stop
        Write-Host "Imported: $Name" -ForegroundColor Green

        $cmds = Get-Command -Module $Name -ErrorAction SilentlyContinue
        if ($cmds) {
            Write-Host "`nAvailable commands:" -ForegroundColor Cyan
            $cmds | Select-Object Name, CommandType | Format-Table -AutoSize
        }
    }
    catch {
        Write-Warning "Enabled in Raven list, but import failed: $($_.Exception.Message)"
    }
}

function global:Disable-RavenModule {
    param([Parameter(Mandatory)][string]$Name)

    $modules = @(Get-RavenModuleList)
    foreach ($m in $modules) {
        if ($m.Name -eq $Name) { $m.Enabled = $false }
    }

    Save-RavenModuleList $modules
    Write-Host "Disabled: $Name" -ForegroundColor Yellow
}

function global:Install-RavenModule {
    param([Parameter(Mandatory)][string]$Name)

    try {
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Host "Installed: $Name" -ForegroundColor Green

        Import-Module $Name -Force -ErrorAction Stop
        Write-Host "Imported: $Name" -ForegroundColor Green

        $cmds = Get-Command -Module $Name -ErrorAction SilentlyContinue

        if ($cmds) {
            Write-Host "`nAvailable commands:" -ForegroundColor Cyan
            $cmds | Select-Object Name, CommandType | Format-Table -AutoSize
        } else {
            Write-Host "`nNo exported commands found for $Name." -ForegroundColor Yellow
        }

        $mods = @(Get-RavenModuleList)
        if ($mods.Name -notcontains $Name) {
            $mods += [pscustomobject]@{
                Name             = $Name
                Enabled          = $true
                InstallIfMissing = $true
            }
            Save-RavenModuleList $mods
            Write-Host "Added to modules.json and enabled." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Install/import failed for $Name`: $($_.Exception.Message)"
    }
}

function global:Uninstall-RavenModule {
    param([Parameter(Mandatory)][string]$Name)

    Uninstall-Module $Name -AllVersions -Force
    Remove-RavenModule $Name
    Write-Host "Uninstalled: $Name" -ForegroundColor Yellow
}

function global:Find-RavenModule {
    param([Parameter(Mandatory)][string]$Name)

    try {
        $results = @(Find-Module -Filter $Name -Repository PSGallery -ErrorAction Stop |
            Select-Object -First 20 Name, Version, Description, Author, ProjectUri)

        if (-not $results -or $results.Count -eq 0) {
            Write-Host "No PSGallery modules found for: $Name" -ForegroundColor Yellow
            return
        }

        $results | Format-Table Name, Version, Description -AutoSize | Out-Host
    } catch {
        Write-Warning "Module search failed: $($_.Exception.Message)"
    }
}

function global:Show-RavenModuleCommands {
    param([Parameter(Mandatory)][string]$Name)

    try {
        Import-Module $Name -Force -ErrorAction Stop
        $cmds = Get-Command -Module $Name -ErrorAction SilentlyContinue

        if (-not $cmds) {
            Write-Host "No exported commands found for: $Name" -ForegroundColor Yellow
            return
        }

        $cmds | Select-Object Name, CommandType, Source | Format-Table -AutoSize
    }
    catch {
        Write-Warning "Could not inspect module $Name`: $($_.Exception.Message)"
    }
}

function global:Show-RavenInstalledModulesMenu {
    while ($true) {
        Clear-Host

        $ravenList = @(Get-RavenModuleList)
        $installed = @(Get-Module -ListAvailable |
            Sort-Object Name, Version -Descending |
            Group-Object Name |
            ForEach-Object { $_.Group | Select-Object -First 1 } |
            Sort-Object Name)

        Write-Host "Installed Modules" -ForegroundColor Cyan
        Write-Host "-----------------"

        for ($i = 0; $i -lt $installed.Count; $i++) {
            $m = $installed[$i]
            $entry = $ravenList | Where-Object { $_.Name -eq $m.Name } | Select-Object -First 1

            $state = if ($entry) {
                if ($entry.Enabled) { "Enabled" } else { "Disabled" }
            } else {
                "Not in Raven"
            }

            "{0,3}) {1,-32} {2,-12} {3}" -f ($i + 1), $m.Name, $m.Version, $state
        }

        Write-Host ""
        Write-Host "Select module number, or B to go back."
        $choice = Read-Host "Module"

        if ($choice -match '^[Bb]$') { return }

        [int]$idx = 0
        if (-not [int]::TryParse($choice, [ref]$idx)) { continue }
        if ($idx -lt 1 -or $idx -gt $installed.Count) { continue }

        Show-RavenInstalledModuleActions -ModuleName $installed[$idx - 1].Name
    }
}

function global:Show-RavenInstalledModuleActions {
    param([Parameter(Mandatory)][string]$ModuleName)

    while ($true) {
        Clear-Host
        Write-Host "Module: $ModuleName" -ForegroundColor Cyan
        Write-Host "------------------------"
        Write-Host "1) Enable Module"
Write-Host "2) Disable Module"
Write-Host "3) Uninstall Module"
Write-Host "4) Show Module Commands and Aliases"
Write-Host "5) Edit Module Aliases"
Write-Host "6) Update Module"
Write-Host "7) Back"
        Write-Host ""

        $c = Read-Host "Choose"

        switch ($c) {
    "1" {
        Enable-RavenModule $ModuleName
        [void](Read-Host "Press Enter...")
    }

    "2" {
        Disable-RavenModule $ModuleName
        [void](Read-Host "Press Enter...")
    }

    "3" {
        $confirm = Read-Host "Uninstall $ModuleName? y/n"
        if ($confirm -match '^[Yy]') {
            Uninstall-RavenModule $ModuleName
            [void](Read-Host "Press Enter...")
            return
        }
    }

    "4" {
        Show-RavenModuleCommandsAndAliases $ModuleName
        [void](Read-Host "Press Enter...")
    }

    "5" {
        Edit-RavenModuleAliases
    }

    "6" {
        try {
            Update-Module -Name $ModuleName -Force -ErrorAction Stop
            Write-Host "Updated: $ModuleName" -ForegroundColor Green
        } catch {
            Write-Warning "Update failed: $($_.Exception.Message)"
        }
        [void](Read-Host "Press Enter...")
    }

    "7" { return }
}
    }
}


function global:ConvertFrom-RavenGalleryApiEntry {
    param([Parameter(Mandatory)]$Entry)

    $props = $Entry.properties

    if (-not $props) {
        $props = $Entry.content.properties
    }

    if (-not $props) {
        return $null
    }

    $name = [string]$props.Id
    if (-not $name) { $name = [string]$Entry.title }

    if (-not $name) {
        return $null
    }

    [pscustomobject]@{
        Name        = $name
        Version     = [string]$props.Version
        Description = [string]$props.Description
        Author      = [string]$props.Authors
        ProjectUri  = [string]$props.ProjectUrl
    }
}

function global:ConvertTo-RavenGalleryResult {
    param([Parameter(Mandatory)]$Module)

    $projectUri = $null
    if ($Module.PSObject.Properties.Name -contains "ProjectUri") {
        $projectUri = $Module.ProjectUri
    }
    elseif ($Module.PSObject.Properties.Name -contains "ProjectUrl") {
        $projectUri = $Module.ProjectUrl
    }

    [pscustomobject]@{
        Name        = [string]$Module.Name
        Version     = [string]$Module.Version
        Description = [string]$Module.Description
        Author      = [string]$Module.Author
        ProjectUri  = [string]$projectUri
    }
}

function global:Search-RavenPSGalleryModules {
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [int]$First = 30
    )

    $q = $Query.Trim()
    if ([string]::IsNullOrWhiteSpace($q)) {
        return @()
    }

    $all = @()

    # Fast path for modern PowerShellGet/PSResourceGet.
    # This is usually quicker and richer than the older Find-Module search provider.
    if (Get-Command Find-PSResource -ErrorAction SilentlyContinue) {
        try {
            $all += @(Find-PSResource -Name $q -Repository PSGallery -Type Module -ErrorAction SilentlyContinue |
                ForEach-Object { ConvertTo-RavenGalleryResult $_ })
        }
        catch {}

        try {
            $all += @(Find-PSResource -Name "*$q*" -Repository PSGallery -Type Module -ErrorAction SilentlyContinue |
                Select-Object -First $First |
                ForEach-Object { ConvertTo-RavenGalleryResult $_ })
        }
        catch {}
    }

    # Compatibility path for older PowerShellGet.
    if (Get-Command Find-Module -ErrorAction SilentlyContinue) {
        try {
            $all += @(Find-Module -Name $q -Repository PSGallery -ErrorAction SilentlyContinue |
                ForEach-Object { ConvertTo-RavenGalleryResult $_ })
        }
        catch {}

        try {
            $all += @(Find-Module -Name "*$q*" -Repository PSGallery -ErrorAction SilentlyContinue |
                Select-Object -First $First |
                ForEach-Object { ConvertTo-RavenGalleryResult $_ })
        }
        catch {}
    }

    $all |
        Where-Object { $_ -and $_.Name } |
        Sort-Object Name -Unique |
        Select-Object -First $First
}

function global:Show-RavenGallerySearchMenu {
    while ($true) {
        Clear-Host
        Write-Host "Search PSGallery / Install" -ForegroundColor Cyan
        Write-Host "--------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Tip: try exact names like Pester, or broad terms like git, excel, az, terminal, posh." -ForegroundColor DarkGray
        Write-Host ""

        $q = Read-Host "Search PSGallery"
        if ([string]::IsNullOrWhiteSpace($q)) { return }

        Write-Host ""
        Write-Host "Searching PSGallery for '$q'..." -ForegroundColor Yellow

        $results = @(Search-RavenPSGalleryModules -Query $q -First 20)

        if (-not $results -or $results.Count -eq 0) {
            Write-Host ""
            Write-Host "No modules found for: $q" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Diagnostics:" -ForegroundColor Cyan

            $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            if ($repo) {
                Write-Host "PSGallery registered: Yes" -ForegroundColor Green
                Write-Host "Source: $($repo.SourceLocation)" -ForegroundColor DarkGray
                Write-Host "Policy: $($repo.InstallationPolicy)" -ForegroundColor DarkGray
            }
            else {
                Write-Host "PSGallery registered: No" -ForegroundColor Red
                Write-Host "Run: Register-PSRepository -Default" -ForegroundColor Cyan
            }

            $probe = Find-Module -Name Pester -Repository PSGallery -ErrorAction SilentlyContinue
            if ($probe) {
                Write-Host "Known-module test: Pester found" -ForegroundColor Green
                Write-Host "So PSGallery works, but search providers are being picky." -ForegroundColor DarkGray
            }
            else {
                Write-Host "Known-module test: Pester not found" -ForegroundColor Red
                Write-Host "Run: Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" -ForegroundColor Cyan
            }

            [void](Read-Host "Press Enter...")
            continue
        }

        Clear-Host
        Write-Host "Search Results" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $results.Count; $i++) {
            $r = $results[$i]
            $desc = [string]$r.Description
            if ($desc.Length -gt 80) { $desc = $desc.Substring(0,80) + "..." }

            "{0,3}) {1,-30} {2,-12} {3}" -f ($i + 1), $r.Name, $r.Version, $desc
        }

        Write-Host ""
        Write-Host "Select result number, or B to go back."
        $choice = Read-Host "Module"

        if ($choice -match '^[Bb]$') { return }

        [int]$idx = 0
        if (-not [int]::TryParse($choice, [ref]$idx)) { continue }
        if ($idx -lt 1 -or $idx -gt $results.Count) { continue }

        Show-RavenGalleryModuleActions -Module $results[$idx - 1]
    }
}

function global:Show-RavenGalleryModuleActions {
    param([Parameter(Mandatory)]$Module)

    while ($true) {
        Clear-Host
        Write-Host "Module: $($Module.Name)" -ForegroundColor Cyan
        Write-Host "Version: $($Module.Version)"
        Write-Host "Author:  $($Module.Author)"
        Write-Host ""
        Write-Host $Module.Description
        Write-Host ""
        Write-Host "1) Select and Install"
        Write-Host "2) Show Module Commands and Aliases"
        Write-Host "3) Show Module Homepage"
        Write-Host "4) Back"
        Write-Host ""

        $c = Read-Host "Choose"

        switch ($c) {
            "1" {
                Install-RavenModule $Module.Name
                [void](Read-Host "Press Enter...")
            }

            "2" {
                if (-not (Get-Module -ListAvailable -Name $Module.Name)) {
                    $install = Read-Host "$($Module.Name) is not installed. Install first? y/n"
                    if ($install -match '^[Yy]') {
                        Install-RavenModule $Module.Name
                    } else {
                        continue
                    }
                }

                Show-RavenModuleCommandsAndAliases $Module.Name
                [void](Read-Host "Press Enter...")
            }

            "3" {
                if ($Module.ProjectUri) {
                    Start-Process $Module.ProjectUri
                } else {
                    Start-Process "https://www.powershellgallery.com/packages/$($Module.Name)"
                }
            }

            "4" { return }
        }
    }
}

function global:Show-RavenModuleCommandsAndAliases {
    param([Parameter(Mandatory)][string]$ModuleName)

    try {
        Import-Module $ModuleName -Force -ErrorAction Stop

        Write-Host "Commands from $ModuleName" -ForegroundColor Cyan
        Write-Host "------------------------"

        $cmds = @(Get-Command -Module $ModuleName -ErrorAction SilentlyContinue)
        if ($cmds.Count) {
            $cmds | Select-Object Name, CommandType, Source | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host "No exported commands found." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "Aliases pointing to this module:" -ForegroundColor Cyan

        $aliases = @(Get-Alias | Where-Object {
            $cmd = Get-Command $_.Definition -ErrorAction SilentlyContinue
            $cmd -and $cmd.Source -eq $ModuleName
        })

        if ($aliases.Count) {
            $aliases | Select-Object Name, Definition | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host "No aliases found." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "Could not inspect module $ModuleName`: $($_.Exception.Message)"
    }
}

function global:Get-RavenModuleAliasesFile {
    Join-Path $env:RAVEN_PROFILE_ROOT "profile/module-aliases.json"
}

function global:Edit-RavenModuleAliases {
    $file = Get-RavenModuleAliasesFile

    if (-not (Test-Path $file)) {
@"
{
  "UltraTree": [
    {
      "Alias": "utree",
      "Command": "Replace-With-Actual-Command"
    }
  ]
}
"@ | Set-Content $file -Encoding UTF8
    }

    if (Get-Command e -ErrorAction SilentlyContinue) {
        e $file
    } elseif (Get-Command code -ErrorAction SilentlyContinue) {
        code $file
    } else {
        Write-Host "Aliases file: $file"
    }
}
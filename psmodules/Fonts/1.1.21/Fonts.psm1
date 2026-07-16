[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidAssignmentToAutomaticVariable', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[CmdletBinding()]
param()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Import-PowerShellDataFile -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"

if ($PSEdition -eq 'Desktop') {
    $IsWindows = $true
}

#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [Get-Font]
Write-Debug "[$scriptName] - [functions] - [public] - [Get-Font] - Importing"
#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.6' }

function Get-Font {
    <#
        .SYNOPSIS
        Retrieves the installed fonts.

        .DESCRIPTION
        Retrieves a list of installed fonts for the current user or all users, depending on the specified scope.
        Supports filtering by font name using wildcards.

        .EXAMPLE
        Get-Font

        Output:
        ```powershell
        Name     Path                             Scope
        ----     ----                             -----
        Arial    C:\Windows\Fonts\arial.ttf       CurrentUser
        ```

        Gets all the fonts installed for the current user.

        .EXAMPLE
        Get-Font -Name 'Arial*'

        Output:
        ```powershell
        Name       Path                                Scope
        ----       ----                                -----
        Arial      C:\Windows\Fonts\arial.ttf          CurrentUser
        Arial Bold C:\Windows\Fonts\arialbd.ttf        CurrentUser
        ```

        Gets all the fonts installed for the current user that start with 'Arial'.

        .EXAMPLE
        Get-Font -Scope 'AllUsers'

        Output:
        ```powershell
        Name      Path                               Scope
        ----      ----                               -----
        Calibri   C:\Windows\Fonts\calibri.ttf       AllUsers
        ```

        Gets all the fonts installed for all users.

        .EXAMPLE
        Get-Font -Name 'Calibri' -Scope 'AllUsers'

        Output:
        ```powershell
        Name     Path                               Scope
        ----     ----                               -----
        Calibri  C:\Windows\Fonts\calibri.ttf       AllUsers
        ```

        Gets the font with the name 'Calibri' for all users.

        .OUTPUTS
        System.Collections.Generic.List[PSCustomObject]

        .NOTES
        Returns a list of installed fonts.
        Each font object contains properties:
        - Name: The font name.
        - Path: The full file path to the font.
        - Scope: The scope from which the font is retrieved.

        .LINK
        https://psmodule.io/Fonts/Functions/Get-Font/
    #>
    [Alias('Get-Fonts')]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    [CmdletBinding()]
    param(
        # Specifies the name of the font to get.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # Specifies the scope of the font(s) to get.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser'
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"
    }

    process {
        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scope(s)"
        foreach ($scopeName in $Scope) {

            Write-Verbose "[$functionName] - [$scopeName] - Getting font(s)"
            $fontFolderPath = $script:FontFolderPathMap[$script:OS][$scopeName]
            Write-Verbose "[$functionName] - [$scopeName] - Font folder path: [$fontFolderPath]"
            $folderExists = Test-Path -Path $fontFolderPath
            Write-Verbose "[$functionName] - [$scopeName] - Folder exists: [$folderExists]"
            if (-not $folderExists) {
                return $fonts
            }
            $installedFonts = Get-ChildItem -Path $fontFolderPath -File
            $installedFontsCount = $($installedFonts.Count)
            Write-Verbose "[$functionName] - [$scopeName] - Filtering from [$installedFontsCount] font(s)"
            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Filtering based on [$nameCount] name pattern(s)"
            foreach ($fontFilter in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Filtering font(s)"
                $filteredFonts = $installedFonts | Where-Object { $_.BaseName -like $fontFilter }
                foreach ($fontItem in $filteredFonts) {
                    $fontName = $fontItem.BaseName
                    $fontPath = $fontItem.FullName
                    $fontScope = $scopeName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Found [$fontName] at [$fontPath]"

                    [PSCustomObject]@{
                        Name  = $fontName
                        Path  = $fontPath
                        Scope = $fontScope
                    }
                }
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Done"
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {}
}
Write-Debug "[$scriptName] - [functions] - [public] - [Get-Font] - Done"
#endregion [functions] - [public] - [Get-Font]
#region    [functions] - [public] - [Install-Font]
Write-Debug "[$scriptName] - [functions] - [public] - [Install-Font] - Importing"
#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.6' }

function Install-Font {
    <#
        .SYNOPSIS
        Installs a font in the system.

        .DESCRIPTION
        Installs a font in the system, either for the current user or all users, depending on the specified scope.
        If the font is already installed, it can be optionally overwritten using the `-Force` parameter.
        The function supports both single file installations and batch installations via pipeline input.

        Installing fonts for all users requires administrator privileges.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf

        Output:
        ```powershell
        Arial.ttf installed for the current user.
        ```

        Installs the font file `Arial.ttf` for the current user.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers

        Output:
        ```powershell
        Arial.ttf installed for all users.
        ```

        Installs the font file `Arial.ttf` system-wide, making it available to all users.
        This requires administrator rights.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf -Force

        Output:
        ```powershell
        Arial.ttf reinstalled for the current user.
        ```

        Installs the font file `Arial.ttf` for the current user. If it already exists, it will be overwritten.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers -Force

        Output:
        ```powershell
        Arial.ttf reinstalled for all users.
        ```

        Installs the font file `Arial.ttf` system-wide and overwrites the existing font if present.

        .EXAMPLE
        Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font

        Output:
        ```powershell
        Found 3 font files.
        Arial.ttf installed for the current user.
        Verdana.ttf installed for the current user.
        TimesNewRoman.ttf installed for the current user.
        ```

        Installs all `.ttf` font files found in `C:\FontFiles\` for the current user.

        .EXAMPLE
        Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers

        Output:
        ```powershell
        Found 3 font files.
        Arial.ttf installed for all users.
        Verdana.ttf installed for all users.
        TimesNewRoman.ttf installed for all users.
        ```

        Installs all `.ttf` font files found in `C:\FontFiles\` system-wide.
        This requires administrator rights.

        .EXAMPLE
        Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers -Force

        Output:
        ```powershell
        Found 3 font files.
        Arial.ttf reinstalled for all users.
        Verdana.ttf reinstalled for all users.
        TimesNewRoman.ttf reinstalled for all users.
        ```

        Installs all `.ttf` font files found in `C:\FontFiles\` system-wide, overwriting existing fonts.
        This requires administrator rights.

        .OUTPUTS
        System.String

        .NOTES
        Returns messages indicating success or failure of font installation.

        .LINK
        https://psmodule.io/Fonts/Functions/Install-Font/
    #>
    [Alias('Install-Fonts')]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # File or folder path(s) to the font(s) to install.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FullName')]
        [string[]] $Path,

        # Scope of the font installation.
        # CurrentUser will install the font for the current user only.
        # AllUsers will install the font so it is available for all users on the system.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser',

        # Recurse will install all fonts in the specified folder and subfolders.
        [Parameter()]
        [switch] $Recurse,

        # Force will overwrite existing fonts.
        [Parameter()]
        [switch] $Force
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        if ($Scope -contains 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @"
Administrator rights are required to install fonts in [$($script:FontFolderPathMap[$script:OS]['AllUsers'])].
Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command.
"@
            throw $errorMessage
        }
        $maxRetries = 10
        $retryIntervalSeconds = 1
    }

    process {
        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scopes(s)"
        foreach ($scopeName in $Scope) {
            $fontDestinationFolderPath = $script:FontFolderPathMap[$script:OS][$scopeName]
            $pathCount = $Path.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$pathCount] path(s)"
            foreach ($PathItem in $Path) {
                Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Processing"
                $pathExists = Test-Path -Path $PathItem -ErrorAction SilentlyContinue
                if (-not $pathExists) {
                    Write-Error "[$functionName] - [$scopeName] - [$PathItem] - Path not found, skipping."
                    continue
                }
                $item = Get-Item -Path $PathItem -ErrorAction Stop

                if ($item.PSIsContainer) {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Folder found"
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Gathering font(s) to install"
                    $fontFiles = Get-ChildItem -Path $item.FullName -ErrorAction Stop -File -Recurse:$Recurse
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Found [$($fontFiles.Count)] font file(s)"
                } else {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - File found"
                    $fontFiles = $Item
                }

                foreach ($fontFile in $fontFiles) {
                    $fontFileName = $fontFile.Name
                    $fontName = $fontFile.BaseName
                    $fontFilePath = $fontFile.FullName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Processing"

                    # Check if font is supported
                    $fontExtension = $fontFile.Extension.ToLower()
                    $supportedFont = $script:SupportedFonts | Where-Object { $_.Extension -eq $fontExtension }
                    if (-not $supportedFont) {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Font type [$fontExtension] is not supported. Skipping."
                        continue
                    }

                    $folderExists = Test-Path -Path $fontDestinationFolderPath -ErrorAction SilentlyContinue
                    if (-not $folderExists) {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Creating folder [$fontDestinationFolderPath]"
                        $null = New-Item -Path $fontDestinationFolderPath -ItemType Directory -Force
                    }
                    $fontDestinationFilePath = Join-Path -Path $fontDestinationFolderPath -ChildPath $fontFileName
                    $fontFileAlreadyInstalled = Test-Path -Path $fontDestinationFilePath
                    if ($fontFileAlreadyInstalled) {
                        if ($Force) {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Already installed. Forcing install."
                        } else {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Already installed. Skipping."
                            continue
                        }
                    }

                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Installing font"

                    $retryCount = 0
                    $fileCopied = $false

                    do {
                        try {
                            $null = $fontFile.CopyTo($fontDestinationFilePath)
                            $fileCopied = $true
                        } catch {
                            $retryCount++
                            if (-not $fileRemoved -and $retryCount -eq $maxRetries) {
                                Write-Error $_
                                Write-Error "Failed [$retryCount/$maxRetries] - Stopping"
                                break
                            }
                            Write-Verbose "Failed [$retryCount/$maxRetries] - Retrying in $retryIntervalSeconds seconds..."
                            Start-Sleep -Seconds $retryIntervalSeconds
                        }
                    } while (-not $fileCopied -and $retryCount -lt $maxRetries)

                    if (-not $fileCopied) {
                        continue
                    }
                    if ($script:OS -eq 'Windows') {
                        $fontType = $script:SupportedFonts | Where-Object { $_.Extension -eq $fontExtension } | Select-Object -ExpandProperty Type
                        $registeredFontName = "$fontName ($fontType)"
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Registering font as [$registeredFontName]"
                        $regValue = if ('AllUsers' -eq $Scope) { $fontFileName } else { $fontDestinationFilePath }
                        $params = @{
                            Name         = $registeredFontName
                            Path         = $script:FontRegPathMap[$scopeName]
                            PropertyType = 'string'
                            Value        = $regValue
                            Force        = $true
                            ErrorAction  = 'Stop'
                        }
                        $null = New-ItemProperty @params
                    }
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Done"
                }
                if ($item.PSIsContainer) {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Done"
                }
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        if ($IsLinux) {
            if ($Verbose) {
                Write-Verbose 'Refreshing font cache'
                fc-cache -fv
            } else {
                fc-cache -f
            }
        }
        Write-Verbose "[$functionName] - Done"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Install-Font] - Done"
#endregion [functions] - [public] - [Install-Font]
#region    [functions] - [public] - [Uninstall-Font]
Write-Debug "[$scriptName] - [functions] - [public] - [Uninstall-Font] - Importing"
#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.6' }

function Uninstall-Font {
    <#
        .SYNOPSIS
        Uninstalls a font from the system.

        .DESCRIPTION
        Uninstalls a font from the system. The function supports removing fonts for either the current user
        or all users. If attempting to remove a font for all users, administrative privileges are required.
        The function ensures font files are deleted, and if on Windows, it also unregisters fonts from the registry.

        .EXAMPLE
        Uninstall-Font -Name 'Courier New'

        Output:
        ```powershell
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Processing
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Removing file [C:\Windows\Fonts\cour.ttf]
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Unregistering font [Courier New]
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Done
        ```

        Uninstalls the 'Courier New' font from the system for the current user.

        .EXAMPLE
        Uninstall-Font -Name 'Courier New' -Scope AllUsers

        Output:
        ```powershell
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Processing
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Removing file [C:\Windows\Fonts\cour.ttf]
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Unregistering font [Courier New]
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Done
        ```

        Uninstalls the 'Courier New' font from the system for all users. Requires administrative privileges.

        .OUTPUTS
        None

        .NOTES
        The function does not return any objects.

        .LINK
        https://psmodule.io/Fonts/Functions/Uninstall-Font/
    #>
    [Alias('Uninstall-Fonts')]
    [CmdletBinding()]
    param (
        # Name of the font to uninstall.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name,

        # Scope of the font to uninstall.
        # CurrentUser will uninstall the font for the current user.
        # AllUsers will uninstall the font so it is removed for all users.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser'
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        if ($Scope -contains 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @"
Administrator rights are required to uninstall fonts in [$($script:FontFolderPath['AllUsers'])].
Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command.
"@
            throw $errorMessage
        }
        $maxRetries = 10
        $retryIntervalSeconds = 1
    }

    process {
        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scopes(s)"
        foreach ($scopeName in $Scope) {
            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$nameCount] font(s)"
            foreach ($fontName in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Processing"
                $fonts = Get-Font -Name $fontName -Scope $Scope
                Write-Verbose ($fonts | Out-String)
                foreach ($font in $fonts) {

                    $filePath = $font.Path

                    $fileExists = Test-Path -Path $filePath -ErrorAction SilentlyContinue
                    if (-not $fileExists) {
                        Write-Warning "[$functionName] - [$scopeName] - [$fontName] - File [$filePath] does not exist. Skipping."
                    } else {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Removing file [$filePath]"
                        $retryCount = 0
                        $fileRemoved = $false
                        do {
                            try {
                                Remove-Item -Path $filePath -Force -ErrorAction Stop
                                $fileRemoved = $true
                            } catch {
                                # Common error; 'file in use'.
                                $retryCount++
                                if (-not $fileRemoved -and $retryCount -eq $maxRetries) {
                                    Write-Error $_
                                    Write-Error "Failed [$retryCount/$maxRetries] - Stopping"
                                    break
                                }
                                Write-Verbose $_
                                Write-Verbose "Failed [$retryCount/$maxRetries] - Retrying in $retryIntervalSeconds seconds..."
                                #TODO: Find a way to try to unlock file here.
                                Start-Sleep -Seconds $retryIntervalSeconds
                            }
                        } while (-not $fileRemoved -and $retryCount -lt $maxRetries)

                        if (-not $fileRemoved) {
                            break  # Break to skip unregistering the font if the file could not be removed.
                        }
                    }

                    if ($script:OS -eq 'Windows') {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Searching for font in registry"
                        $keys = Get-ItemProperty -Path $script:FontRegPathMap[$scopeName]
                        $key = $keys.PSObject.Properties | Where-Object { $_.Value -eq $filePath }
                        if (-not $key) {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Font is not registered. Skipping."
                        } else {
                            $keyName = $key.Name
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Unregistering font [$keyName]"
                            Remove-ItemProperty -Path $script:FontRegPathMap[$scopeName] -Name $keyName -Force -ErrorAction Stop
                        }
                    }
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Done"
                }
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        if ($IsLinux) {
            if ($Verbose) {
                Write-Verbose 'Refreshing font cache'
                fc-cache -fv
            } else {
                fc-cache -f
            }
        }
        Write-Verbose "[$functionName] - Done"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Uninstall-Font] - Done"
#endregion [functions] - [public] - [Uninstall-Font]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]
#region    [variables] - [private]
Write-Debug "[$scriptName] - [variables] - [private] - Processing folder"
#region    [variables] - [private] - [common]
Write-Debug "[$scriptName] - [variables] - [private] - [common] - Importing"
$script:FontRegPathMap = @{
    CurrentUser = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    AllUsers    = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
}

$script:FontFolderPathMap = @{
    'Windows' = @{
        CurrentUser = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        AllUsers    = "$($env:windir)\Fonts"
    }
    'MacOS'   = @{
        CurrentUser = "$env:HOME/Library/Fonts"
        AllUsers    = '/Library/Fonts'
    }
    'Linux'   = @{
        CurrentUser = "$env:HOME/.fonts"
        AllUsers    = '/usr/share/fonts'
    }
}

$script:OS = if ($IsWindows -or $PSEdition -eq 'Desktop') {
    'Windows'
} elseif ($IsLinux) {
    'Linux'
} elseif ($IsMacOS) {
    'MacOS'
} else {
    throw 'Unsupported OS'
}

$script:SupportedFonts = @(
    [pscustomobject]@{
        Extension   = '.ttf'
        Type        = 'TrueType'
        Description = 'TrueType Font'
    }
    [pscustomobject]@{
        Extension   = '.otf'
        Type        = 'OpenType'
        Description = 'OpenType Font'
    }
    [pscustomobject]@{
        Extension   = '.ttc'
        Type        = 'TrueType'
        Description = 'TrueType Font Collection'
    }
    [pscustomobject]@{
        Extension   = '.pfb'
        Type        = 'PostScript Type 1'
        Description = 'PostScript Type 1 Font'
    }
    [pscustomobject]@{
        Extension   = '.pfm'
        Type        = 'PostScript Type 1'
        Description = 'PostScript Type 1 Outline Font'
    }
    [pscustomobject]@{
        Extension   = '.woff'
        Type        = 'Web Open Font Format'
        Description = 'Web Open Font Format'
    }
    [pscustomobject]@{
        Extension   = '.woff2'
        Type        = 'Web Open Font Format 2'
        Description = 'Web Open Font Format 2'
    }
)
Write-Debug "[$scriptName] - [variables] - [private] - [common] - Done"
#endregion [variables] - [private] - [common]
Write-Debug "[$scriptName] - [variables] - [private] - Done"
#endregion [variables] - [private]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'Get-Font'
        'Install-Font'
        'Uninstall-Font'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter


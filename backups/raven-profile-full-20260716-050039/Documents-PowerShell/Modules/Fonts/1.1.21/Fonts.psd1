@{
    RootModule            = 'Fonts.psm1'
    ModuleVersion         = '1.1.21'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '5ceed666-cf42-45b9-874f-a86c5e41e50e'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for managing fonts.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName      = 'Admin'
            RequiredVersion = '1.1.6'
        }
    )
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Get-Font'
        'Install-Font'
        'Uninstall-Font'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Get-Fonts'
        'Install-Fonts'
        'Uninstall-Fonts'
    )
    ModuleList            = @()
    FileList              = @(
        'Fonts.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'fonts'
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Fonts/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Fonts'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Fonts/main/icon/icon.png'
        }
    }
}

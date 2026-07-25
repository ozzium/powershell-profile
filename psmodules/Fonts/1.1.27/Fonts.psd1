@{
    RootModule            = 'Fonts.psm1'
    ModuleVersion         = '1.1.27'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '1ca45b7d-1f25-4b1e-a092-c243bbb0cb8b'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2026 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for managing fonts.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName     = 'Admin'
            ModuleVersion  = '1.1.6'
            MaximumVersion = '1.999.999'
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

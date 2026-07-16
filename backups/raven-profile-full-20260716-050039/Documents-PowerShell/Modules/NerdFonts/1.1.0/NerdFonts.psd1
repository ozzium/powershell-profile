@{
    RootModule            = 'NerdFonts.psm1'
    ModuleVersion         = '1.1.0'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '1bddb1d8-04d4-4fac-8b91-3fde3385c699'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2026 PSModule. All rights reserved.'
    Description           = 'A PowerShell module to download and install fonts from NerdFonts.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName      = 'Admin'
            RequiredVersion = '1.1.6'
        }
        @{
            ModuleName      = 'Fonts'
            RequiredVersion = '1.1.21'
        }
    )
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Get-NerdFont'
        'Install-NerdFont'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Get-NerdFonts'
        'Install-NerdFonts'
    )
    ModuleList            = @()
    FileList              = @(
        'FontsData.json'
        'NerdFonts.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'fonts'
                'Linux'
                'MacOS'
                'module'
                'nerdfonts'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/NerdFonts/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/NerdFonts'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/NerdFonts/main/icon/icon.png'
        }
    }
}

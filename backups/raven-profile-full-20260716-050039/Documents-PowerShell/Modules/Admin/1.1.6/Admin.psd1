@{
    RootModule            = 'Admin.psm1'
    ModuleVersion         = '1.1.6'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '510067f2-3727-4665-8130-1edb82a200a8'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module working with the admin role.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = 'Test-Admin'
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Test-Administrator'
        'IsAdmin'
        'IsAdministrator'
    )
    ModuleList            = @()
    FileList              = 'Admin.psm1'
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'powershell'
                'powershell-module'
                'sudo'
                'isadmin'
                'Windows'
                'Linux'
                'MacOS'
                'PSEdition_Desktop'
                'PSEdition_Core'
            )
            LicenseUri = 'https://github.com/PSModule/Admin/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Admin'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Admin/main/icon/icon.png'
        }
    }
}


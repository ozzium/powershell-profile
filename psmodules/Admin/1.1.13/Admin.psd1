@{
    RootModule            = 'Admin.psm1'
    ModuleVersion         = '1.1.13'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '70660c5c-30db-4787-861e-0a626ca8683c'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module working with the admin role.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Test-Admin'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'IsAdmin'
        'IsAdministrator'
        'Test-Administrator'
    )
    ModuleList            = @()
    FileList              = @(
        'Admin.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'isadmin'
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'sudo'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Admin/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Admin'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Admin/main/icon/icon.png'
        }
    }
}

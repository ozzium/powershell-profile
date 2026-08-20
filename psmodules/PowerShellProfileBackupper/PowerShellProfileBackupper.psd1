@{
    RootModule           = 'PowerShellProfileBackupper.psm1'
    ModuleVersion        = '0.0.2'
    GUID                 = '0b78e6df-25dc-40eb-b339-083b13d696e5' 
    # Use your existing GUID or generate a new one via (New-Guid).Guid
    Author               = 'ozzium'
    CompanyName          = 'ozzium'
    Copyright            = '(c) 2026 ozzium. All rights reserved.'
    Description          = 'A PowerShell utility module to automate profile and environment backups.'
    FunctionsToExport    = @('Compress-Profile')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags = @('Profile', 'Backup', 'Automation')
        }
    }
}
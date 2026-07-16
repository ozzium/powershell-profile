@{
    ModuleVersion = '1.0'
    Author = 'Ole Rand-Hendriksen'
    Description = 'A module for working with extended PowerShell command history. It lets you get history from previous sessions, get multi-line commands, and invoke them from history.'
    PowerShellVersion = '3.0'  # Should support all PowerShell versions where Get-History is available
    Guid = '92df1ae8-d3db-41e3-b20c-b2ace0d8c54d'
    FormatsToProcess = @()
    TypesToProcess = @()
    NestedModules = 'ExtendedHistory.psm1'
    FunctionsToExport =  @('Split-History', 'Get-ExtendedHistory', 'Invoke-ExtendedHistory')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FileList = @()
    PrivateData = @{
        PSData = @{
            Tags = @()
            ProjectUri = 'https://github.com/randriksen/ExtendedHistory'
            LicenseUri = 'https://www.gnu.org/licenses/gpl-3.0.en.html'
        }
    }
}
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
#region    [functions] - [public] - [Test-Admin]
Write-Debug "[$scriptName] - [functions] - [public] - [Test-Admin] - Importing"
function Test-Admin {
    <#
        .SYNOPSIS
        Test if the current context is running as a specified role.

        .DESCRIPTION
        This function checks if the current user context has Administrator privileges on Windows or is root on Unix-based systems.
        It returns $true if the user has the required privileges, otherwise $false.

        .EXAMPLE
        ```pwsh
        Test-Admin
        ```

        Test if the current context is running as an Administrator.

        .LINK
        https://psmodule.io/Admin/Functions/Test-Admin/
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    [Alias('Test-Administrator', 'IsAdmin', 'IsAdministrator')]
    param()

    $IsUnix = $PSVersionTable.Platform -eq 'Unix'
    if ($IsUnix) {
        Write-Verbose "Running on Unix, checking if user is root."
        $whoAmI = $(whoami)
        Write-Verbose "whoami: $whoAmI"
        $IsRoot = $whoAmI -eq 'root'
        Write-Verbose "IsRoot: $IsRoot"
        $IsRoot
    } else {
        Write-Verbose "Running on Windows, checking if user is an Administrator."
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($user)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        Write-Verbose "IsAdmin: $isAdmin"
        $isAdmin
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Test-Admin] - Done"
#endregion [functions] - [public] - [Test-Admin]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = 'Test-Admin'
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter


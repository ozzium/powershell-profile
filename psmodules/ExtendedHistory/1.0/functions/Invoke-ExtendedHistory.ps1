<#
.SYNOPSIS
    Invokes a command from the extended PowerShell command history.

.DESCRIPTION
    The Invoke-ExtendedHistory function allows you to retrieve and execute a command from the extended PowerShell command history.
    You can specify the index of the command you want to execute.

.PARAMETER i
    Specifies the index of the command to execute from the extended history.

.EXAMPLE
    Invoke-ExtendedHistory -i 10
    Invokes the command at index 10 from the extended history.

.NOTES
    File Name      : Invoke-ExtendedHistory.ps1
    Author         : Ole Rand-Hendriksen
    Prerequisite   : PowerShell Version 3.0 or later
    Copyright 2023 - Ole Rand-Hendriksen. All rights reserved.

#>

function Invoke-ExtendedHistory {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
        [int]$i
    )

    # Call the Split-History function to split the history into coherent commands
    $hist = Split-History

    # Retrieve the command at the specified index
    $ScriptBlock = [scriptblock]::Create($hist[$i])
    write-host $ScriptBlock
    invoke-command -ScriptBlock $ScriptBlock
}

<#
.SYNOPSIS
    Displays an extended history of executed PowerShell commands.

.DESCRIPTION
    The Get-ExtendedHistory function retrieves and displays an extended history of executed PowerShell commands.
    It provides a list of historical commands along with their respective indices for reference.

.NOTES
    File Name      : Get-ExtendedHistory.ps1
    Author         : Ole Rand-Hendriksen
    Prerequisite   : PowerShell Version 3.0 or later
    Copyright 2023 - Ole Rand-Hendriksen. All rights reserved.

.EXAMPLE
    Get-ExtendedHistory
    Displays the extended history of executed PowerShell commands.

#>

function Get-ExtendedHistory {
    [CmdletBinding()]
    param (
        # No parameters are required for this function.
    )

    # Call the Split-History function to split the history into coherent commands
    $hist = Split-History

    # Output headers for displaying command history
    write-host "Id`tCommand"
    write-host "-----------------------"

    # Loop through the commands in the history
    for ($i = 0; $i -lt $hist.Length; $i++) {
        # If a command is very long (over 200 characters), add separators for readability
        if ($hist[$i].length -gt 200) {
            write-host "`n--------------------------------------------------------------------------------------------"
        }

        # Output the command's index and the command itself
        write-host "$i`t$hist[$i]"

        # If a command is very long (over 200 characters), add separators for readability
        if ($hist[$i].length -gt 200) {
            write-host "--------------------------------------------------------------------------------------------`n"
        }
    }
}


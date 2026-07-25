<#
.SYNOPSIS
    Splits and processes the extended PowerShell command history.

.DESCRIPTION
    The Split-History function processes the extended PowerShell command history, splitting multi-line commands
    and returning a list of coherent individual commands. It helps in organizing and analyzing the command history.

.NOTES
    File Name      : Split-History.ps1
    Author         : Ole Rand-Hendriksen
    Prerequisite   : PowerShell Version 3.0 or later
    Copyright 2023 - Ole Rand-Hendriksen. All rights reserved.

.EXAMPLE
    Split-History
    Splits and processes the extended PowerShell command history.

#>


function Split-History {
    [CmdletBinding()]
    param (
        # No parameters are required for this function.
    )

    # Read the content of the PowerShell history file
    $historyContent = Get-Content (Get-PSReadlineOption).HistorySavePath

    # Initialize arrays to store commands and the current command being processed
    $commands = @()
    $currentCommand = ""

    # Loop through each line in the history file
    foreach ($line in $historyContent) {
        # Check if the line ends with "``" (backtick), indicating a continuation of a multiline command
        if ($line.EndsWith("``")) {
            # Replace the backtick with a line change and append the line to the current command
            $currentCommand += $line.Replace("``", "`n")
        } else {
            # If the line doesn't end with a backtick, it's a standalone command
            $currentCommand += $line
            # Add the complete command to the list of commands, trimming any leading/trailing whitespace
            $commands += $currentCommand.Trim()
            # Reset the current command string
            $currentCommand = ""
        }
    }

    # Add the last command if it exists
    if ($currentCommand -ne "") {
        $commands += $currentCommand.Trim()
    }

    # Return the array of individual commands
    return $commands
}

# ExtendedHistory
A PowerShell module to improve Get-History and Invoke-History 

## Description

The ExtendedHistory PowerShell module allows you to work with and manipulate the command history in PowerShell outside the current session. It provides functions to retrieve extended history, and invoke commands from the history.

## Manual Installation
1. Clone or download this repository.
2. Extract the contents to a directory.
3. Open a PowerShell session and navigate to the directory containing ExtendedHistory.psd1.
4. Import the module using:
```powershell	
Import-Module .\ExtendedHistory.psd1
```

## Usage
The ExtendedHistory module provides several functions to work with the extended PowerShell command history.

### Get-ExtendedHistory
```powershell	
# Retrieve and display the extended command history
Get-ExtendedHistory
```

### Invoke-ExtendedHistory
```powershell
# Invoke a command from the extended command history
Invoke-ExtendedHistory -i <index>
```



# One PowerShell Profile

Enables a one-and-done global PowerShell profile for **all installed PS editions (e.g. Desktop, ISE, Core)**, as each PS profile is seperate by default.

OnePowerShellProfile essentially generates duplicate profile files for each PS edition installed on the machine -- based off the content of the `Public.ps1` and `Private.ps1` files provided in this module.

Profiles can be saved and archived 

## Installation

Install **OnePowerShellProfile** from the [PowerShell Gallery](https://www.powershellgallery.com/packages/OnePowerShellProfile/1)

## Requirements
* PowerShell 5.1 or later

## Quickstart

```powershell
Invoke-ProfileConfiguration -Type Public # Add profile stuff here (e.g. aliases, environment paths)
Set-Profile -ArchiveCurrentProfule $True # Save your existing profile in case you want to revert!!!!
```

## Parameters
```powershell
Invoke-ProfileConfiguration
    # Modify Public.ps1 or Private.ps1 profile templates 
    [-Type {"Public" | "Private"} <string>]
Set-Profile
    # Includes Private.ps1 content into global OnePowerShellProfile
    [-IncludePrivate {$True | $False} = $False <boolean>]
    # Snapshot && archive the current profile (useful if you want to revert)
    [-ArchiveOldProfile {$True | $False} = $False <boolean>]
```


## FAQ
### Q. What does this do?

It builds a global PowerShell profile, and distributes it across any installed PS editions (i.e. Desktop, ISE, Core).

### Q. Why do you use this?

I frequently switch between different PowerShell editions, and this helps me maintain an overall persistent profile environment.

### Q. What is `Public.ps1` and `Private.ps1`?

`Public.ps1` and `Private.ps1` are the **two source files that are concatenated into the global PowerShell profile.** 

In the event you want to export out a global profile to a different account or computer, you can do the following:

```powershell
# 1. Build a new profile without sourcing Private.ps1
Set-Profile -IncludesPrivate $False -ArchiveOldProfile $True

# 2. Find any *profile.ps1 generated from the following message
# => [DONE] Updated /path/to/Microsoft.PowerShell_profile.ps1
```

### Q. Where are my older/archived profiles saved?

Using `Set-Profile`, if `-ArchiveOldProfile` option is set to `$True`, then it will generate a message like this:

> [DONE] Updated /path/to/Microsoft.PowerShell_profile.ps1

From there, you can navigate to the provided path.


### Q. How do I toggle which PS editions I want to generate a profile for?

I have not included this functionality yet, but plan to if I eventually need to, or if requested.
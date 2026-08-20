```
# PowerShell Profile Backup Utility

A PowerShell module function designed to package and archive your PowerShell profile, configuration files, and related Git repositories into a timestamped ZIP archive backup file.

## Overview

`Compress-Profile` automates backing up your shell customizations into a centralized directory to prevent data loss and simplify migration across machines.

### Targeted Paths
* Current user profile path (`$PROFILE`)
* PowerShell document directory (`%USERPROFILE%\Documents\PowerShell`)

---
```

## Usage

### Default Backup

Runs the backup and saves the archive to `%USERPROFILE%\Documents\PowerShellProfileBackup`:

PowerShell

```
Compress-Profile
```

### Custom Backup Destination

Specify an alternate directory using the `-BackupLocation` parameter:

PowerShell

```
Compress-Profile -BackupLocation "path to backup destination"
```

## Output

Creates a ZIP archive with the following naming structure:

Plaintext

```
PowerShellProfileBackup_yyyyMMddHHmmss.zip
```

> **Note:** Ensure paths containing environment variables such as `%USERPROFILE%` are properly resolved or replaced with `$HOME` or `$env:USERPROFILE` if executing in standard PowerShell sessions.
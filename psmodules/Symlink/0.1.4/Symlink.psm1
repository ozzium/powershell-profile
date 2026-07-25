# Create module-wide variables.
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$ModuleRoot\Symlink.psd1").ModuleVersion
$script:DataPath = "$env:APPDATA\Powershell\Symlink\database.xml"

# For the debug output to be displayed, $DebugPreference must be set to 'Continue' within the current session.
Write-Debug "`e[4mMODULE-WIDE VARIABLES`e[0m"
Write-Debug "Module root folder: $ModuleRoot"
Write-Debug "Module version: $ModuleVersion"
Write-Debug "Database file: $DataPath"

# Create the module data-storage folder if it doesn't exist.
if (-not (Test-Path -Path "$env:APPDATA\Powershell\Symlink" -ErrorAction Ignore))
{
	New-Item -ItemType Directory -Path "$env:APPDATA" -Name "Powershell\Symlink" -Force -ErrorAction Stop
	Write-Debug "Created database folder!"
}

# Potentially force this module script to dot-source the files, rather than load them in an alternative method.
$doDotSource = $global:ModuleDebugDotSource
$doDotSource = $true # Needed to make code coverage tests work

function Resolve-Path_i
{
	<#
	.SYNOPSIS
		Resolves a path, gracefully handling a non-existent path.
		
	.DESCRIPTION
		Resolves a path into the full path. If the path is invalid,
		an empty string will be returned instead.
		
	.PARAMETER Path
		The path to resolve.
		
	.EXAMPLE
		PS C:\> Resolve-Path_i -Path "~\Desktop"
		
		Returns 'C:\Users\...\Desktop"

	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]
		$Path
	)
	
	# Run the command, silencing errors.
	$resolvedPath = Resolve-Path -Path $Path -ErrorAction Ignore
	
	# If NULL, then just return an empty string.
	if ($null -eq $resolvedPath)
	{
		$resolvedPath = ""
	}
	
	Write-Output $resolvedPath
}
function Import-ModuleFile
{
	<#
	.SYNOPSIS
		Loads files into the module on module import.
		Only used in the project development environment.
		In built module, compiled code is within this module file.
		
	.DESCRIPTION
		This helper function is used during module initialization.
		It should always be dot-sourced itself, in order to properly function.
		
	.PARAMETER Path
		The path to the file to load.
		
	.EXAMPLE
		PS C:\> . Import-ModuleFile -File $function.FullName
		
		Imports the code stored in the file $function according to import policy.
		
	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path
	)
	
	# Get the resolved path to avoid any cross-OS issues.
	$resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
	
	if ($doDotSource)
	{
		# Load the file through dot-sourcing.
		. $resolvedPath	
		Write-Debug "Dot-sourcing file: $resolvedPath"
	}
	else
	{
		# Load the file through different method (unknown atm?).
		$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($resolvedPath))), $null, $null) 
		Write-Debug "Importing file: $resolvedPath"
	}
}

# ISSUE WITH BUILT MODULE FILE
# ----------------------------
# If this module file contains the compiled code below, as this is a "packaged"
# build, then that code *must* be loaded, and you cannot individually import
# and of the code files, even if they are there.
# 
# 
# If this module file is built, then it contains the class definitions below,
# and on Import-Module, this file is AST analysed and those class definitions 
# are read-in and loaded.
# 
# It's only once a command is run that this module file is executed, and if at
# that point this file starts to individually import the project files, it will
# end up re-defining the classes, and apparently that seems to cause issues 
# later down the line.
# 
# 
# Therefore to prevent this issue, if this module file has been built and it
# contains the compile code below, that code will be used, and nothing else.
# 
# The build script should also not package the individual files, so that the
# *only* possibility is to load the compiled code below and there is no way
# the individual files can be imported, as they don't exist.


# If this module file contains the compiled code, import that, but if it doesn't, then import the
# individual files instead.
$importIndividualFiles = $false
if ("<was built>" -eq '<was not built>')
{
	$importIndividualFiles = $true
	Write-Debug "Module not built! Importing individual files."
}

Write-Debug "`e[4mIMPORT DECISION`e[0m"
Write-Debug "Dot-sourcing: $doDotSource"
Write-Debug "Importing individual files: $importIndividualFiles"

# If importing code as individual files, perform the importing.
# Otherwise, the compiled code below will be loaded.
if ($importIndividualFiles)
{
	Write-Debug "!IMPORTING INDIVIDUAL FILES!"
	
	# Execute Pre-import actions.
	. Import-ModuleFile -Path "$ModuleRoot\internal\preimport.ps1"
	
	# Import all internal functions.
	foreach ($file in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{
		. Import-ModuleFile -Path $file.FullName
	}
	
	# Import all public functions.
	foreach ($file in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{	
		. Import-ModuleFile -Path $file.FullName
	}
	
	# Execute Post-import actions.
	. Import-ModuleFile -Path "$ModuleRoot\internal\postimport.ps1"
	
	# End execution here, do not load compiled code below (if there is any).
	return
}

Write-Debug "!LOADING COMPILED CODE!"

#region Load compiled code
enum SymlinkState
{
	Exists
	NotExists
	NeedsCreation
	NeedsDeletion
	Error
}

class Symlink
{
	[string]$Name
	hidden [string]$_Path
	hidden [string]$_Target
	hidden [scriptblock]$_Condition
		
	# Constructor with no creation condition.
	Symlink([string]$name, [string]$path, [string]$target)
	{
		$this.Name = $name
		$this._Path = $path
		$this._Target = $target
		$this._Condition = $null
	}
	
	# Constructor with a creation condition.
	Symlink([string]$name, [string]$path, [string]$target, [scriptblock]$condition)
	{
		$this.Name = $name
		$this._Path = $path
		$this._Target = $target
		$this._Condition = $condition
	}
	
	[string] ShortPath()
	{
		# Return the path after replacing common variable string.
		$path = $this._Path.Replace("$env:APPDATA\", "%APPDATA%\")
		$path = $path.Replace("$env:LOCALAPPDATA\", "%LOCALAPPDATA%\")
		$path = $path.Replace("$env:USERPROFILE\", "~\")
		return $path
	}
	
	[string] FullPath()
	{
		# Return the path after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Path)
	}
	
	[string] ShortTarget()
	{
		# Return the path after replacing common variable string.
		$path = $this._Target.Replace($env:APPDATA, "%APPDATA%")
		$path = $path.Replace($env:LOCALAPPDATA, "%LOCALAPPDATA%")
		$path = $path.Replace($env:USERPROFILE, "~")
		return $path
	}
	
	[string] FullTarget()
	{
		# Return the target after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Target)
	}
	
	[bool] IsValidPathDirectory()
	{
		# Remove the leaf of the path, as that part is the name the symbolic-link should take,
		# and the link may not be created. This does not invalidate the parent path however, as the parent path
		# must be valid for the link to exist in the first place.
		$parentPath = Split-Path -Path $this.FullPath() -Parent
		
		# Now test that this path to the parent is valid. If this path is valid, then the symbolic link
		# item can be successfully created.
		return Test-Path -Path $parentPath
	}
	
	[bool] IsValidTarget()
	{
		# Test that the target is valid. If any of the parent folders do not exist, or if any environmental 
		# variables are used which do not exist, this will return false.
		return Test-Path -Path $this.FullTarget()
	}
	
	# TODO: Deprecate.
	[string] TargetState()
	{
		# Check if the target is a valid path.
		if (Test-Path -Path $this.FullTarget() -ErrorAction Ignore)
		{
			return "Valid"
		}
		else
		{
			# Check if the target has unexpanded environment variables,
			# i.e. variable not present on system, hence path cannot
			# be verified.
			if ($this.FullTarget().Contains("%"))
			{
				return "MissingVariable"
			}
			else
			{
				return "Invalid"
			}
		}
	}
	
	# TODO: Refactor.
	[bool] Exists()
	{
		# Check if the item even exists.
		if ($null -eq (Get-Item -Path $this.FullPath() -ErrorAction Ignore))
		{
			return $false
		}
		# Checks if the symlink item exists and has the correct target.
		if ((Get-Item -Path $this.FullPath() -ErrorAction Ignore).Target -eq $this.FullTarget())
		{
			return $true
		}
		else
		{
			return $false
		}
	}
	
	[string] GetSourceState()
	{
		if (-not $this.IsValidPathDirectory())
		{
			# Part of the path for where the symbolic-link exists cannot be resolved correctly, either because of
			# missing folders or because of a use of an environment variable not present on the system.
			# Since the path cannot be validated, its unknown if the symbolic link item exists correctly or not.
			return "CannotValidate"
		}
		
		if (-not (Get-Item -Path $this.FullPath() -ErrorAction Ignore))
		{
			# The parent part of the path is valid, but the actual symbolic-link item does not exist.
			return "Nonexistent"
		}
		
		if (-not $this.IsValidTarget())
		{
			# The target is invalid, so the symbolic-link item exists but it's unknown if the target it points to
			# doesn't exist or if the target it points to cannot be resolved.
			return "UnknownTarget"
		}
		
		if ((Get-Item -Path $this.FullPath()).Target -eq $this.FullTarget())
		{
			# The target of the symbolic-link matches the stored target.
			return "Existent"
		}
		else
		{
			# The target of the symbolic-link does not match the stored target (may have changed).
			return "IncorrectTarget"
		}
		
		return "Unknown"
	}
	
	[string] GetTargetState()
	{
		if (-not $this.IsValidTarget())
		{
			# The target path cannot be resolved, because either the folders don't properly exist, or because the
			# system lacks an environmental variable for resolving.
			return "Invalid"
		}
		
		return "Valid"
	}
	
	[bool] ShouldExist()
	{
		# If the condition is null, i.e. no condition,
		# assume true by default.
		if ($null -eq $this._Condition) { return $true }
		
		# An if check is here just in case the creation condition doesn't
		# return a boolean, which could cause issues down the line.
		# This is done because the scriptblock can't be validated whether
		# it always returns true/false, since it is not a "proper" method with
		# typed returns.
		if (Invoke-Command -ScriptBlock $this._Condition)
		{
			return $true
		}
		return $false
	}
	
	# TODO: Deprecate.
	[SymlinkState] GetState()
	{
		# Return the appropiate state depending on whether the symlink
		# exists and whether it should exist.
		if ($this.Exists() -and $this.ShouldExist())
		{
			return [SymlinkState]::Exists
		}
		elseif ($this.Exists() -and -not $this.ShouldExist()) 
		{
			return [SymlinkState]::NeedsDeletion
		}
		elseif (-not $this.Exists() -and $this.ShouldExist())
		{
			return [SymlinkState]::NeedsCreation
		}
		elseif (-not $this.Exists() -and -not $this.ShouldExist())
		{
			return [SymlinkState]::NotExists
		}
		return [SymlinkState]::Error
	}
}

<#
.SYNOPSIS
	Reads all of the defined symlink objects.
	
.DESCRIPTION
	Reads all of the defined symlink objects.
	
.EXAMPLE
	PS C:\> $list = Read-Symlinks
	
	Reads all of the symlink objects into a variable, for later manipulation.
	
.INPUTS
	None
	
.OUTPUTS
	System.Collections.Generic.List[Symlink]
	
.NOTES
	
#>
function Read-Symlinks
{
	# Create an empty list.
	$linkList = New-Object -TypeName System.Collections.Generic.List[Symlink]
	
	# If the file doesn't exist, skip any importing.
	if (Test-Path -Path $script:DataPath -ErrorAction SilentlyContinue)
	{
		# Read the xml data in.
		$xmlData = Import-Clixml -Path $script:DataPath
		
		# Iterate through all the objects.
		foreach ($item in $xmlData)
		{
			# Rather than extracting the deserialised objects, which would create a mess of serialised and
			# non-serialised objects, create new identical copies from scratch.
			if ($item.pstypenames[0] -eq "Deserialized.Symlink")
			{
				# Create using the appropiate constructor.
				$link = if ($null -eq $item._Condition)
				{
					[Symlink]::new($item.Name, $item._Path, $item._Target)
				}else
				{
					[Symlink]::new($item.Name, $item._Path, $item._Target, [scriptblock]::Create($item._Condition))
				}
				
				$linkList.Add($link)
			}
		}
	}
	
	# Return the list as a <List> object, rather than as an array, (ps converts by default).
	Write-Output $linkList -NoEnumerate
}


<#
.SYNOPSIS
	Creates the symbolic-link items.
	
.DESCRIPTION
	The `Build-Symlink` cmdlet creates the symbolic-link items on the
	filesystem. Non-existent items will be created anew, whilst existing items
	will be updated (if necessary). This cmdlet does not create any new
	symlink definitions.	
	
.PARAMETER Names
	Specifies the name(s) of the symlinks to create.
	
 [!]This parameter will autocomplete to valid symlink names.
	
.PARAMETER All
	Specifies to create all symlinks.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to create a symbolic-link item on the filesystem even
	if the creation condition evaluates to false.
	
	Even using this parameter, if the filesystem denies access to the necessary
	files, this cmdlet can fail.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the
		symlinks to create.
	
.OUTPUTS
	Symlink
	
.NOTES
	This command is aliased by default to 'bsl'.
	
.EXAMPLE
	PS C:\> Build-Symlink -All
	
	Creates all of the symbolic-link items on the filesystem for all symlink
	definitions, assuming the creation condition is met.
	
.EXAMPLE
	PS C:\> Build-Symlink -Names "data","files"
	
	Creates the symbolic-link items on the filesystem for the symlink
	definitions named "data" and "files", assuming any creation conditions for
	each evaluate to true.
	
.LINK
	New-Symlink
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function Build-Symlink
{
	[Alias("bsl")]
	
	[CmdletBinding(DefaultParameterSetName = "All", SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "All")]
		[switch]
		$All,
		
		[Parameter()]
		[switch]
		$Force
		
	)

	begin
	{
		# Validate that '-WhatIf'/'-Confirm' isn't used together with '-Force'.
		# This is ambiguous, so warn the user instead.
		Write-Debug "`$WhatIfPreference: $WhatIfPreference"
		Write-Debug "`$ConfirmPreference: $ConfirmPreference"
		if ($WhatIfPreference -and $Force)
		{
			Write-Error "You cannot specify both '-WhatIf' and '-Force' in the invocation for this cmdlet!"
			return
		}
		if (($ConfirmPreference -eq "Low") -and $Force)
		{
			Write-Error "You cannot specify both '-Confirm' and '-Force' in the invocation for this cmdlet!"
			return
		}
	
		# Store lists to notify user which symlinks were created.
		$createdList = New-Object System.Collections.Generic.List[Symlink] 
		
		if ($All)
		{
			$linkList = Read-Symlinks
		}
		else
		{
			$linkList = Get-Symlink -Names $Names -Verbose:$false
		}
	}
	
	process
	{
		foreach ($link in $linkList)
		{
			# Check if the symlink should be created, but it has an invalid target,
			# as in such a case it must be skipped.
			if (($link.ShouldExist() -or $Force) -and ($link.TargetState() -ne "Valid"))
			{
				Write-Error "The symlink named '$($link.Name)' has a target which is invalid/non-existent!`nAborting creation of this symlink."
				continue
			}
			
			# Build the symbolic-link item on the filesytem.
			$expandedPath = $link.FullPath()
			if (($link.ShouldExist() -or $Force) -and ($link.TargetState() -eq "Valid") -and $PSCmdlet.ShouldProcess("Creating symbolic-link item at '$expandedPath'.", "Are you sure you want to create the symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
			{
				# Appropriately delete any existing items before creating the symbolic-link.
				$item = Get-Item -Path $expandedPath -ErrorAction Ignore
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself,
						# whilst calling 'Delete()' on a folder will not delete it's contents. Therefore check
						# whether the item is a symbolic-link to call the appropriate method.
						if ($null -eq $item.LinkType)
						{
							Remove-Item -Path $expandedPath -Force -Recurse -ErrorAction Stop -WhatIf:$false `
								-Confirm:$false | Out-Null
						}
						else
						{
							$item.Delete()
						}
					}
					catch
					{
						Write-Error "The item located at '$expandedPath' could not be deleted to make room for the symbolic-link."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
				
				New-Item -ItemType SymbolicLink -Path $link.FullPath() -Value $link.FullTarget() -Force `
					-WhatIf:$false -Confirm:$false | Out-Null
				
				$createdList.Add($link)
			}
		}
	}
	
	end
	{
		# By default, outputs in List formatting.
		if ($createdList.Count -gt 0)
		{
			Write-Host "Created the following new symlinks:"
			Write-Output $createdList
		}
	}
}

<#
.SYNOPSIS
	Gets the specified symlink item(s).
	
.DESCRIPTION
	The `Get-Symlink` cmdlet gets one or more symlinks, specified by their
	name(s).
	
.PARAMETER Names
	Specifies the name(s) of the items to get.
	
 [!]This parameter will autocomplete to valid symlink names.
	
.PARAMETER All
	Specifies to get all symlinks.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the
		symlinks to get.
	
.OUTPUTS
	Symlink
	
.NOTES
	This command is aliased by default to 'gsl'.
	
.EXAMPLE
	PS C:\> Get-Symlink -Names "data","files"
	
	Gets the symlink definitions named "data" and "video", and pipes them out
	to the screen, by default formatted in a list.
	
.EXAMPLE
	PS C:\> Get-Symlink -All
	
	Gets all symlink definitions, and pipes them out to the screen, by default
	formatted in a list.
	
.EXAMPLE
	PS C:\> Get-Symlink "data" | Build-Symlink
	
	Gets the symlink definition named "data", and then pipes it to the
	`Build-Symlink` cmdlet to create the symbolic-link item on the filesystem.
	
.LINK
	New-Symlink
	Set-Symlink
	Remove-Symlink
	Build-Symlink
	about_Symlink
	
#>
function Get-Symlink
{
	[Alias("gsl")]
	
	[CmdletBinding(DefaultParameterSetName = "Specific")]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "All")]
		[switch]
		$All
		
	)
	
	begin
	{
		# Store the retrieved symlinks, to output together in one go at the end.
		$outputList = New-Object -TypeName System.Collections.Generic.List[Symlink]
	}
	
	process
	{
		if (-not $All)
		{
			# Read in the existing symlinks.
			$linkList = Read-Symlinks
			
			# Iterate through all the passed in names.
			foreach ($name in $Names)
			{
				# If the link doesn't exist, warn the user.
				$existingLink = $linkList | Where-Object { $_.Name -eq $name }
				if ($null -eq $existingLink)
				{
					Write-Warning "There is no symlink named: '$name'."
					continue
				}
				
				# Add the symlink object.
				$outputList.Add($existingLink)
			}
		}
		else
		{
			# Read in all of the symlinks.
			$outputList = Read-Symlinks
		}
	}
	
	end
	{
		# By default, this outputs in List formatting.
		$outputList | Sort-Object -Property Name
	}
}

<#
.SYNOPSIS
	Creates a new symlink.
	
.DESCRIPTION
	The `New-Symlink` cmdlet creates a new symlink definition, and optionally
	also creates the symbolic-link item on the filesystem.
	
.PARAMETER Name
	Specifies the name of the symlink to be created; must be unique.
	
.PARAMETER Path
	Specifies the path of the location of the symbolic-link item. If any parent
	folders in this path don't exist, they will be created.
	
.PARAMETER Target
	Specifies the path of the target which the symbolic-link item points to.
	This also defines whether the symbolic-link points to a directory or a file.
	
.PARAMETER CreationCondition
	Specifies a scriptblock to be used for this symlink. This scriptblock
	decides whether the symbolic-link item should be created on the filesystem.
	For detailed help, see the "CREATION CONDITION SCRIPTBLOCK" section in 
	the help at: 'about_Symlink'.
	
.PARAMETER DontCreateItem
	Prevents the creation of the symbolic-link item on the filesystem.
	(The symlink definition will still be created).
	
.PARAMETER MoveExistingItem
	Specifies to move an already existing directory/file at the specifies path.
	This item will be moved to the specified target path rather than being
	deleted.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to create an symlink that writes over an existing one,
	and forces this cmdlet to create a symbolic-link item on the filesystem
	even if the creation condition evaluates to false.
	
	Even using this parameter, if the filesystem denies access to the necessary
	files, this cmdlet can fail.
	
.INPUTS
	None
	
.OUTPUTS
	Symlink
	
.NOTES
	For detailed help regarding the creation condition scriptblock, see
	the "CREATION CONDITION SCRIPTBLOCK" section in help at: 'about_Symlink'.
	
	This command is aliased by default to 'nsl'.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
	
	Creates a new symlink definition named "data", and also creates the 
	symbolic-link item in the user's document folder under "Data", pointing to a
	location on the "D:\" drive.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
			 -CreationCondition $script -DontCreateItem
	
	Creates a new symlink definition named "data", giving it a creation
	condition to be evaluated. However, this will not create the symbolic-link
	item on the filesystem due to the use of the '-DontCreateItem' switch.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "program" -Path ~\Documents\Program
			 -Target D:\Files\my_program -MoveExistingItem
				
	Creates a new symlink definition named "program", and also creates the 
	symbolic-link item in the user's document folder under the name "Program",
	pointing to a location on the "D:\" drive. By using the '-MoveExistingItem'
	switch, the "~\Documents\Program" folder will be moved into the "D:\Files" 
	folder and renamed to "my_program".
	
.LINK
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function New-Symlink
{
	[Alias("nsl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[string]
		$Target,
		
		[Parameter(Position = 3)]
		[scriptblock]
		$CreationCondition,
		
		[Parameter(Position = 4)]
		[switch]
		$MoveExistingItem,
		
		[Parameter(Position = 5)]
		[switch]
		$DontCreateItem,
		
		[Parameter()]
		[switch]
		$Force
		
	)
	
	# Validate that '-WhatIf'/'-Confirm' isn't used together with '-Force'.
	# This is ambiguous, so warn the user instead.
	Write-Debug "`$WhatIfPreference: $WhatIfPreference"
	Write-Debug "`$ConfirmPreference: $ConfirmPreference"
	if ($WhatIfPreference -and $Force)
	{
		Write-Error "You cannot specify both '-WhatIf' and '-Force' in the invocation for this cmdlet!"
		return
	}
	if (($ConfirmPreference -eq "Low") -and $Force)
	{
		Write-Error "You cannot specify both '-Confirm' and '-Force' in the invocation for this cmdlet!"
		return
	}
	
	# Validate that the name isn't empty.
	Write-Verbose "Validating parameters."
	if ([system.string]::IsNullOrWhiteSpace($Name))
	{
		Write-Error "The name cannot be blank or empty!"
		return
	}
	
	$expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
	$expandedTarget = [System.Environment]::ExpandEnvironmentVariables($Target)
	
	# Validate that the target location exists. If the item isn't being moved there, check the full path,
	# otherwise check that the parent folder is valid.
	if (-not (Test-Path -Path $expandedTarget -ErrorAction Ignore) -and -not $MoveExistingItem)
	{
		Write-Error "The target path: '$Target' points to an invalid/non-existent location!"
		return
	}
	if (-not (Test-Path -Path (Split-Path -Path $expandedTarget -Parent) -ErrorAction Ignore) `
		-and $MoveExistingItem)
	{
		Write-Error "Part of the target path: '$(Split-Path -Path $expandedTarget -Parent)' is invalid!"
		return
	}
	
	# Validate that the name isn't already taken.
	$linkList = Read-Symlinks
	$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
	if ($null -ne $existingLink)
	{
		if ($Force)
		{
			Write-Verbose "Existing symlink named: '$Name' exists, but since the '-Force' switch is present, the existing symlink will be deleted."
			$existingLink | Remove-Symlink
		}
		else
		{
			Write-Error "The name: '$Name' is already taken."
			return
		}
	}
	
	if ((Test-Path -Path $expandedPath -ErrorAction Ignore) -and $MoveExistingItem -and $PSCmdlet.ShouldProcess("Moving and renaming existing item from '$expandedPath' to '$expandedTarget'.", "Are you sure you want to move and rename the existing item from '$expandedPath' to '$expandedTarget'?", "Move File Prompt")) 
	{
		# Move the item over to the target parent folder, and rename it to the specified name given as part
		# of the target path.
		$fileName = Split-Path -Path $expandedPath -Leaf
		$newFileName = Split-Path -Path $expandedTarget -Leaf
		$targetFolder = Split-Path -Path $expandedTarget -Parent
		# Only troy to move the item if the parent folders differ, otherwise 'Move-Item' will thrown an error.
		if ((Split-Path -Path $expandedPath -Parent) -ne $targetFolder)
		{
			try
			{
				Move-Item -Path $expandedPath -Destination $targetFolder -Force -ErrorAction Stop -WhatIf:$false `
					-Confirm:$false | Out-Null
			}
			catch
			{
				Write-Error "Could not move the existing item to the target destination.`nClose any programs which may be using this path and re-run the cmdlet."
				return
			}
		}
		
		# Only try to rename the item if the name differs, otherwise 'Rename-Item' will throw an error.
		if ($fileName -ne $newFileName)
		{
			try
			{
				Rename-Item -Path "$targetFolder\$filename" -NewName $newFileName -Force -ErrorAction Stop `
					-WhatIf:$false -Confirm:$false | Out-Null
			}
			catch
			{
				Write-Error "Could not rename the existing item to match the target path.`nClose any programs which may be using this path and re-run the cmdlet."
				return
			}
		}
	}
	elseif (-not (Test-Path -Path $expandedPath -ErrorAction Ignore) -and $MoveExistingItem)
	{
		Write-Error "Cannot move the existing item from: '$expandedPath' because the location is invalid."
		return
	}
	
	# Create the object and save it to the database.
	Write-Verbose "Creating new symlink object."
	if ($null -eq $CreationCondition)
	{
		$newLink = [Symlink]::new($Name, $Path, $Target)
	}
	else
	{
		$newLink = [Symlink]::new($Name, $Path, $Target, $CreationCondition)
	}
	$linkList.Add($newLink)
	if ($PSCmdlet.ShouldProcess("Saving newly-created symlink to database at '$script:DataPath'.", "Are you sure you want to save the newly-created symlink to the database at '$script:DataPath'?", "Save File Prompt"))
	{
		Export-Clixml -Path $script:DataPath -InputObject $linkList -Force -WhatIf:$false -Confirm:$false `
			| Out-Null
	}
	
	# Build the symbolic-link item on the filesytem.
	if (-not $DontCreateItem -and ($newLink.TargetState() -eq "Valid") -and ($newLink.ShouldExist() -or $Force) -and $PSCmdlet.ShouldProcess("Creating symbolic-link item at '$expandedPath'.", "Are you sure you want to create the symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
	{
		# Appropriately delete any existing items before creating the symbolic-link.
		$item = Get-Item -Path $expandedPath -ErrorAction Ignore
		# Existing item may be in use and unable to be deleted, so retry until the user has closed any
		# programs using the item.
		while (Test-Path -Path $expandedPath)
		{
			try
			{
				# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
				# to; calling 'Delete()' will only destroy the symbolic-link iteself,
				# whilst calling 'Delete()' on a folder will not delete it's contents. Therefore check whether the
				# item is a symbolic-link to call the appropriate method.
				if ($null -eq $item.LinkType)
				{
					Remove-Item -Path $expandedPath -Force -Recurse -ErrorAction Stop -WhatIf:$false `
						-Confirm:$false | Out-Null
				}
				else
				{
					$item.Delete()
				}
			}
			catch
			{
				Write-Error "The item located at: '$expandedPath' could not be deleted to make room for the symbolic-link."
				Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
			}
		}
		New-Item -ItemType SymbolicLink -Path $expandedPath -Value $expandedTarget -Force -WhatIf:$false `
			-Confirm:$false | Out-Null
	}
	
	Write-Output $newLink
}

<#
.SYNOPSIS
	Deletes a specified symlink item(s).
	
.DESCRIPTION
	The `Remove-YoutubeDlItem` cmdlet deletes one or more symlinks, specified
	by their name(s).
	
.PARAMETER Names
	Specifies the name(s) of the items to delete.
	
 [!]This parameter will autocomplete to valid symlink names.
	
.PARAMETER DontDeleteItem
	Prevents the deletion of the symbolic-link item from the filesystem.
	(The symlink definition will still be deleted).
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the symlinks
		to delete.
	
.OUTPUTS
	None
	
.NOTES
	This command is aliased by default to 'rsl'.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Name "data"
	
	Deletes the symlink definition named "data", and deletes the symbolic-link
	item from the filesystem.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Names "data","files"
	
	Deletes the symlink definitions named "data" and "files", and their 
	symbolic-link items from the filesystem.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Name "data" -DontDeleteItem
	
	Deletes the symlink definition named "data", but does not delete the
	symbolic-link item from the filesystem; that remains unchanged.
	
.LINK
	New-Symlink
	Get-Symlink
	Set-Symlink
	about_Symlink
	
#>
function Remove-Symlink
{
	[Alias("rsl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 1)]
		[switch]
		$DontDeleteItem
		
	)
	
	process
	{
		# Read in the existing symlinks.
		$linkList = Read-Symlinks
		
		foreach ($name in $Names)
		{
			# If the link doesn't exist, warn the user.
			$existingLink = $linkList | Where-Object { $_.Name -eq $name }
			if ($null -eq $existingLink)
			{
				Write-Error "There is no symlink named: '$name'."
				continue
			}
			
			# Delete the symlink from the filesystem.
			$expandedPath = $existingLink.FullPath()
			$item = Get-Item -Path $expandedPath -ErrorAction Ignore
			if (-not $DontDeleteItem -and $existingLink.Exists() -and $PSCmdlet.ShouldProcess("Deleting symbolic-link at '$expandedPath'.", "Are you sure you want to delete the symbolic-link at '$expandedPath'?", "Delete Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself.
						$item.Delete()
					}
					catch
					{
						Write-Error "The symbolic-link located at: '$expandedPath' could not be deleted."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
			}
			
			# Remove the link from the list.
			Write-Verbose "Deleting the symlink object."
			$linkList.Remove($existingLink) | Out-Null
		}
		
		# Save the modified database.
		if ($PSCmdlet.ShouldProcess("Updating database at '$script:DataPath' with the changes (deletions).", "Are you sure you want to update the database at '$script:DataPath' with the changes (deletions)?", "Save File Prompt"))
		{
			Export-Clixml -Path $script:DataPath -InputObject $linkList -Force -WhatIf:$false `
				-Confirm:$false | Out-Null
		}
	}
}

<#
.SYNOPSIS
	Changes a value of a symlink item.
	
.DESCRIPTION
	The `Set-Symlink` cmdlet changes the value of a symlink.
	
.PARAMETER Name
	Specifies the name of the symlink to be changed.
	
 [!]This parameter will autocompleted to valid names for a symlink.

.PARAMETER Property
	Specifies the name of the property to change.
	
 [!]This parameter will autocompleted to the following: "Name", "Path",
	"Target", "CreationCondition".
	
.PARAMETER Value
	Specifies the new value of the property being changed.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to change the name of a symlink even if it overwrites an
	existing one, or forces this cmdlet to create a symbolic-link item on the
	filesystem even if the creation condition evaluates to false.
	
	Even using this parameter, if the filesystem denies access to the necessary
	files, this cmdlet can fail.
	
.INPUTS
	System.String
		You can pipe the name of the symlink to change.
	
.OUTPUTS
	None
	
.NOTES
	For detailed help regarding the creation condition scriptblock, see
	the "CREATION CONDITION SCRIPTBLOCK" section in help at: 'about_Symlink'.
	
	This command is aliased by default to 'ssl'.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Name" -Value "WORK"
	
	Changes the name of a symlink definition named "data", to the new name
	of "WORK". From now on, there is not symlink named "data" anymore, and that
	name is free for future use.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Path" -Value "~\Desktop\Files"
	
	Changes the path of the symlink definition named "data", to a new value
	located in the user's desktop folder. The old symbolic-link item at the
	previous location will be deleted from the filesystem, and a new item will
	be created at the new location.

.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Target" -Value "D:\new\target"
	
	Changes the target of the symlink definition named "data", to a new value
	on the "D:\" drive. The existing symbolic-link item on the filesystem will
	have its target updated to this new value, (technically involves deleting
	and re-creating the item since the target cannot be modified).
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "CreationCondition" 
			 -Value { return $false }
			 
	Changes the creation condition of the symlink definition named "data", to
	a new scriptblock which always returns $FALSE. This will not delete the
	existing symbolic-link item on the filesystem, even though if the condition
	was evaluated now, it would return false.
	
.LINK
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function Set-Symlink
{
	[Alias("ssl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[ValidateSet("Name", "Path", "Target", "CreationCondition")]
		[string]
		$Property,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[AllowNull()]
		$Value,
		
		[Parameter()]
		[switch]
		$Force
		
	)
	
	process
	{
		# If the link doesn't exist, warn the user.
		$linkList = Read-Symlinks
		$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
		if ($null -eq $existingLink)
		{
			Write-Error "There is no symlink named: '$Name'."
			return
		}
		
		# Modify the property values.
		Write-Verbose "Validating parameters."
		if ($Property -eq "Name")
		{
			# Validate that the new name is valid.
			if ([system.string]::IsNullOrWhiteSpace($Name))
			{
				Write-Error "The new name cannot be blank or empty!"
				return
			}
			# Validate that the new name isn't already taken.
			$clashLink = $linkList | Where-Object { $_.Name -eq $Value }
			if ($null -ne $clashLink)
			{
				if ($Force)
				{
					Write-Verbose "Existing symlink named: '$Value' exists, but since the '-Force' switch is present, the existing symlink will be deleted."
					$clashLink | Remove-Symlink
				}
				else
				{
					Write-Error "The name: '$Value' is already taken!"
					return
				}
			}
			
			$linkList = Read-Symlinks
			$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
			
			$existingLink.Name = $Value
		}
		elseif ($Property -eq "Path")
		{
			# Validate the new path isn't empty.
			if ([System.String]::IsNullOrWhiteSpace($Value))
			{
				Write-Error "The new path cannot be blank or empty!"
				return
			}
			# Validate that the target exists.
			if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($existingLink.FullTarget())) `
					-ErrorAction Ignore))
			{
				Write-Error "The symlink's target path: '$($existingLink.FullTarget())' points to an invalid location!"
				return
			}
			
			# Firstly, delete the symlink from the filesystem at the original path location.
			$expandedPath = $existingLink.FullPath()
			$item = Get-Item -Path $expandedPath -ErrorAction Ignore
			if ($existingLink.Exists() -and $PSCmdlet.ShouldProcess("Deleting old symbolic-link at '$expandedPath'.", "Are you sure you want to delete the old symbolic-link at '$expandedPath'?", "Delete Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself.
						$item.Delete()
					}
					catch
					{
						Write-Error "The old symbolic-link located at '$expandedPath' could not be deleted."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
			}
			
			# Then change the path property, and re-create the symlink at the new location, taking into account
			# that there may be existing items at the new path.
			$existingLink._Path = $Value
			$expandedPath = $existingLink.FullPath()
			if (($existingLink.ShouldExist() -or $Force) -and ($existingLink.TargetState() -eq "Valid") -and $PSCmdlet.ShouldProcess("Creating new symbolic-link item at '$expandedPath'.", "Are you sure you want to create the new symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
			{
				# Appropriately delete any existing items before creating the symbolic-link.
				$item = Get-Item -Path $expandedPath -ErrorAction Ignore
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself,
						# whilst calling 'Delete()' on a folder will not delete it's contents. Therefore check
						# whether the item is a symbolic-link to call the appropriate method.
						if ($null -eq $item.LinkType)
						{
							Remove-Item -Path $expandedPath -Force -Recurse -ErrorAction Stop -WhatIf:$false `
								-Confirm:$false | Out-Null
						}
						else
						{
							$item.Delete()
						}
					}
					catch
					{
						Write-Error "The item located at '$expandedPath' could not be deleted to make room for the symbolic-link."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
				
				New-Item -ItemType SymbolicLink -Path $existingLink.FullPath() -Value $existingLink.FullTarget() `
					-Force -WhatIf:$false -Confirm:$false | Out-Null
			}
		}
		elseif ($Property -eq "Target")
		{
			# Validate that the target exists.
			if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Value)) `
					-ErrorAction Ignore))
			{
				Write-Error "The new target path: '$Value' points to an invalid/non-existent location!"
				return
			}
			
			# Firstly, delete the symlink with the old target value from the filesystem.
			$expandedPath = $existingLink.FullPath()
			$item = Get-Item -Path $expandedPath -ErrorAction Ignore
			if ($existingLink.Exists() -and $PSCmdlet.ShouldProcess("Deleting outdated symbolic-link at '$expandedPath'.", "Are you sure you want to delete the outdated symbolic-link at '$expandedPath'?", "Delete Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself.
						$item.Delete()
					}
					catch
					{
						Write-Error "The outdated symbolic-link located at '$expandedPath' could not be deleted."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
			}
			
			# Then change the target property, and re-create the symlink at the with the new target,
			# taking into account that there may be existing items at the new path.
			$existingLink._Target = $Value
			$expandedPath = $existingLink.FullPath()
			if (($existingLink.ShouldExist() -or $Force) -and ($existingLink.TargetState() -eq "Valid") -and $PSCmdlet.ShouldProcess("Creating new symbolic-link item at '$expandedPath'.", "Are you sure you want to create the new symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
			{
				# Appropriately delete any existing items before creating the symbolic-link.
				$item = Get-Item -Path $expandedPath -ErrorAction Ignore
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself,
						# whilst calling 'Delete()' on a folder will not delete it's contents. Therefore check
						# whether the item is a symbolic-link to call the appropriate method.
						if ($null -eq $item.LinkType)
						{
							Remove-Item -Path $expandedPath -Force -Recurse -ErrorAction Stop -WhatIf:$false `
								-Confirm:$false | Out-Null
						}
						else
						{
							$item.Delete()
						}
					}
					catch
					{
						Write-Error "The item located at '$expandedPath' could not be deleted to make room for the symbolic-link."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
				New-Item -ItemType SymbolicLink -Path $existingLink.FullPath() -Value $existingLink.FullTarget() `
					-Force -WhatIf:$false -Confirm:$false | Out-Null
			}
		}
		elseif ($Property -eq "CreationCondition")
		{
			$existingLink._Condition = $Value
		}
		
		if ($PSCmdlet.ShouldProcess("Updating database at '$script:DataPath' with the changes.", "Are you sure you want to update the database at '$script:DataPath' with the changes?", "Save File Prompt"))
		{
			Export-Clixml -Path $script:DataPath -InputObject $linkList -WhatIf:$false -Confirm:$false `
				| Out-Null
		}
	}
}

# Tab expansion assignements for commands.
$argCompleter_SymlinkName =
{
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Import all objects from the database file.
	$linkList = Read-Symlinks
	
	if ($linkList.Count -eq 0)
	{
		Write-Output ""
	}
	
	# Return the names which match the currently typed in pattern.
	# This first strips the string of any quotation marks, then matches it to the valid names,
	# and then inserts the quotation marks again. This is necessary so that strings with spaces have quotes,
	# otherwise they will not be treated as one parameter.
	$linkList.Name | Where-Object { $_ -like "$($wordToComplete.Replace(`"`'`", `"`"))*" } | ForEach-Object { "'$_'" }
	
}

Register-ArgumentCompleter -CommandName Get-Symlink -ParameterName Names -ScriptBlock $argCompleter_SymlinkName
Register-ArgumentCompleter -CommandName Set-Symlink -ParameterName Name -ScriptBlock $argCompleter_SymlinkName
Register-ArgumentCompleter -CommandName Remove-Symlink -ParameterName Names -ScriptBlock $argCompleter_SymlinkName
Register-ArgumentCompleter -CommandName Build-Symlink -ParameterName Names -ScriptBlock $argCompleter_SymlinkName
#endregion Load compiled code

using namespace System.Management.Automation
using namespace System.Collections.ObjectModel
function Clear-AliasTipsInternalASTResults {
  Clear-Variable AliasTipsInternalASTResults_* -Scope Global
}
# Attempts to find an alias for a singular command
function Find-AliasCommand {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)]
    [string]$Command
  )

  begin {
    if ($AliasTipsHash -and $AliasTipsHash.Count -eq 0) {
      $AliasTipsHash = ConvertFrom-StringData -StringData $([System.IO.File]::ReadAllText($AliasTipsHashFile)) -Delimiter "|"
    }
  }

  process {
    # If we can find the alias quickly, do so
    $Alias = $AliasTipsHash[$Command.Trim()]
    if (-not [string]::IsNullOrEmpty($Alias)) {
      Write-Verbose "Quickly found alias inside of AliasTipsHash"
      return $Alias | Format-Command
    }

    # TODO check if it is an alias, expand it back out to check if there is a better alias

    # We failed to find the alias in the hash, instead get the executed command, and attempt to generate a regex for it.

    # First we need to ensure we have generated required regexes
    Find-RegexThreadJob
    # Generate a regex that searches through our alias hash, and checks if it matches as an alias for our command
    $Regex = Get-CommandRegex $Command
    # Write-Host $Regex
    if ([string]::IsNullOrEmpty($Regex)) {
      return ""
    }
    $SimpleSubRegex = "$([Regex]::Escape($($Command | Format-Command).Split(" ")[0]))[^`$`n]*\`$"

    $Aliases = @("")
    Write-Verbose "`n$Regex`n`n$SimpleSubRegex`n"

    # Create a new AliasHash with evaluated expression
    $AliasTipsHashEvaluated = $AliasTipsHash.Clone()
    $AliasTipsHash.GetEnumerator() | ForEach-Object {
      # Only reasonably evaluate any commands that match the one we are searching for
      if ($_.key -match $Regex) {
        $Aliases += ,($_.Key, $_.Value)
      }

      # Substitute commands using ExecutionContext if possible
      # Check if we have anything that has a $(...)
      if ($_.key -match $SimpleSubRegex -and ((Initialize-EnvVariable "ALIASTIPS_FUNCTION_INTROSPECTION" $false) -eq $true)) {
        $NewKey = Format-CommandFromExecutionContext($_.value)
        if (-not [string]::IsNullOrEmpty($NewKey) -and $($NewKey -replace '\$args', '') -match $Regex) {
          $Aliases += ,($($NewKey -replace '\$args', '').Trim(), $_.Value)
          $AliasTipsHashEvaluated[$NewKey] = $_.value
        }
      }
    }
    Clear-AliasTipsInternalASTResults

    # Sort by which alias removes the most, then if they both shorten by same amount, choose the shorter alias
    $Aliases = @(@($Aliases
      | Where-Object { $null -ne $_[0] -and $null -ne $_[1] })
      | Sort-Object -Property @{Expression = { - ($_[0]).Length } }, @{Expression = { ($_[1]).Length} })
    # foreach ($pair in $Aliases) {
    #   Write-Host "($($pair[0]), $($pair[1]))"
    # }
    # Use the longest candiate, if tied use shorter alias
    # -- TODO? this is my opinionated way since it results in most coverage (one long alias is better than two combined shorter aliases),
    $AliasCandidate = ($Aliases)[0][0]
    Write-Verbose "Alias Candidate Chosen: $AliasCandidate"
    $Alias = ""
    if (-not [string]::IsNullOrEmpty($AliasCandidate)) {
      $Remaining = "$($Command)"
      $CleanAlias = "$($AliasCandidate)" | Format-Command
      $AttemptSplit = $CleanAlias -split " "

      $AttemptSplit | ForEach-Object {
        [Regex]$Pattern = [Regex]::Escape("$_")
        $Remaining = $Pattern.replace($Remaining, "", 1)
      }

      if (-not $Remaining) {
        $Alias = ($AliasTipsHashEvaluated[$AliasCandidate]) | Format-Command
      }
      if ($AliasTipsHashEvaluated[$AliasCandidate + ' $args']) {
        # TODO: Sometimes superflous args aren't at the end... Fix this.
        $Alias = ($AliasTipsHashEvaluated[$AliasCandidate + ' $args'] + $Remaining) | Format-Command
      }
      if ($Alias -ne $Command) {
        return $Alias
      }
    }
  }
}
function Find-RegexThreadJob {
  if ($null -ne $script:AliasTipsProxyFunctionRegex -and $null -ne $script:AliasTipsProxyFunctionRegexNoArgs) {
    return
  }

  $existingJob = Get-Job -Name "FindAliasTipsJob" -ErrorAction SilentlyContinue | Select-Object -Last 1
  if ($null -ne $existingJob) {
    $existingJob = Wait-Job -Job $existingJob
  }
  else {
    $job = Start-RegexThreadJob

    $existingJob = Wait-Job -Job $job
  }
  $result = Receive-Job -Job $existingJob -Wait -AutoRemoveJob

  # this is a regex to find all commands, not just aliases/functions
  $script:AliasTipsProxyFunctionRegex, $script:AliasTipsProxyFunctionRegexNoArgs = $result
}
function Format-Command {
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)][string]${Command}
  )

  process {
    if ([string]::IsNullOrEmpty($Command)) {
      return $Command
    }

    $tokens = @()
    [void][System.Management.Automation.Language.Parser]::ParseInput($Command, [ref]$tokens, [ref]$null)

    return ($tokens.Text -join " " -replace '\s*\r?\n\s*', ' ').Trim()
  }
}
$script:AUTOMATIC_VARIBLES_TO_SUPRESS = @(
  '\$',
  '\?',
  '\^',
  '_',
  'args',
  'ConsoleFileName',
  'EnabledExperimentalFeatures',
  'Error',
  'Event(Args|Subscriber)?',
  'ExecutionContext',
  'false',
  'HOME',
  'Host',
  'input',
  'Is(CoreCLR|Linux|MacOS|Windows){1}',
  'LASTEXITCODE',
  'Matches', # TODO?
  'MyInvocation',
  'NestedPromptLevel',
  'null',
  'PID',
  'PROFILE',
  'PSBoundParameters', # TODO?
  'PSCmdlet',
  'PSCommandPath', # TODO?
  'PSCulture',
  'PSDebugContext',
  'PSEdition',
  'PSHOME',
  'PSItem',
  'PSScriptRoot',
  'PSSenderInfo',
  'PSUICulture',
  'PSVersionTable',
  'PWD',
  'Sender',
  'ShellId',
  'StackTrace',
  'switch',
  'this',
  'true'
) -Join '|'

# Finds the command based on the alias and replaces $(...) if possible
function Format-CommandFromExecutionContext {
  param(
    [Parameter(Mandatory)][string]${Alias}
  )

  # Get the original definition
  $Def = Get-Item -Path Function:\$Alias | Select-Object -ExpandProperty 'Definition'

  # Find variables we need to resolve, ie $MainBranch
  $VarsToResolve = @("")
  $ReconstructedCommand = ""
  if ($Def -match $AliasTipsProxyFunctionRegexNoArgs) {
    $ReconstructedCommand = ("$($matches['cmd'].TrimStart()) $($matches['params'])") | Format-Command
    if ($args -match '\$args') {
      $ReconstructedCommand += ' $args'
    }
    $($matches['params'] | Format-Command) -split " " | ForEach-Object {
      if ($_ -match '\$') {
        # Make sure it is not an automatic variable
        if ($_ -match "(\`$)($AUTOMATIC_VARIBLES_TO_SUPRESS)") {

        }
        else {
          $VarsToResolve += $_ -replace "[^$`n]*(?=\$)", ""
        }
      }
    }
  }
  else {
    return ""
  }

  $VarsReplaceHash = @{}
  Get-Variable AliasTipsInternalASTResults_* | ForEach-Object {
    if ($_.Value) {
      $VarsReplaceHash[$($_.Name -replace "AliasTipsInternalASTResults_", "")] = $_.Value
    }
  }

  # If there are vars to resolve, attempt to find them.
  if ($VarsToResolve) {
    $DefScriptBlock = [scriptblock]::Create($Def)
    $DefAst = $DefScriptBlock.Ast

    foreach ($Var in $VarsToResolve) {
      # Attempt to find the definition based on the ast
      # TODO: handle nested script blocks
      $FoundAssignment = $DefAst.Find({
          $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
          $("$($args[0].Extent)" -eq "$Var")
        }, $false)
      if ($FoundAssignment -and -not $VarsReplaceHash[$Var]) {
        $CommandToEval = $($FoundAssignment.Parent -replace "[^=`n]*=", "").Trim()
        # Super naive LOL! Hopefully the command isn't destructive!
        $Evaluated = Invoke-Command -ScriptBlock $([scriptblock]::Create("$CommandToEval -ErrorAction SilentlyContinue"))
        if ($Evaluated) {
          $VarsReplaceHash[$Var] = $Evaluated
          Set-Variable -Name "AliasTipsInternalASTResults_$Var" -Value $Evaluated -Scope Global
        }
      }
    }

    $VarsReplaceHash.GetEnumerator() | ForEach-Object {
      if ($_.Value) {
        $ReconstructedCommand = $ReconstructedCommand -replace $([regex]::Escape($_.key)), $_.Value
      }
    }

    return $($ReconstructedCommand | Format-Command)
  }
}
# Return a hashtable of possible aliases
function Get-Aliases {
  $Hash = @{}
  Find-RegexThreadJob

  # generate aliases for commands aliases created via native PowerShell functions
  $proxyAliases = Get-Item -Path Function:\
  foreach ($alias in $proxyAliases) {
    $f = Get-Item -Path Function:\$alias
    $ProxyName = $f | Select-Object -ExpandProperty 'Name'
    $ProxyDef = $f | Select-Object -ExpandProperty 'Definition'
    # validate there is a command
    if ($ProxyDef -match $script:AliasTipsProxyFunctionRegex) {
      $CleanedCommand = ("$($matches['cmd'].TrimStart()) $($matches['params'])") | Format-Command

      if ($ProxyDef -match '\$args') {
        # Use the shorter of two if we already have hashed this command
        if ($Hash.ContainsKey($CleanedCommand + ' $args')) {
          if ($ProxyName.Length -lt $Hash[$CleanedCommand + ' $args'].Length) {
            $Hash[$CleanedCommand + ' $args'] = $ProxyName
          }
        }
        else {
          $Hash[$CleanedCommand + ' $args'] = $ProxyName
        }
      }

      # quick alias
      # use the shorter of two if we already have hashed this command
      if ($Hash.ContainsKey($CleanedCommand)) {
        if ($ProxyName.Length -lt $Hash[$CleanedCommand].Length) {
          $Hash[$CleanedCommand] = $ProxyName
        }
      }
      else {
        $Hash[$CleanedCommand] = $ProxyName
      }
    }
  }

  # generate aliases configured from the `Set-Alias` command
  Get-Alias | ForEach-Object {
    $aliasName = $_ | Select-Object -ExpandProperty 'Name'
    $aliasDef = $($_ | Select-Object -ExpandProperty 'Definition') | Format-Command
    $hash[$aliasDef] = $aliasName
    $hash[$aliasDef + ' $args'] = $aliasName
  }

  return $hash
}
function Get-CommandRegex {
  [CmdletBinding()]
  [OutputType([System.String])]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]${Command}
  )

  process {
    # The parse is a bit naive...
    if ($Command -match $script:AliasTipsProxyFunctionRegexNoArgs) {
      # Clean up the command by removing extra delimiting whitespace and backtick preceding newlines
      $CommandString = ("$($matches['cmd'].TrimStart())")

      if ([string]::IsNullOrEmpty($CommandString)) {
        return ""
      }
      $CommandString = $CommandString | Format-Command

      $ReqParams = $($matches['params']) -split " "
      $ReqParamRegex = "(" + ($ReqParams.ForEach({
              "$([Regex]::Escape($_.Trim()))(\s|``\r?\n)*"
          }) -join '|') + ")*"

      # Enable sensitive case (?-i)
      # Begin anchor      (^|[;`n])
      # Whitespace        (\s*)
      # Any Command       (?<cmd>$CommandString)
      # Whitespace        (\s|``\r?\n)*
      # Req Parameters    (?<params>$ReqParamRegex)
      # Whitespace        (\s|``\r?\n)*
      # End Anchor        ($|[|;`n])
      $Regex = "(?-i)(^|[;`n])(\s*)(?<cmd>$CommandString)(\s|``\r?\n)*(?<params>$ReqParamRegex)(\s|``\r?\n)*($|[|;`n])"

      return $Regex
    }
  }
}
function Get-EnvVariable {
  param (
      [string]$VariableName
  )

  [System.Environment]::GetEnvironmentVariable($VariableName)
}
function Initialize-EnvVariable {
  param (
    [Parameter(Mandatory = $true, Position = 0)][string]$VariableName,
    [Parameter(Position = 1)][string]$DefaultValue
  )

  $Var = Get-EnvVariable $VariableName
  $Var = if ($null -ne $Var) { $Var } else { $DefaultValue }
  Set-UnsetEnvVariable $VariableName $Var
  $Var
}
function Set-UnsetEnvVariable {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param (
    [string]$VariableName,
    [string]$Value
  )

  # Check if the environment variable is already set
  if (-not [System.Environment]::GetEnvironmentVariable($VariableName)) {
    # Set the environment variable
    if($PSCmdlet.ShouldProcess($VariableName)){
      [System.Environment]::SetEnvironmentVariable($VariableName, $Value)
    }
  }
}
function Start-RegexThreadJob {
  $existingJob = Get-Job -Name "FindAliasTipsJob" -ErrorAction SilentlyContinue | Select-Object -Last 1
  if ($null -ne $existingJob) {
    $existingJob = Wait-Job -Job $existingJob
  }

  return Start-ThreadJob -Name "FindAliasTipsJob" -ScriptBlock {
    function Get-CommandsRegex {
      (Get-Command * | ForEach-Object {
        $CommandUnsafe = $_ | Select-Object -ExpandProperty 'Name'
        $Command = [Regex]::Escape($CommandUnsafe)
        # check if it has a file extensions
        if ($CommandUnsafe -match "(?<cmd>[^.\s]+)\.(?<ext>[^.\s]+)$") {
          $CommandWithoutExtension = [Regex]::Escape($matches['cmd'])
          return $Command, $CommandWithoutExtension
        }
        else {
          return $Command
        }
      }) -Join '|'
    }

    # The regular expression here roughly follows this pattern:
    #
    # <begin anchor><whitespace>*<command>(<whitespace><parameter>)*<whitespace>+<$args><whitespace>*<end anchor>
    #
    # The delimiters inside the parameter list and between some of the elements are non-newline whitespace characters ([^\S\r\n]).
    # In those instances, newlines are only allowed if they preceded by a non-newline whitespace character.
    #
    # Begin anchor (^|[;`n])
    # Whitespace   (\s*)
    # Any Command  (?<cmd>)
    # Parameters   (?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)
    # $args Anchor (([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)
    # Whitespace   (\s|``\r?\n)*
    # End Anchor   ($|[|;`n])
    function Get-ProxyFunctionRegexes {
      param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)][regex]${CommandPattern}
      )

      process {
        [regex]"(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)(\s|``\r?\n)*($|[|;`n])",
        [regex]"(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(\s|``\r?\n)*($|[|;`n])"
      }
    }

    Get-CommandsRegex | Get-ProxyFunctionRegexes
  }
}

Start-RegexThreadJob | Out-Null
function Disable-AliasTips {
  <#
  .SYNOPSIS

  Disables alias-tips

  .DESCRIPTION

  Disables alias-tips by setting $env:ALIASTIPS_DISABLE to $true

  .INPUTS
  
  None. This function does not accept any input.

  .OUTPUTS
  
  None. This function does not accept any input.

  .EXAMPLE

  PS> Disable-AliasTips

  #>
  [System.Environment]::SetEnvironmentVariable("ALIASTIPS_DISABLE", $true)
}
function Enable-AliasTips {
  <#
  .SYNOPSIS

  Enables alias-tips

  .DESCRIPTION

  Enables alias-tips by setting $env:ALIASTIPS_DISABLE to $false

  .INPUTS
  
  None. This function does not accept any input.

  .OUTPUTS
  
  None. This function does not accept any input.

  .EXAMPLE

  PS> Enable-AliasTips

  #>

  [System.Environment]::SetEnvironmentVariable("ALIASTIPS_DISABLE", $false)
}
function Find-Alias {
  <#
  .SYNOPSIS

  Finds an alias for a command string.

  .DESCRIPTION

  Finds an alias for a command string. Returns the original line if no aliases are found.

  .PARAMETER Line

  Specifies the line to find an alias for.

  .INPUTS

  [System.String](https://docs.microsoft.com/en-us/dotnet/api/system.string)

  .OUTPUTS

  [System.String](https://docs.microsoft.com/en-us/dotnet/api/system.string)

  .EXAMPLE

  PS> Find-Alias "git checkout master"

  .EXAMPLE

  PS> "git status" | Find-Alias

  #>
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)]
    [string]$Line
  )

  process {
    if ($AliasTipsHash -and $AliasTipsHash.Count -eq 0) {
      $AliasTipsHash = ConvertFrom-StringData -StringData $([System.IO.File]::ReadAllText($AliasTipsHashFile)) -Delimiter "|"
    }

    $tokens = @()
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$null)

    $queue = [System.Collections.ArrayList]::new()
    $extents = @(0, 0)
    $offset = 0
    $aliased = $ast.ToString()

    foreach ($token in $tokens) {
      $kind = $token.Kind
      Write-Verbose "$(($kind, "'$($token.Text)'" , $token.Extent.StartOffset, $token.Extent.EndOffset))"
      if ('Generic', 'Identifier', 'HereStringLiteral', 'Parameter', 'StringLiteral' -contains $kind) {
        if ($queue.Count -eq 0) {
          $queue += $token.Text
          $extents = @($token.Extent.StartOffset, $token.Extent.EndOffset)
        }
        else {
          $queue[-1] = "$($queue[-1]) $($token.Text)"
          $extents = @($extents[0], $token.Extent.EndOffset)
        }
      }
      else {
        # When we finish the current token back-alias it
        if ($queue.Count -gt 0) {
          $alias = Find-AliasCommand $queue[-1]
          if (-not [string]::IsNullOrEmpty($alias)) {
            $saved = $queue[-1].Length - $alias.Length
            $newleft = $extents[0] + $offset
            $newright = $extents[1] + $offset
            $aliased = "$(if ($newLeft -le 0) {''} else {$aliased.Substring(0, $newLeft)})$alias$(if ($newright -ge $aliased.Length) {''} else {$aliased.Substring($newright)})"
            $offset -= $saved
          }
        }

        # Reset the queue
        $queue = [System.Collections.ArrayList]::new()
        $extents = @(0, 0)

        if ('HereStringExpandable', 'StringExpandable' -contains $kind) {
          $ntokens = $token.NestedTokens
          if ($ntokens.Length -eq 0) {
            continue
          }
          $nqueue = [System.Collections.ArrayList]::new()
          $nextents = @(0, 0)
          foreach ($ntoken in $ntokens) {
            $nkind = $ntoken.Kind
            # Write-Host ("`t", $nkind, "'$($ntoken.Text)'" , $ntoken.Extent.StartOffset, $ntoken.Extent.Endoffset)
            if ('Generic', 'Identifier', 'HereStringLiteral', 'Parameter', 'StringLiteral' -contains $nkind) {
              if ($nqueue.Count -eq 0) {
                $nqueue += $ntoken.Text
                $nextents = @($ntoken.Extent.StartOffset, $ntoken.Extent.EndOffset)
              }
              else {
                $nqueue[-1] = "$($nqueue[-1]) $($ntoken.Text)"
                $nextents = @($nextents[0], $ntoken.Extent.EndOffset)
              }
            }
            else {
              # When we finish the current token back-alias it
              if ($nqueue.Count -gt 0) {
                $alias = Find-AliasCommand $nqueue[-1]
                if (-not [string]::IsNullOrEmpty($alias)) {
                  $saved = $nqueue[-1].Length - $alias.Length
                  $newleft = $nextents[0] + $offset
                  $newright = $nextents[1] + $offset
                  $aliased = "$(if ($newLeft -le 0) {''} else {$aliased.Substring(0, $newLeft)})$alias$(if ($newright -ge $aliased.Length) {''} else {$aliased.Substring($newright)})"
                  $offset -= $saved
                }
              }

              # Reset the queue
              $nqueue = [System.Collections.ArrayList]::new()
              $nextents = @(0, 0)
            }
          }
        }
      }
    }

    $aliased.Trim()
  }
}
function Find-AliasTips {
  <#
  .SYNOPSIS

  Finds alias-tips for the current shell context.

  .DESCRIPTION

  Finds alias-tips for the current shell context. This command should be run everytime aliases 
  are updated or changed. It caches the expensive operation to a pipe delimited file in the 
  `$env:AliasTipsHashFile` location. By default this location is at `$HOME/.alias_tips.hash`.

  .EXAMPLE

  PS> Find-AliasTips

  #>
  $AliasTipsHash = Get-Aliases
  $Value = $($AliasTipsHash.GetEnumerator() | ForEach-Object {
      if ($_.Key.Length -ne 0) {
        # Replaces \ with \\
        "$($_.Key -replace "\\", "\\")|$($_.Value -replace "\\", "\\")"
      }
    })

  $script:AliasTipsProxyFunctionRegex, $script:AliasTipsProxyFunctionRegexNoArgs = $null
  $jobs = Get-Job -Name "FindAliasTipsJob" -ErrorAction SilentlyContinue
  if ($null -ne $jobs) {
    foreach ($job in $jobs) {
      Stop-Job -Job $job
      Remove-Job -Job $job
    }
  }
  Start-RegexThreadJob

  Set-Content -Path $AliasTipsHashFile -Value $Value
}
# Store the original PSConsoleHostReadLine function when importing the module
$script:AliasTipsOriginalPSConsoleHostReadLine = Get-Item Function:\PSConsoleHostReadLine -ErrorAction SilentlyContinue

function PSConsoleHostReadLine {
  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?

  ($Line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus))

  if ([System.Environment]::GetEnvironmentVariable("ALIASTIPS_DISABLE") -eq [string]$true) {
    return
  }

  # split line into multiple commands if possible
  $alias = Find-Alias $Line

  if (-not [string]::IsNullOrEmpty($alias) -and ($alias | Format-Command) -ne ($Line | Format-Command)) {
    $tip = (Initialize-EnvVariable "ALIASTIPS_MSG" "Alias tip: {0}") -f $alias
    $vtTip = (Initialize-EnvVariable "ALIASTIPS_MSG_VT" "`e[033mAlias tip: {0}`e[m") -f $alias
    if ($tip -eq "") {
      Write-Warning "Error formatting ALIASTIPS_MSG"
    }
    if ($vtTip -eq "") {
      Write-Warning "Error formatting ALIASTIPS_MSG_VT"
    }
    $host.UI.SupportsVirtualTerminal ? $vtTip : $tip | Out-Host
  }
}

$DEFAULT_PSConsoleHostReadLine = {
  [System.Diagnostics.DebuggerHidden()]
  param()

  ## Get the execution status of the last accepted user input.
  ## This needs to be done as the first thing because any script run will flush $?.
  $lastRunStatus = $?
  Microsoft.PowerShell.Core\Set-StrictMode -Off
  [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  if ($null -eq $script:AliasTipsOriginalPSConsoleHostReadLine) {
    $script:AliasTipsOriginalPSConsoleHostReadLine = $DEFAULT_PSConsoleHostReadLine
  }
  $toFixStr = "Set-Item Function:\PSConsoleHostReadLine -Value `$AliasTipsOriginalPSConsoleHostReadLine"
  @"
`e[1;31mRemoved module alias-tips!`e[m `e[36mTo restore your PSReadline, run:`e[m
$toFixStr
`e[36mIt has been copied into your clipboard for your convenience`e[m
"@ | Out-Host
  Set-Clipboard -Value $toFixStr
  # TODO is there a way to restore this automagically??
  Set-Item Function:\PSConsoleHostReadLine -Value $script:AliasTipsOriginalPSConsoleHostReadLine -Force
}
$AliasTipsHashFile = Initialize-EnvVariable "ALIASTIPS_HASH_PATH" "$([System.IO.Path]::Combine("$HOME", '.alias_tips.hash'))"
Initialize-EnvVariable "ALIASTIPS_DISABLE" $false

$AliasTipsHash = @{}
$AliasTipsHashEvaluated = @{}
$script:AliasTipsProxyFunctionRegex, $script:AliasTipsProxyFunctionRegexNoArgs = $null, $null


########## Public Profile ##########
<#
.SYNOPSIS
    Public functions/cmdlets for PowerShell profile
#>

function New-File
{
  param(
    [Parameter(Mandatory = $true)] [string] $Name,
    [string] $Path = $null
  )

  $Command = New-Item -Name $Name -ItemType File
  if ($null -ne $Path) {
    $Command = $Command -join ' -Path $Path'
  }
  else {
    $Command = $Command -join ' -Path .'
  }

  $Command
}

Set-Alias -Name touch -Value New-File
Set-Alias -Name refresh -Value Set-Profile
Set-Alias -Name profile -Value Invoke-ProfileConfiguration
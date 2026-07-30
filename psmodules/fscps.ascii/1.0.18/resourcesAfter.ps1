<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'fscps.ascii' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'fscps.ascii' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'fscps.ascii' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."


<#
# Example:
Register-PSFTeppScriptblock -Name "fscps.ascii.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

<#
Stored scriptblocks are available in [PsfValidateScript()] attributes.
This makes it easier to centrally provide the same scriptblock multiple times,
without having to maintain it in separate locations.

It also prevents lengthy validation scriptblocks from making your parameter block
hard to read.

Set-PSFScriptblock -Name 'fscps.ascii.ScriptBlockName' -Scriptblock {
	
}
#>

<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name fscps.ascii.alcohol
#>

New-PSFLicense -Product 'fscps.ascii' -Manufacturer 'onikolaiev' -ProductVersion $script:ModuleVersion -ProductType Module -Name MIT -Version "1.0.0.0" -Date (Get-Date "2024-03-27") -Text @"
Copyright (c) 2025 Oleksandr Nikolaiev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@

$Script:TimeSignals = @{ }
$Script:FigFonts = @{} 
$Script:FigDefaults = @{
    font = "Standard"
    fontPath = "$Script:ModuleRoot\internal\misc\Fonts"
}

# Add the System.Web type
Add-Type -AssemblyName System.Web

# Add the System.Net.Http type
Add-Type -AssemblyName System.Net.Http

# Add the System.IO.Compression type
Add-Type -AssemblyName System.IO.Compression

# Add the System.IO.Compression.FileSystem type
Add-Type -AssemblyName System.IO.Compression.FileSystem

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidAssignmentToAutomaticVariable', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[CmdletBinding()]
param()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Import-PowerShellDataFile -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"

if ($PSEdition -eq 'Desktop') {
    $IsWindows = $true
}

#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [Set-MarkdownCodeBlock]
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownCodeBlock] - Importing"
function Set-MarkdownCodeBlock {
    <#
        .SYNOPSIS
        Generates a fenced code block for Markdown using the specified language.

        .DESCRIPTION
        This function takes a programming language and a script block, and depending on the provided parameters,
        either captures the script block's literal text (with indentation normalized) or executes it and captures the
        string representation of the output. It then formats the result as a fenced code block suitable for Markdown.

        .EXAMPLE
        Set-MarkdownCodeBlock -Language 'PowerShell' -Content {
            Get-Process
        }

        Output:
        ```powershell
        Get-Process
        ```

        Generates a fenced code block with the specified PowerShell script.

        .EXAMPLE
        CodeBlock 'PowerShell' {
            Get-Process
        }

        Output:
        ```powershell
        Get-Process
        ```

        Generates a fenced code block with the specified PowerShell script.

        .EXAMPLE
        CodeBlock -Language 'PowerShell' -Content {
            Get-Process | Select-Object -First 1
        } -Execute

        Output:
        ```powershell
        NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
        ------    -----      -----     ------      --  -- -----------
            13     4.09      15.91       0.00    9904   0 AggregatorHost
        ```

        Generates a fenced code block with the output of the specified PowerShell script.

        .OUTPUTS
        string

        .NOTES
        Returns the formatted fenced code block as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownCodeBlock/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Alias('Block')]
    [Alias('CodeBlock')]
    [Alias('Fence')]
    [Alias('CodeFence')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Language,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock] $Content,

        [Parameter()]
        [switch] $Execute
    )

    # If -Execute is specified, run the script block and capture its output.
    if ($Execute) {
        # Execute the script block and capture all output as a single string.
        $output = . $Content | Out-String
        # Split the output into lines.
        $lines = $output -split "`r?`n"
    } else {
        # Capture the raw text of the script block.
        $raw = $Content.Ast.Extent.Text
        $lines = $raw -split "`r?`n"

        # Remove leading and trailing blank lines.
        while ($lines.Count -gt 0 -and $lines[0].Trim() -eq '') {
            $lines = $lines[1..($lines.Count - 1)]
        }
        while ($lines.Count -gt 0 -and $lines[-1].Trim() -eq '') {
            $lines = $lines[0..($lines.Count - 2)]
        }

        # If the first and last lines are only '{' and '}', remove them.
        if ($lines.Count -ge 2 -and $lines[0].Trim() -eq '{' -and $lines[-1].Trim() -eq '}') {
            $lines = $lines[1..($lines.Count - 2)]
        }

        # Determine common leading whitespace (indentation) on non-empty lines.
        $nonEmpty = $lines | Where-Object { $_.Trim().Length -gt 0 }
        if ($nonEmpty) {
            $commonIndent = ($nonEmpty | ForEach-Object {
                    $_.Length - $_.TrimStart().Length
                } | Measure-Object -Minimum).Minimum

            # Remove the common indent from each line.
            $lines = $lines | ForEach-Object {
                if ($_.Length -ge $commonIndent) { $_.Substring($commonIndent) } else { $_ }
            }
        }
    }

    # Build the Markdown fenced code block.
    $return = @()
    $return += '```{0}' -f $Language
    $return += $lines
    $return += '```'
    $return += ''

    $return -join [Environment]::NewLine
}
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownCodeBlock] - Done"
#endregion [functions] - [public] - [Set-MarkdownCodeBlock]
#region    [functions] - [public] - [Set-MarkdownDetails]
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownDetails] - Importing"
function Set-MarkdownDetails {
    <#
        .SYNOPSIS
        Generates a collapsible Markdown details block.

        .DESCRIPTION
        This function creates a collapsible Markdown `<details>` block with a summary title
        and formatted content. It captures the output of the provided script block and
        wraps it in a Markdown details structure.

        .EXAMPLE
        Set-MarkdownDetails -Title 'More Information' -Content {
            'This is detailed content.'
        }

        Output:
        ```powershell
        <details><summary>More Information</summary>
        <p>

        This is detailed content.

        </p>
        </details>
        ```

        Generates a Markdown details block with the title "More Information" and the specified content.

        .EXAMPLE
        Details 'More Information' {
            'This is detailed content.'
        }

        Output:
        ```powershell
        <details><summary>More Information</summary>
        <p>

        This is detailed content.

        </p>
        </details>
        ```

        Generates a Markdown details block with the title "More Information" and the specified content.

        .OUTPUTS
        string

        .NOTES
        Returns the formatted Markdown details block as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownDetails/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns', '',
        Justification = 'Markdown details are a collection of information. Language specific'
    )]
    [Alias('Details')]
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # The title of the Markdown details block.
        [Parameter(Mandatory, Position = 0)]
        [string] $Title,

        # The content inside the Markdown details block.
        [Parameter(Mandatory, Position = 1)]
        [ScriptBlock] $Content
    )

    $captured = . $Content | Out-String
    $captured = $captured.TrimEnd()

    $return = @()
    $return += "<details><summary>$Title</summary>"
    $return += '<p>'
    $return += ''
    $return += $captured
    $return += ''
    $return += '</p>'
    $return += '</details>'
    $return += ''

    $return -join [System.Environment]::NewLine
}
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownDetails] - Done"
#endregion [functions] - [public] - [Set-MarkdownDetails]
#region    [functions] - [public] - [Set-MarkdownParagraph]
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownParagraph] - Importing"
function Set-MarkdownParagraph {
    <#
        .SYNOPSIS
        Generates a Markdown paragraph.

        .DESCRIPTION
        This function captures the output of the provided script block and formats it as a Markdown paragraph.
        It trims trailing whitespace and surrounds the content with blank lines to ensure proper Markdown formatting.

        .EXAMPLE
        Paragraph {
            "This is a simple Markdown paragraph generated dynamically."
        }

        Output:
        ```markdown

        This is a simple Markdown paragraph generated dynamically.

        ```

        .EXAMPLE
        Paragraph {
            "This is a simple Markdown paragraph generated dynamically."
        } -Tags

        Output:
        ```markdown
        <p>

        This is a simple Markdown paragraph generated dynamically.

        </p>
        ```

        Generates a Markdown paragraph with the specified content.

        .OUTPUTS
        string

        .NOTES
        Returns the formatted Markdown paragraph as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownParagraph/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [Alias('Paragraph')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ScriptBlock] $Content,

        [Parameter()]
        [switch] $Tags
    )

    # Capture the output of the script block and trim trailing whitespace.
    $captured = . $Content | Out-String
    $captured = $captured.TrimEnd()

    # Surround the paragraph with blank lines to ensure proper Markdown separation.
    $return = @()
    if ($Tags) {
        $return += ''
        $return += '<p>'
    }
    $return += ''
    $return += $captured
    $return += ''
    if ($Tags) {
        $return += '</p>'
        $return += ''
    }

    $return -join [System.Environment]::NewLine
}
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownParagraph] - Done"
#endregion [functions] - [public] - [Set-MarkdownParagraph]
#region    [functions] - [public] - [Set-MarkdownSection]
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownSection] - Importing"
function Set-MarkdownSection {
    <#
        .SYNOPSIS
        Generates a formatted Markdown section with a specified header level, title, and content.

        .DESCRIPTION
        This function creates a Markdown section with a specified header level, title, and formatted content.
        The header level determines the number of `#` symbols used for the Markdown heading.
        The content is provided as a script block and executed within the function.
        The function returns the formatted Markdown as a string.

        .EXAMPLE
        Set-MarkdownSection -Level 2 -Title "Example Section" -Content {
            "This is an example of Markdown content."
        }

        Output:
        ```powershell
        ## Example Section

        This is an example of Markdown content.
        ```

        Generates a Markdown section with an H2 heading and the given content.

        .EXAMPLE
        Section 2 "Example Section" {
            "This is an example of Markdown content."
        }

        Output:
        ```powershell
        ## Example Section

        This is an example of Markdown content.
        ```

        Generates a Markdown section with an H2 heading and the given content.

        .OUTPUTS
        string

        .NOTES
        The formatted Markdown section as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownSection
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Alias('Header')]
    [Alias('Heading')]
    [Alias('Section')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # Specifies the Markdown header level (1-6).
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, 6)]
        [int] $Level,

        # The title of the Markdown section.
        [Parameter(Mandatory, Position = 1)]
        [string] $Title,

        # The content to be included in the Markdown section.
        [Parameter(Mandatory, Position = 2)]
        [scriptblock] $Content
    )

    $captured = . $Content | Out-String
    $captured = $captured.TrimEnd()

    # Create the Markdown header by repeating the '#' character
    $hashes = '#' * $Level

    $return = @()
    $return += "$hashes $Title"
    $return += ''
    $return += $captured
    $return += ''

    $return -join [System.Environment]::NewLine
}
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownSection] - Done"
#endregion [functions] - [public] - [Set-MarkdownSection]
#region    [functions] - [public] - [Set-MarkdownTable]
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownTable] - Importing"
function Set-MarkdownTable {
    <#
        .SYNOPSIS
        Converts objects from a script block into a Markdown table.

        .DESCRIPTION
        The Set-MarkdownTable function executes a provided script block and formats the resulting objects as a Markdown table.
        Each property of the objects becomes a column, and each object becomes a row in the table. If no objects are returned,
        a warning is displayed, and no output is produced.

        .EXAMPLE
        Table {
            Get-Process | Select-Object -First 3 Name, ID
        }

        Output:
        ```powershell
        | Name | ID |
        | ---- | -- |
        | notepad | 1234 |
        | explorer | 5678 |
        | chrome | 91011 |
        ```

        Generates a Markdown table from the first three processes, displaying their Name and ID properties.

        .OUTPUTS
        string

        .NOTES
        The Markdown-formatted table as a string output.

        This function returns a Markdown-formatted table string, which can be used in documentation or exported.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownTable/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Alias('Table')]
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # Script block containing commands whose output will be converted into a Markdown table.
        [Parameter(Mandatory, Position = 0)]
        [ScriptBlock] $InputScriptBlock
    )

    # Execute the script block and capture the output objects.
    $results = & $InputScriptBlock

    if (-not $results) {
        Write-Warning 'No objects to display.'
        return
    }

    # Use the first object to get the property names.
    $first = $results | Select-Object -First 1
    $props = $first.psobject.Properties.Name

    # Build the Markdown header row.
    $header = '| ' + ($props -join ' | ') + ' |'
    # Build the separator row.
    $separator = '| ' + ( ($props | ForEach-Object { '-' }) -join ' | ' ) + ' |'

    # Output header rows.
    $return = @()
    $return += $header
    $return += $separator

    # For each object, output a table row.
    foreach ($item in $results) {
        $rowValues = foreach ($prop in $props) {
            $val = $item.$prop
            if ($null -eq $val) { '' } else { $val.ToString() }
        }
        $row = '| ' + ($rowValues -join ' | ') + ' |'
        $return += $row
    }
    $return += ''

    $return -join [Environment]::NewLine
}
Write-Debug "[$scriptName] - [functions] - [public] - [Set-MarkdownTable] - Done"
#endregion [functions] - [public] - [Set-MarkdownTable]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'Set-MarkdownCodeBlock'
        'Set-MarkdownDetails'
        'Set-MarkdownParagraph'
        'Set-MarkdownSection'
        'Set-MarkdownTable'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter


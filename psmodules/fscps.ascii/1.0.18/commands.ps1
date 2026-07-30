
<#
    .SYNOPSIS
        Breaks a long word into two parts: the portion that fits within the allowed width and the leftover characters.
        
    .DESCRIPTION
        This function processes a list of ASCII characters (`figChars`) and determines how much of the word can fit
        within the specified width (`opts.width`). It returns the portion that fits (`outputFigText`) and any leftover
        characters (`chars`).
        
    .PARAMETER figChars
        An array of single ASCII characters in the form `{fig, overlap}`. Represents the word to be broken.
        
    .PARAMETER len
        The number of rows to process.
        
    .PARAMETER opts
        A hashtable containing options, including:
        - `width`: The maximum allowed width for the word.
        
    .EXAMPLE
        $figChars = @(
        @{ fig = "H"; overlap = 1 },
        @{ fig = "e"; overlap = 1 },
        @{ fig = "l"; overlap = 1 },
        @{ fig = "l"; overlap = 1 },
        @{ fig = "o"; overlap = 1 }
        )
        $opts = @{
        width = 10
        }
        $result = Break-Word -figChars $figChars -len 2 -opts $opts
        
        This example breaks the word "Hello" into a portion that fits within the width of 10 and any leftover characters.
        
    .NOTES
        This function assumes the existence of helper functions `Join-FigArray` and `Get-FigLinesWidth` for processing
        the ASCII characters and calculating their widths.
#>
function Break-Word {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [array]$figChars, # List of single ASCII characters in form {fig, overlap}
        [int]$len,        # Number of rows
        [hashtable]$opts  # Options object
    )

    $result = @{}
    for ($i = $figChars.Count; --$i -ge 0; ) {
        # Join the figChars up to the current index
        $w = Join-FigArray -array $figChars[0..($i)] -len $len -opts $opts
        # Check if the width of the joined array is within the allowed width
        if ((Get-FigLinesWidth -textLines $w) -le $opts.width) {
            $result["outputFigText"] = $w
            # If there are leftover characters, add them to the result
            if ($i -lt $figChars.Count) {
                $result["chars"] = $figChars[$i..($figChars.Count)]
            } else {
                $result["chars"] = @()
            }
            break
        }
    }
    return $result
}


<#
    .SYNOPSIS
        Determines if two lines of text can be vertically smushed based on the specified smushing rules.
        
    .DESCRIPTION
        This function evaluates whether two lines of text (`txt1` and `txt2`) can be vertically smushed together
        according to the vertical smushing rules defined in the `opts.fittingRules` parameter. It iterates through
        each character in the lines and applies the appropriate smushing rules to determine if the lines can be
        combined. The function returns whether the smushing is valid, invalid, or has ended.
        
    .PARAMETER txt1
        The first line of text to evaluate for vertical smushing.
        
    .PARAMETER txt2
        The second line of text to evaluate for vertical smushing.
        
    .PARAMETER opts
        A hashtable containing the smushing options, including:
        - `fittingRules.vLayout`: Specifies the vertical layout type (e.g., Full, Fitted, UniversalSmushing).
        - `fittingRules.vRule1` to `vRule4`: Boolean flags indicating which smushing rules to apply.
        
    .EXAMPLE
        $txt1 = "Hello"
        $txt2 = "World"
        $opts = @{
        fittingRules = @{
        vLayout = [LayoutType]::UniversalSmushing
        vRule1 = $true
        vRule2 = $false
        vRule3 = $true
        vRule4 = $false
        }
        }
        $result = Can-VerticalSmush -txt1 $txt1 -txt2 $txt2 -opts $opts
        
        This example checks if the lines "Hello" and "World" can be vertically smushed using the specified smushing rules.
        
    .NOTES
        This function relies on helper functions (`vRule1-Smush`, `vRule2-Smush`, `vRule3-Smush`, `vRule4-Smush`, and `vRule5-Smush`)
        to evaluate individual smushing rules for character pairs.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Can-VerticalSmush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$txt1,  # A line of text
        [string]$txt2,  # A line of text
        [hashtable]$opts  # FIGlet options array
    )

    # Check if the vertical layout is FULL_WIDTH
    if ($opts.fittingRules.vLayout -eq [LayoutType]::Full) {
        return "invalid"
    }

    # Determine the minimum length of the two lines
    $len = [math]::Min($txt1.Length, $txt2.Length)
    if ($len -eq 0) {
        return "invalid"
    }

    $endSmush = $false
    $validSmush = $false

    # Iterate through each character in the lines
    for ($ii = 0; $ii -lt $len; $ii++) {
        $ch1 = $txt1[$ii]
        $ch2 = $txt2[$ii]
        # Check if both characters are not spaces
        if ($ch1 -ne " " -and $ch2 -ne " ") {
            if ($opts.fittingRules.vLayout -eq [LayoutType]::Fitted) {
                return "invalid"
            } elseif ($opts.fittingRules.vLayout -eq [LayoutType]::UniversalSmushing) {
                return "end"
            } else {
                # Apply smushing rules
                if (vRule5-Smush -ch1 $ch1 -ch2 $ch2) {
                    $endSmush = $endSmush -or $false
                    continue
                }

                $validSmush = $false
                if ($opts.fittingRules.vRule1) {
                    $validSmush = vRule1-Smush -ch1 $ch1 -ch2 $ch2    
                }
                if (-not $validSmush -and $opts.fittingRules.vRule2) {
                    $validSmush = vRule2-Smush -ch1 $ch1 -ch2 $ch2
                }
                if (-not $validSmush -and $opts.fittingRules.vRule3) {
                    $validSmush = vRule3-Smush -ch1 $ch1 -ch2 $ch2
                }
                if (-not $validSmush -and $opts.fittingRules.vRule4) {
                    $validSmush = vRule4-Smush -ch1 $ch1 -ch2 $ch2
                }

                $endSmush = $true
                if (-not $validSmush) {
                    return "invalid"
                }
            }
        }
    }

    # Return the result based on whether smushing has ended
    if ($endSmush) {
        return "end"
    } else {
        return "valid"
    }
}


<#
    .SYNOPSIS
        Generates FIGlet text lines from input text using specified FIGlet characters and options.
        
    .DESCRIPTION
        This function processes input text and converts it into FIGlet text lines using the provided FIGlet character
        definitions (`figChars`) and options (`opts`). It handles whitespace, character smushing, and layout rules
        to produce the final FIGlet text output.
        
    .PARAMETER txt
        The input text to be converted into FIGlet text lines.
        
    .PARAMETER figChars
        A hashtable containing the FIGlet character definitions. Each character maps to its FIGlet representation.
        
    .PARAMETER opts
        A hashtable containing options for generating FIGlet text, including:
        - `height`: The height of the FIGlet characters.
        - `width`: The maximum width of the output text.
        - `whitespaceBreak`: A flag indicating whether to break lines at whitespace.
        - `printDirection`: The direction in which the text is printed (e.g., left-to-right or right-to-left).
        - `fittingRules.hLayout`: Specifies the horizontal layout type (e.g., Full, Fitted, ControlledSmushing).
        
    .EXAMPLE
        $txt = "Hello, World!"
        $figChars = @{
        72 = @("H", "H")
        101 = @("e", "e")
        108 = @("l", "l")
        111 = @("o", "o")
        44 = @(",", ",")
        32 = @(" ", " ")
        87 = @("W", "W")
        114 = @("r", "r")
        100 = @("d", "d")
        33 = @("!", "!")
        }
        $opts = @{
        height = 8
        width = 80
        whitespaceBreak = $true
        printDirection = 0
        fittingRules = @{
        hLayout = [LayoutType]::ControlledSmushing
        }
        }
        $result = Generate-FigTextLines -txt $txt -figChars $figChars -opts $opts
        
        This example generates FIGlet text lines for the input "Hello, World!" using the specified FIGlet characters
        and options.
        
    .NOTES
        This function assumes the existence of helper functions such as `New-FigChar` for creating FIGlet characters
        and `Join-FigArray` for combining FIGlet text lines.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Generate-FigTextLines {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string]$txt,          # Input text
        [hashtable]$figChars,  # FIGlet characters
        [hashtable]$opts       # Options object
    )

    $overlap = 0
    $height = $opts.height
    $outputFigLines = @()
    $figWords = @()
    $outputFigText = New-FigChar -len $height
    $nextFigChars = $null

    if ($opts.width -gt 0 -and $opts.whitespaceBreak) {
        $nextFigChars = @{
            chars = @()
            overlap = $overlap
        }
    }

    if ($opts.printDirection -eq 1) {
        $txt = ($txt.ToCharArray() | ForEach-Object { $_ })[-1..-($txt.Length)] -join ""
    }

    $len = $txt.Length
    for ($charIndex = 0; $charIndex -lt $len; $charIndex++) {
        $char = $txt.Substring($charIndex, 1)
        $isSpace = $char -match "\s"
        $figChar = $figChars[[int][char]$char]
        $textFigLine = $null

        if ($figChar) {
            if ($opts.fittingRules.hLayout -ne [LayoutType]::Full) {
                $overlap = 10000
                for ($row = 0; $row -lt $opts.height; $row++) {
                    $overlap = [math]::Min(
                        $overlap,
                        (Get-HorizontalSmushLength -txt1 $outputFigText[$row] -txt2 $figChar[$row] -opts $opts)
                    )
                }
                $overlap = if ($overlap -eq 10000) { 0 } else { $overlap }
            }

            if ($opts.width -gt 0) {
                if ($opts.whitespaceBreak) {
                    $textFigWord = Join-FigArray -array ($nextFigChars.chars + @(@{ fig = $figChar; overlap = $overlap })) -len $height -opts $opts
                    $textFigLine = Join-FigArray -array ($figWords + @(@{ fig = $textFigWord; overlap = $nextFigChars.overlap })) -len $height -opts $opts
                    $maxWidth = Get-FigLinesWidth -textLines $textFigLine
                } else {
                    $textFigLine = Horizontal-Smush -textBlock1 $outputFigText -textBlock2 $figChar -overlap $overlap -opts $opts
                    $maxWidth = Get-FigLinesWidth -textLines $textFigLine
                }

                if ($maxWidth -ge $opts.width -and $charIndex -gt 0) {
                    if ($opts.whitespaceBreak) {
                        $outputFigText = Join-FigArray -array $figWords[0..($figWords.Count - 2)] -len $height -opts $opts
                        if ($figWords.Count -gt 1) {
                            $outputFigLines += $outputFigText
                            $outputFigText = New-FigChar -len $height
                        }
                        $figWords = @()
                    } else {
                        $outputFigLines += $outputFigText
                        $outputFigText = New-FigChar -len $height
                    }
                }
            }

            if ($opts.width -gt 0 -and $opts.whitespaceBreak) {
                if (-not $isSpace -or $charIndex -eq $len - 1) {
                    $nextFigChars.chars += @{ fig = $figChar; overlap = $overlap }
                }

                if ($isSpace -or $charIndex -eq $len - 1) {
                    $tmpBreak = $null
                    while ($true) {
                        $textFigLine = Join-FigArray -array $nextFigChars.chars -len $height -opts $opts
                        $maxWidth = Get-FigLinesWidth -textLines $textFigLine
                        if ($maxWidth -ge $opts.width) {
                            $tmpBreak = Break-Word -figChars $nextFigChars.chars -len $height -opts $opts
                            $nextFigChars = @{ chars = $tmpBreak.chars }
                            $outputFigLines += $tmpBreak.outputFigText
                        } else {
                            break
                        }
                    }

                    if ($maxWidth -gt 0) {
                        if ($tmpBreak) {
                            $figWords += @{ fig = $textFigLine; overlap = 1 }
                        } else {
                            $figWords += @{ fig = $textFigLine; overlap = $nextFigChars.overlap }
                        }
                    }

                    if ($isSpace) {
                        $figWords += @{ fig = $figChar; overlap = $overlap }
                        $outputFigText = New-FigChar -len $height
                    }

                    if ($charIndex -eq $len - 1) {
                        $outputFigText = Join-FigArray -array $figWords -len $height -opts $opts
                    }

                    $nextFigChars = @{
                        chars = @()
                        overlap = $overlap
                    }
                    continue
                }
            }

            $outputFigText = Horizontal-Smush -textBlock1 $outputFigText -textBlock2 $figChar -overlap $overlap -opts $opts
        }
    }

    if (Get-FigLinesWidth -textLines $outputFigText -gt 0) {
        $outputFigLines += $outputFigText
    }

    if (-not $opts.showHardBlanks) {
        $outputFigLines = $outputFigLines | ForEach-Object {
            $_ | ForEach-Object {
                $_ -replace [regex]::Escape($opts.hardBlank), " "
            }
        }
    }

    return $outputFigLines
}


<#
    .SYNOPSIS
        Generates ASCII art text using a specified FIGlet font and options.
        
    .DESCRIPTION
        This function converts input text into ASCII art using the specified FIGlet font and rendering options.
        It processes each line of the input text, generates FIGlet lines for each, and combines them vertically
        to produce the final ASCII art output.
        
    .PARAMETER fontName
        The name of the FIGlet font to use for generating the ASCII art.
        
    .PARAMETER options
        A hashtable containing options to override the default font settings, including:
        - `width`: The maximum width of the output text.
        - `fittingRules`: Rules for horizontal and vertical smushing.
        - `printDirection`: The direction in which the text is printed (e.g., left-to-right or right-to-left).
        
    .PARAMETER txt
        The input text to be converted into ASCII art.
        
    .EXAMPLE
        $fontName = "Standard"
        $options = @{
        width = 80
        fittingRules = @{
        hLayout = [LayoutType]::ControlledSmushing
        vLayout = [LayoutType]::UniversalSmushing
        }
        printDirection = 0
        }
        $txt = "Hello, World!"
        $asciiArt = Generate-Text -fontName $fontName -options $options -txt $txt
        
        This example generates ASCII art for the text "Hello, World!" using the "Standard" FIGlet font and the specified options.
        
    .NOTES
        This function assumes the existence of helper functions such as `Generate-FigTextLines` for generating FIGlet lines
        and `Smush-VerticalFigLines` for combining FIGlet lines vertically.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Generate-Text {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$fontName,   # Font to use
        [hashtable]$options, # Options to override the defaults
        [string]$txt         # The text to make into ASCII Art
    )

    # Replace line endings with "\n"
    $txt = $txt -replace "`r`n", "`n" -replace "`r", "`n"

    # Split the text into lines
    $lines = $txt -split "`n"
    $figLines = @()
    
    # Generate FIGlet lines for each line of text
    foreach ($line in $lines) {
        
        $figLines += Generate-FigTextLines -txt $line -figChars $Script:FigFonts[$fontName] -opts $options
    }
    # Combine the FIGlet lines vertically
    $output = $figLines[0]
    for ($ii = 1; $ii -lt $figLines.Count; $ii++) {
        $lines = $figLines[$ii]  
        $output = Smush-VerticalFigLines -output $output -lines $lines -opts $options
    }
    # Return the final output as a single string
    return $output -join "`n"
}


<#
    .SYNOPSIS
        Retrieves the border symbols for a specified border type.
        
    .DESCRIPTION
        This function returns a hashtable containing the symbols used for constructing borders
        based on the specified border type. The hashtable includes symbols for the corners,
        spacers, and edges of the border.
        
    .PARAMETER BorderType
        The type of border to retrieve symbols for. Valid values are defined in the `BorderType` enum
        and include:
        - `Asterisk`
        - `Hash`
        - `Plus`
        - `Box`
        - `TwoLinesFrame`
        
    .EXAMPLE
        $borderSymbols = Get-BorderSymbol -BorderType "Box"
        
        This example retrieves the border symbols for the "Box" border type.
        
    .EXAMPLE
        $borderSymbols = Get-BorderSymbol -BorderType "Asterisk"
        
        This example retrieves the border symbols for the "Asterisk" border type.
        
    .NOTES
        This function uses a switch statement to map the specified border type to its corresponding
        symbols. The returned hashtable includes the following keys:
        - `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`: Symbols for the corners.
        - `TopSpacer`, `BottomSpacer`: Symbols for the horizontal edges.
        - `LeftSpacer`, `RightSpacer`: Symbols for the vertical edges.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-BorderSymbol {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [BorderType] # Use the enum for validation
        $BorderType
    )

    switch ($BorderType) {
        'Asterisk' { 
            return @{
                TopLeft = "*"; TopRight = "*"; BottomLeft = "*"; BottomRight = "*";
                TopSpacer = "*"; BottomSpacer = "*"; LeftSpacer = "*"; RightSpacer = "*"
            }
        }
        'Hash' { 
            return @{
                TopLeft = "#"; TopRight = "#"; BottomLeft = "#"; BottomRight = "#";
                TopSpacer = "#"; BottomSpacer = "#"; LeftSpacer = "#"; RightSpacer = "#"
            }
        }
        'Plus' { 
            return @{
                TopLeft = "+"; TopRight = "+"; BottomLeft = "+"; BottomRight = "+";
                TopSpacer = "+"; BottomSpacer = "+"; LeftSpacer = "+"; RightSpacer = "+"
            }
        }
        'Box' {
            return @{
                TopLeft = "┌"; TopRight = "┐"; BottomLeft = "└"; BottomRight = "┘";
                TopSpacer = "─"; BottomSpacer = "─"; LeftSpacer = "│"; RightSpacer = "│"
            }
        }
        'TwoLinesFrame' {
            return @{
                TopLeft = "/"; TopRight = "\"; BottomLeft = "\"; BottomRight = "/";
                TopSpacer = "="; BottomSpacer = "="; LeftSpacer = "||"; RightSpacer = "||"
            }
        }
        'DoubleBox' {
            return @{
                TopLeft = "╔"; TopRight = "╗"; BottomLeft = "╚"; BottomRight = "╝";
                TopSpacer = "═"; BottomSpacer = "═"; LeftSpacer = "║"; RightSpacer = "║"
            }
        }
        'DoubleCorners' {
            return @{
                TopLeft = "╔"; TopRight = "╗"; BottomLeft = "╚"; BottomRight = "╝";
                TopSpacer = "─"; BottomSpacer = "─"; LeftSpacer = "│"; RightSpacer = "│"
            }
        }
        'BubbleBorder' {
            return @{
                TopLeft = "(_)"; TopRight = "(_)"; BottomLeft = "(_)"; BottomRight = "(_)";
                TopSpacer = "(_)"; BottomSpacer = "(_)"; LeftSpacer = "(_)"; RightSpacer = "(_)"
            }
        }
        'BoxBorder' {
            return @{
                TopLeft = "|_|"; TopRight = "|_|"; BottomLeft = "|_|"; BottomRight = "|_|";
                TopSpacer = "|_|"; BottomSpacer = "|_|"; LeftSpacer = "|_|"; RightSpacer = "|_|"
            }
        }
        'Dots' { 
            return @{
                TopLeft = "."; TopRight = "."; BottomLeft = ":"; BottomRight = ":";
                TopSpacer = "."; BottomSpacer = "."; LeftSpacer = ":"; RightSpacer = ":"
            }
        }
        'DoubleDots' { 
            return @{
                TopLeft = "::"; TopRight = "::"; BottomLeft = "::"; BottomRight = "::";
                TopSpacer = ":"; BottomSpacer = ":"; LeftSpacer = "::"; RightSpacer = "::"
            }
        }
        'None' { 
            return @{
                TopLeft = ""; TopRight = ""; BottomLeft = ""; BottomRight = "";
                TopSpacer = ""; BottomSpacer = ""; LeftSpacer = ""; RightSpacer = ""
            }
        }
    }
}


<#
    .SYNOPSIS
        Calculates the maximum line width of the provided ASCII art text.
        
    .DESCRIPTION
        This function takes an array of text lines as input and determines the maximum width
        (number of characters) among all the lines. It is useful for measuring the width of
        ASCII art or text blocks.
        
    .PARAMETER textLines
        An array of strings representing the lines of text to measure.
        
    .EXAMPLE
        $textLines = @(
        "Hello, World!",
        "This is a test.",
        "PowerShell"
        )
        $maxWidth = Get-FigLinesWidth -textLines $textLines
        
        This example calculates the maximum line width from the provided text lines.
        
    .NOTES
        This function uses the `Measure-Object` cmdlet to determine the maximum length of the lines.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-FigLinesWidth {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string[]]$textLines # Array of lines for text
    )

    return ($textLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
}


<#
    .SYNOPSIS
        Retrieves metadata about a specified FIGlet font.
        
    .DESCRIPTION
        This function retrieves metadata for a given FIGlet font, including its options and header comment.
        It loads the font using the `Load-Font` function and extracts the header comment from the global
        `$Script:FigFonts` hashtable.
        
    .PARAMETER fontName
        The name of the FIGlet font to retrieve metadata for.
        
    .PARAMETER next
        An optional callback function to handle the result or error. If provided, the callback will be invoked
        with the font options and header comment.
        
    .EXAMPLE
        $fontName = "Standard"
        $metadata = Get-FontMetadata -fontName $fontName
        
        This example retrieves the metadata for the "Standard" FIGlet font.
        
    .NOTES
        This function assumes the existence of a `Load-Font` function to load the font options and a global
        `$Script:FigFonts` hashtable containing font metadata.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-FontMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string]$fontName,          # Name of the font
        [ScriptBlock]$next = $null # Optional callback function
    )

    # Ensure fontName is a string
    $fontName = [string]"$fontName"
    # Load the font
    $fontOpts = Load-Font -fontName "$fontName"
    $headerComment = $Script:FigFonts["$fontName"].comment    

    # Return the Task object
    return @($fontOpts, $headerComment)
}


<#
    .SYNOPSIS
        Retrieves the horizontal fitting rules for a specified layout type.
        
    .DESCRIPTION
        This function returns a hashtable containing the horizontal fitting rules based on the specified layout type.
        It supports multiple layout types, such as Default, Full, Fitted, and ControlledSmushing. The function maps
        the layout type to its corresponding fitting rules, including horizontal layout (`hLayout`) and individual
        smushing rules (`hRule1` to `hRule6`).
        
    .PARAMETER layout
        The layout type for which the horizontal fitting rules are retrieved. Valid values include:
        - `[LayoutType]::Default`
        - `[LayoutType]::Full`
        - `[LayoutType]::Fitted`
        - `[LayoutType]::ControlledSmushing`
        
    .PARAMETER options
        A hashtable containing the fitting rules for the Default layout. This parameter is used when the layout type
        is `[LayoutType]::Default`.
        
    .EXAMPLE
        $layout = [LayoutType]::Default
        $options = @{
        fittingRules = @{
        hLayout = [LayoutType]::Default
        hRule1 = $true
        hRule2 = $false
        hRule3 = $true
        hRule4 = $false
        hRule5 = $true
        hRule6 = $false
        }
        }
        $rules = Get-HorizontalFittingRules -layout $layout -options $options
        
        This example retrieves the horizontal fitting rules for the Default layout type using the specified options.
        
    .NOTES
        This function assumes the existence of a `[LayoutType]` enum or equivalent structure to define valid layout types.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-HorizontalFittingRules {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string]$layout,       # Layout type (e.g., [LayoutType]::Default, [LayoutType]::Full, etc.)
        [hashtable]$options    # Options object containing fitting rules
    )

    $props = @("hLayout", "hRule1", "hRule2", "hRule3", "hRule4", "hRule5", "hRule6")
    $params = @{}

    if ($layout -eq [LayoutType]::Default) {
        foreach ($prop in $props) {
            $params[$prop] = $options.fittingRules[$prop]
        }
    } elseif ($layout -eq [LayoutType]::Full) {
        $params = @{
            hLayout = [LayoutType]::Full
            hRule1 = $false
            hRule2 = $false
            hRule3 = $false
            hRule4 = $false
            hRule5 = $false
            hRule6 = $false
        }
    } elseif ($layout -eq [LayoutType]::Fitted) {
        $params = @{
            hLayout = [LayoutType]::Fitted
            hRule1 = $false
            hRule2 = $false
            hRule3 = $false
            hRule4 = $false
            hRule5 = $false
            hRule6 = $false
        }
    } elseif ($layout -eq [LayoutType]::ControlledSmushing) {
        $params = @{
            hLayout = [LayoutType]::ControlledSmushing
            hRule1 = $true
            hRule2 = $true
            hRule3 = $true
            hRule4 = $true
            hRule5 = $true
            hRule6 = $true
        }
    } elseif ($layout -eq [LayoutType]::UniversalSmushing) {
        $params = @{
            hLayout = [LayoutType]::UniversalSmushing
            hRule1 = $false
            hRule2 = $false
            hRule3 = $false
            hRule4 = $false
            hRule5 = $false
            hRule6 = $false
        }
    } else {
        return $null
    }

    return $params
}


<#
    .SYNOPSIS
        Calculates the horizontal smushing distance between two text strings based on the specified smushing rules.
        
    .DESCRIPTION
        This function determines the maximum horizontal smushing distance between two text strings (`txt1` and `txt2`)
        according to the smushing rules defined in the `opts.fittingRules` parameter. It evaluates character overlaps
        and applies specific smushing rules, such as Full, Fitted, and UniversalSmushing, to calculate the distance.
        
    .PARAMETER txt1
        The first text string to evaluate for horizontal smushing.
        
    .PARAMETER txt2
        The second text string to evaluate for horizontal smushing.
        
    .PARAMETER opts
        A hashtable containing smushing options, including:
        - `fittingRules.hLayout`: Specifies the horizontal layout type (e.g., Full, Fitted, UniversalSmushing).
        - `hardBlank`: The character used to represent hard blanks in FIGlet fonts.
        
    .EXAMPLE
        $txt1 = "Hello"
        $txt2 = "World"
        $opts = @{
        fittingRules = @{
        hLayout = [LayoutType]::UniversalSmushing
        }
        hardBlank = "@"
        }
        $smushLength = Get-HorizontalSmushLength -txt1 $txt1 -txt2 $txt2 -opts $opts
        
        This example calculates the horizontal smushing distance between the strings "Hello" and "World" using
        the UniversalSmushing layout type.
        
    .NOTES
        This function assumes the existence of a `[LayoutType]` enum or equivalent structure to define valid layout types.
        It also relies on the `hardBlank` option to handle special cases for smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-HorizontalSmushLength {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$txt1,          # First text string
        [string]$txt2,          # Second text string
        [hashtable]$opts        # Options for smushing
    )

    if ($opts.fittingRules.hLayout -eq [LayoutType]::Full) {
        return 0
    }

    $len1 = $txt1.Length
    $len2 = $txt2.Length
    $maxDist = $len1
    $curDist = 1
    $breakAfter = $false
    $validSmush = $false

    if ($len1 -eq 0) {
        return 0
    }
    $stopWhile = $false
    while ($curDist -le $maxDist -and (-not $stopWhile)) {
        $seg1StartPos = $len1 - $curDist
        $seg1 = $txt1.Substring($seg1StartPos, $curDist)
        $seg2 = $txt2.Substring(0, [math]::Min($curDist, $len2))
        for ($ii = 0; $ii -lt [math]::Min($curDist, $len2) -and (-not $stopWhile); $ii++) {
            $ch1 = $seg1.Substring($ii, 1)
            $ch2 = $seg2.Substring($ii, 1)
            if ($ch1 -ne " " -and $ch2 -ne " ") {
                if ($opts.fittingRules.hLayout -eq [LayoutType]::Fitted) {
                    $curDist -= 1
                    $stopWhile = $true
                    break 
                } elseif ($opts.fittingRules.hLayout -eq [LayoutType]::UniversalSmushing) {
                    if ($ch1 -eq $opts.hardBlank -or $ch2 -eq $opts.hardBlank) {
                        $curDist -= 1 # universal smushing does not smush hardblanks
                    }
                    $stopWhile = $true
                    break
                } else {
                    $breakAfter = $true # we know we need to break, but we need to check if our smushing rules will allow us to smush the overlapped characters
                    $validSmush = $false # the below checks will let us know if we can smush these characters

                    if ($opts.fittingRules.hRule1) {
                        $validSmush = hRule1-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $validSmush -and $opts.fittingRules.hRule2) {
                        $validSmush = hRule2-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $validSmush -and $opts.fittingRules.hRule3) {
                        $validSmush = hRule3-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $validSmush -and $opts.fittingRules.hRule4) {
                        $validSmush = hRule4-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $validSmush -and $opts.fittingRules.hRule5) {
                        $validSmush = hRule5-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $validSmush -and $opts.fittingRules.hRule6) {
                        $validSmush = hRule6-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }

                    if (-not $validSmush) {
                        $curDist -= 1
                        $stopWhile = $true
                        break
                    }
                }
            }
        }
        if($stopWhile) {
            break
        }

        if ($breakAfter) {
            break
        }
        $curDist++
    }

    return [math]::Min($maxDist, $curDist)
}


<#
    .SYNOPSIS
        Retrieves smushing rules for horizontal and vertical layouts based on the specified layout values.
        
    .DESCRIPTION
        This function calculates the smushing rules for both horizontal and vertical layouts based on the provided
        `oldLayout` and `newLayout` values. It processes a predefined set of codes to determine the layout type
        (e.g., Fitted, UniversalSmushing) and individual smushing rules (e.g., `hRule1`, `vRule5`). The resulting
        rules are returned as a hashtable.
        
    .PARAMETER oldLayout
        The legacy layout value used to determine smushing rules if `newLayout` is not provided.
        
    .PARAMETER newLayout
        The updated layout value used to determine smushing rules. If provided, it takes precedence over `oldLayout`.
        
    .EXAMPLE
        $oldLayout = 2048
        $newLayout = 8192
        $rules = Get-SmushingRules -oldLayout $oldLayout -newLayout $newLayout
        
        This example retrieves smushing rules based on the provided `oldLayout` and `newLayout` values.
        
    .EXAMPLE
        $oldLayout = 128
        $rules = Get-SmushingRules -oldLayout $oldLayout
        
        This example retrieves smushing rules using only the `oldLayout` value.
        
    .NOTES
        The function uses a predefined set of codes to map layout values to smushing rules. The resulting hashtable
        includes keys such as `hLayout`, `vLayout`, `hRule1`, `vRule5`, and others.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-SmushingRules {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [int]$oldLayout,
        [int]$newLayout
    )

    # Initialize rules
    $rules = @{}

    # Define codes array
    $codes = @(
        @{ Value = 16384; Key = "vLayout"; Default = [LayoutType]::UniversalSmushing },
        @{ Value = 8192; Key = "vLayout"; Default = [LayoutType]::Fitted },
        @{ Value = 4096; Key = "vRule5"; Default = $true },
        @{ Value = 2048; Key = "vRule4"; Default = $true },
        @{ Value = 1024; Key = "vRule3"; Default = $true },
        @{ Value = 512; Key = "vRule2"; Default = $true },
        @{ Value = 256; Key = "vRule1"; Default = $true },
        @{ Value = 128; Key = "hLayout"; Default = [LayoutType]::UniversalSmushing },
        @{ Value = 64; Key = "hLayout"; Default = [LayoutType]::Fitted },
        @{ Value = 32; Key = "hRule6"; Default = $true },
        @{ Value = 16; Key = "hRule5"; Default = $true },
        @{ Value = 8; Key = "hRule4"; Default = $true },
        @{ Value = 4; Key = "hRule3"; Default = $true },
        @{ Value = 2; Key = "hRule2"; Default = $true },
        @{ Value = 1; Key = "hRule1"; Default = $true }
    )

    # Determine the layout value
    $val = if ($null -ne $newLayout) { $newLayout } else { $oldLayout }

    # Process codes
    foreach ($code in $codes) {
        if ($val -ge $code.Value) {
            $val -= $code.Value
            if (-not $rules.ContainsKey($code.Key)) {
                $rules[$code.Key] = $code.Default
            }
        } elseif ($code.Key -notin @("vLayout", "hLayout")) {
            $rules[$code.Key] = $false
        }
    }

    # Handle undefined horizontal layout
    if (-not $rules.ContainsKey("hLayout")) {
        if ($oldLayout -eq 0) {
            $rules["hLayout"] = [LayoutType]::Fitted
        } elseif ($oldLayout -eq -1) {
            $rules["hLayout"] = [LayoutType]::Full
        } else {
            if (
                $rules["hRule1"] -or
                $rules["hRule2"] -or
                $rules["hRule3"] -or
                $rules["hRule4"] -or
                $rules["hRule5"] -or
                $rules["hRule6"]
            ) {
                $rules["hLayout"] = [LayoutType]::ControlledSmushing
            } else {
                $rules["hLayout"] = [LayoutType]::UniversalSmushing
            }
        }
    } elseif ($rules["hLayout"] -eq [LayoutType]::UniversalSmushing) {
        if (
            $rules["hRule1"] -or
            $rules["hRule2"] -or
            $rules["hRule3"] -or
            $rules["hRule4"] -or
            $rules["hRule5"] -or
            $rules["hRule6"]
        ) {
            $rules["hLayout"] = [LayoutType]::ControlledSmushing
        }
    }

    # Handle undefined vertical layout
    if (-not $rules.ContainsKey("vLayout")) {
        if (
            $rules["vRule1"] -or
            $rules["vRule2"] -or
            $rules["vRule3"] -or
            $rules["vRule4"] -or
            $rules["vRule5"]
        ) {
            $rules["vLayout"] = [LayoutType]::ControlledSmushing
        } else {
            $rules["vLayout"] = [LayoutType]::Full
        }
    } elseif ($rules["vLayout"] -eq [LayoutType]::UniversalSmushing) {
        if (
            $rules["vRule1"] -or
            $rules["vRule2"] -or
            $rules["vRule3"] -or
            $rules["vRule4"] -or
            $rules["vRule5"]
        ) {
            $rules["vLayout"] = [LayoutType]::ControlledSmushing
        }
    }

    return $rules
}


<#
    .SYNOPSIS
        Retrieves vertical fitting rules for a specified layout type.
        
    .DESCRIPTION
        This function returns a hashtable containing the vertical fitting rules based on the specified layout type.
        It supports multiple layout types, such as Default, Full, Fitted, and ControlledSmushing. The function maps
        the layout type to its corresponding fitting rules, including vertical layout (`vLayout`) and individual
        smushing rules (`vRule1` to `vRule5`).
        
    .PARAMETER layout
        The layout type for which the vertical fitting rules are retrieved. Valid values include:
        - `[LayoutType]::Default`
        - `[LayoutType]::Full`
        - `[LayoutType]::Fitted`
        - `[LayoutType]::ControlledSmushing`
        
    .PARAMETER options
        A hashtable containing the fitting rules for the Default layout. This parameter is used when the layout type
        is `[LayoutType]::Default`.
        
    .EXAMPLE
        $layout = [LayoutType]::Default
        $options = @{
        fittingRules = @{
        vLayout = [LayoutType]::Default
        vRule1 = $true
        vRule2 = $false
        vRule3 = $true
        vRule4 = $false
        vRule5 = $true
        }
        }
        $rules = Get-VerticalFittingRules -layout $layout -options $options
        
        This example retrieves the vertical fitting rules for the Default layout type using the specified options.
        
    .NOTES
        This function assumes the existence of a `[LayoutType]` enum or equivalent structure to define valid layout types.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-VerticalFittingRules {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string]$layout,       # Layout type (e.g., [LayoutType]::Default, [LayoutType]::Full, etc.)
        [hashtable]$options    # Options object containing fitting rules
    )

    $props = @("vLayout", "vRule1", "vRule2", "vRule3", "vRule4", "vRule5")
    $params = @{}

    if ($layout -eq [LayoutType]::Default) {
        foreach ($prop in $props) {
            $params[$prop] = $options.fittingRules[$prop]
        }
    } elseif ($layout -eq [LayoutType]::Full) {
        $params = @{
            vLayout = [LayoutType]::Full
            vRule1 = $false
            vRule2 = $false
            vRule3 = $false
            vRule4 = $false
            vRule5 = $false
        }
    } elseif ($layout -eq [LayoutType]::Fitted) {
        $params = @{
            vLayout = [LayoutType]::Fitted
            vRule1 = $false
            vRule2 = $false
            vRule3 = $false
            vRule4 = $false
            vRule5 = $false
        }
    } elseif ($layout -eq [LayoutType]::ControlledSmushing) {
        $params = @{
            vLayout = [LayoutType]::ControlledSmushing
            vRule1 = $true
            vRule2 = $true
            vRule3 = $true
            vRule4 = $true
            vRule5 = $true
        }
    } elseif ($layout -eq [LayoutType]::UniversalSmushing) {
        $params = @{
            vLayout = [LayoutType]::UniversalSmushing
            vRule1 = $false
            vRule2 = $false
            vRule3 = $false
            vRule4 = $false
            vRule5 = $false
        }
    } else {
        return $null
    }

    return $params
}


<#
    .SYNOPSIS
        Calculates the maximum vertical smushing distance between two sets of text lines.
        
    .DESCRIPTION
        This function determines the maximum number of overlapping lines (`curDist`) that can be vertically smushed
        between two sets of text lines (`lines1` and `lines2`) based on the smushing rules defined in the `opts` parameter.
        It evaluates each pair of overlapping lines using the `Can-VerticalSmush` function and adjusts the distance
        based on the results ("valid", "invalid", or "end").
        
    .PARAMETER lines1
        An array of strings representing the first set of text lines.
        
    .PARAMETER lines2
        An array of strings representing the second set of text lines.
        
    .PARAMETER opts
        A hashtable containing smushing options, including:
        - `fittingRules.vLayout`: Specifies the vertical layout type (e.g., Full, Fitted, UniversalSmushing).
        - Additional smushing rules for evaluating line overlaps.
        
    .EXAMPLE
        $lines1 = @(
        "Hello",
        "World"
        )
        $lines2 = @(
        "Foo",
        "Bar"
        )
        $opts = @{
        fittingRules = @{
        vLayout = [LayoutType]::UniversalSmushing
        }
        }
        $maxDist = Get-VerticalSmushDist -lines1 $lines1 -lines2 $lines2 -opts $opts
        
        This example calculates the maximum vertical smushing distance between the two sets of text lines.
        
    .NOTES
        This function relies on the `Can-VerticalSmush` helper function to evaluate individual line overlaps.
        The result is determined based on the smushing rules and the overlap validity.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Get-VerticalSmushDist {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string[]] $lines1,
        [string[]] $lines2,
        [hashtable] $opts
    )

    $maxDist = $lines1.Count
    $len1 = $lines1.Count
    $len2 = $lines2.Count
    $curDist = 1

    while ($curDist -le $maxDist) {
        $startIndex = [math]::Max(0, $len1 - $curDist)
        $subLines1 = $lines1[$startIndex..($len1 - 1)]
        $subLines2 = $lines2[0..([math]::Min($len2, $curDist) - 1)]
        $slen = $subLines2.Count
        $result = ""

        for ($ii = 0; $ii -lt $slen; $ii++) {
            $ret = Can-VerticalSmush -txt1 $subLines1[$ii] -txt2 $subLines2[$ii] -opts $opts
            if ($ret -eq "end") {
                $result = $ret
                break
            } elseif ($ret -eq "invalid") {
                $result = $ret
                break
            } else {
                $result = "valid"
            }
        }

        if ($result -eq "invalid") {
            $curDist--
            break
        }
        if ($result -eq "end") {
            break
        }
        if ($result -eq "valid") {
            $curDist++
        }
    }

    return [math]::Min($maxDist, $curDist)
}


<#
    .SYNOPSIS
        Combines two horizontal text blocks with optional overlapping smushing.
        
    .DESCRIPTION
        The Horizontal-Smush function takes two horizontal text blocks (`textBlock1` and `textBlock2`) and combines
        them into a single text block. If an overlap is specified, the function applies horizontal smushing rules
        to the overlapping characters. The smushing behavior is determined by the options provided in the `opts`
        parameter, including the horizontal layout type (`hLayout`) and specific smushing rules (`hRule1` to `hRule6`).
        
        The function processes each line of the text blocks, calculates the overlapping segments, and applies the
        appropriate smushing rules to generate the combined output.
        
    .PARAMETER textBlock1
        An array of strings representing the first horizontal text block.
        
    .PARAMETER textBlock2
        An array of strings representing the second horizontal text block.
        
    .PARAMETER overlap
        The number of overlapping characters to smush. If set to 0, no smushing is applied, and the text blocks
        are concatenated.
        
    .PARAMETER opts
        A hashtable containing options for horizontal smushing, including:
        - `fittingRules.hLayout`: Specifies the horizontal layout type (e.g., Fitted, UniversalSmushing, ControlledSmushing).
        - `fittingRules.hRule1` to `hRule6`: Boolean flags indicating which smushing rules to apply.
        - `hardBlank`: The character used to represent hard blanks in FIGlet fonts.
        - `height`: The number of rows in the text blocks.
        
    .EXAMPLE
        $textBlock1 = @(
        "Hello",
        "World"
        )
        $textBlock2 = @(
        "Foo",
        "Bar"
        )
        $opts = @{
        fittingRules = @{
        hLayout = [LayoutType]::ControlledSmushing
        hRule1 = $true
        hRule2 = $false
        hRule3 = $true
        hRule4 = $false
        hRule5 = $true
        hRule6 = $false
        }
        hardBlank = "@"
        height = 2
        }
        $result = Horizontal-Smush -textBlock1 $textBlock1 -textBlock2 $textBlock2 -overlap 3 -opts $opts
        
        This example combines two horizontal text blocks with 3 characters of overlap using ControlledSmushing rules.
        
    .NOTES
        This function relies on the following helper functions:
        - `Uni-Smush`: Applies universal smushing rules to overlapping characters.
        - `hRule1-Smush` to `hRule6-Smush`: Applies specific controlled smushing rules to overlapping characters.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Horizontal-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string[]]$textBlock1,  # First text block
        [string[]]$textBlock2,  # Second text block
        [int]$overlap,          # Overlap length
        [hashtable]$opts        # Options containing fitting rules and hardBlank
    )

    $outputFig = @()
    $height = $opts.height

    for ($ii = 0; $ii -lt $height; $ii++) {
        $txt1 = $textBlock1[$ii]
        $txt2 = $textBlock2[$ii]
        $len1 = $txt1.Length
        $len2 = $txt2.Length
        $overlapStart = $len1 - $overlap
        $piece1 = $txt1.Substring(0, [math]::Max(0, $overlapStart))
        $piece2 = ""

        # Determine overlap piece
        $seg1StartPos = [math]::Max(0, $len1 - $overlap)
        $seg1 = $txt1.Substring($seg1StartPos, [math]::Min($overlap, $len1 - $seg1StartPos))
        $seg2 = $txt2.Substring(0, [math]::Min($overlap, $len2))

        for ($jj = 0; $jj -lt $overlap; $jj++) {
            $ch1 = if ($jj -lt $len1) { $seg1[$jj] } else { " " }
            $ch2 = if ($jj -lt $len2) { $seg2[$jj] } else { " " }

            if ($ch1 -ne " " -and $ch2 -ne " ") {
                if ($opts.fittingRules.hLayout -eq [LayoutType]::Fitted) {
                    $piece2 += Uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                } elseif ($opts.fittingRules.hLayout -eq [LayoutType]::UniversalSmushing) {
                    $piece2 += Uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                } else {
                    # Controlled Smushing
                    $nextCh = ""
                    if (-not $nextCh -and $opts.fittingRules.hRule1) {
                        $nextCh = hRule1-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $nextCh -and $opts.fittingRules.hRule2) {
                        $nextCh = hRule2-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $nextCh -and $opts.fittingRules.hRule3) {
                        $nextCh = hRule3-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $nextCh -and $opts.fittingRules.hRule4) {
                        $nextCh = hRule4-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $nextCh -and $opts.fittingRules.hRule5) {
                        $nextCh = hRule5-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    if (-not $nextCh -and $opts.fittingRules.hRule6) {
                        $nextCh = hRule6-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
                    }
                    $nextCh = if ($nextCh) { $nextCh } else { Uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank }
                    $piece2 += $nextCh
                }
            } else {
                $piece2 += Uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $opts.hardBlank
            }
        }

        if ($overlap -ge $len2) {
            $piece3 = ""
        } else {
            $piece3 = $txt2.Substring($overlap, [math]::Max(0, $len2 - $overlap))
        }

        $outputFig += $piece1 + $piece2 + $piece3
    }

    return $outputFig
}


<#
    .SYNOPSIS
        Applies Rule 1: Equal Character Smushing.
        
    .DESCRIPTION
        This function smushes two characters into a single character if they are the same and not a hardblank.
        Rule 1, known as "Equal Character Smushing," ensures that identical characters are combined into one,
        except when the characters are hardblanks.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .PARAMETER hardBlank
        The character used to represent hardblanks in FIGlet fonts. Hardblanks are excluded from smushing.
        
    .EXAMPLE
        $ch1 = "H"
        $ch2 = "H"
        $hardBlank = "@"
        $result = hRule1-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example smushes the characters "H" and "H" into a single "H" since they are identical and not a hardblank.
        
    .EXAMPLE
        $ch1 = "@"
        $ch2 = "@"
        $hardBlank = "@"
        $result = hRule1-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example does not smush the characters "@" and "@" because they are hardblanks.
        
    .NOTES
        This function implements Rule 1 of the FIGlet smushing rules: Equal Character Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function hRule1-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2,
        [string]$hardBlank
    )
    if ($ch1 -eq $ch2 -and $ch1 -ne $hardBlank) {
        return $ch1
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 2: Underscore Smushing.
        
    .DESCRIPTION
        This function smushes an underscore (`_`) with specific characters (`|`, `/`, `\`, `[`, `]`, `{`, `}`, `(`, `)`, `<`, `>`)
        according to Rule 2 of the FIGlet smushing rules. If one of the characters is an underscore and the other is
        in the allowed set, the underscore is replaced by the other character.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .EXAMPLE
        $ch1 = "_"
        $ch2 = "|"
        $result = hRule2-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the underscore (`_`) with the pipe (`|`) and returns `|`.
        
    .EXAMPLE
        $ch1 = "/"
        $ch2 = "_"
        $result = hRule2-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the underscore (`_`) with the forward slash (`/`) and returns `/`.
        
    .EXAMPLE
        $ch1 = "_"
        $ch2 = "A"
        $result = hRule2-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the underscore (`_`) with the character `A` and returns `$false`.
        
    .NOTES
        This function implements Rule 2 of the FIGlet smushing rules: Underscore Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function hRule2-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    $rule2Str = "|/\[]{}()<>"
    if ($ch1 -eq "_") {
        if ($rule2Str.Contains($ch2)) {
            return $ch2
        }
    } elseif ($ch2 -eq "_") {
        if ($rule2Str.Contains($ch1)) {
            return $ch1
        }
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 3: Hierarchy Smushing.
        
    .DESCRIPTION
        This function smushes two characters based on their hierarchy class according to Rule 3 of the FIGlet smushing rules.
        A hierarchy of six classes is defined: "|", "/\", "[]", "{}", "()", and "<>". When two smushing characters belong
        to different classes, the character from the latter class in the hierarchy is used.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .EXAMPLE
        $ch1 = "|"
        $ch2 = ">"
        $result = hRule3-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters "|" and ">" and returns ">".
        
    .EXAMPLE
        $ch1 = "("
        $ch2 = "["
        $result = hRule3-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters "(" and "[" and returns "[".
        
    .EXAMPLE
        $ch1 = "|"
        $ch2 = "|"
        $result = hRule3-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters "|" and "|" because they belong to the same class and returns `$false`.
        
    .NOTES
        This function implements Rule 3 of the FIGlet smushing rules: Hierarchy Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function hRule3-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    # Define the hierarchy classes explicitly
    $rule3Classes = @("|", "/", "\", "[", "]", "{", "}", "(", ")", "<", ">")
    
    # Get the indices of the characters in the hierarchy
    $r3_pos1 = $rule3Classes.IndexOf($ch1)
    $r3_pos2 = $rule3Classes.IndexOf($ch2)

    # Ensure both characters are in the hierarchy
    if ($r3_pos1 -ne -1 -and $r3_pos2 -ne -1) {
        # Check if characters are from different classes
        if ($r3_pos1 -ne $r3_pos2) {
            # Return the character from the latter class
            return $rule3Classes[[math]::Max($r3_pos1, $r3_pos2)]
        }
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 4: Opposite Pair Smushing.
        
    .DESCRIPTION
        This function smushes opposing pairs of brackets (`[]` or `][`), braces (`{}` or `}{`), and parentheses (`()` or `)(`)
        into a vertical bar (`|`). It checks if the two characters belong to the predefined set of opposing pairs and replaces
        them with a vertical bar if they meet the criteria.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .EXAMPLE
        $ch1 = "["
        $ch2 = "]"
        $result = hRule4-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `[` and `]` into a vertical bar (`|`).
        
    .EXAMPLE
        $ch1 = "("
        $ch2 = ")"
        $result = hRule4-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `(` and `)` into a vertical bar (`|`).
        
    .EXAMPLE
        $ch1 = "["
        $ch2 = "}"
        $result = hRule4-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters `[` and `}` and returns `$false`.
        
    .NOTES
        This function implements Rule 4 of the FIGlet smushing rules: Opposite Pair Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function hRule4-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    $rule4Str = "[] {} ()"
    $r4_pos1 = $rule4Str.IndexOf($ch1)
    $r4_pos2 = $rule4Str.IndexOf($ch2)
    if ($r4_pos1 -ne -1 -and $r4_pos2 -ne -1) {
        if ([math]::Abs($r4_pos1 - $r4_pos2) -le 1) {
            return "|"
        }
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 5: Big X Smushing.
        
    .DESCRIPTION
        This function smushes specific character pairs into predefined replacements according to Rule 5 of the FIGlet
        smushing rules. It replaces:
        - `"/\"` with `"|"`,
        - `"\\"` with `"Y"`,
        - `"><"` with `"X"`.
        If the character pair does not match any of these patterns, the function returns `$false`.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .EXAMPLE
        $ch1 = "/"
        $ch2 = "\"
        $result = hRule5-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `"/\"` into `"|"`.
        
    .EXAMPLE
        $ch1 = ">"
        $ch2 = "<"
        $result = hRule5-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `"><"` into `"X"`.
        
    .EXAMPLE
        $ch1 = "/"
        $ch2 = ">"
        $result = hRule5-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters `"/"` and `">"` and returns `$false`.
        
    .NOTES
        This function implements Rule 5 of the FIGlet smushing rules: Big X Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function hRule5-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    $rule5Str = "/\ \/ ><"
    $rule5Hash = @{
        0 = "|"
        3 = "Y"
        6 = "X"
    }

    if($rule5Str.IndexOf($ch1+$ch2) -ge 0) {
        return $rule5Hash[$rule5Str.IndexOf($ch1+$ch2)]
    }

    return $false
}


<#
    .SYNOPSIS
        Applies Rule 6: Hardblank Smushing.
        
    .DESCRIPTION
        This function smushes two hardblanks together into a single hardblank according to Rule 6 of the FIGlet
        smushing rules. If both characters are hardblanks, they are replaced with a single hardblank. If either
        character is not a hardblank, the function returns `$false`.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .PARAMETER hardBlank
        The character used to represent hardblanks in FIGlet fonts.
        
    .EXAMPLE
        $ch1 = "@"
        $ch2 = "@"
        $hardBlank = "@"
        $result = hRule6-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example smushes two hardblanks (`@` and `@`) into a single hardblank (`@`).
        
    .EXAMPLE
        $ch1 = "@"
        $ch2 = "H"
        $hardBlank = "@"
        $result = hRule6-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example does not smush the characters `@` and `H` because `H` is not a hardblank, and it returns `$false`.
        
    .NOTES
        This function implements Rule 6 of the FIGlet smushing rules: Hardblank Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function hRule6-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2,
        [string]$hardBlank
    )
    if ($ch1 -eq $hardBlank -and $ch2 -eq $hardBlank) {
        return $hardBlank
    }
    return $false
}


<#
    .SYNOPSIS
        Measures the execution time of a command or function by marking its start and end points.
        
    .DESCRIPTION
        The Invoke-TimeSignal function is used to measure the time spent executing a specific command or function.
        It works by marking the start and end points of the execution and calculating the time difference between them.
        The function uses a global hashtable `$Script:TimeSignals` to store the start time for each command or function.
        
        When the `-Start` parameter is used, the function records the current time for the specified command or function.
        If the command is already being tracked, the start time is updated. When the `-End` parameter is used, the function
        calculates the elapsed time since the start and logs the result. If the command was not started, a message is logged.
        
    .PARAMETER Start
        Marks the start of the time measurement for the current command or function.
        
    .PARAMETER End
        Marks the end of the time measurement for the current command or function and calculates the elapsed time.
        
    .EXAMPLE
        Invoke-TimeSignal -Start
        
        This example marks the start of the time measurement for the current command or function.
        
    .EXAMPLE
        Invoke-TimeSignal -End
        
        This example marks the end of the time measurement for the current command or function and logs the elapsed time.
        
    .NOTES
        This function uses the PSFramework module for logging and message handling. Ensure the PSFramework module
        is installed and imported before using this function.
        
        The function relies on a global hashtable `$Script:TimeSignals` to track the start times of commands or functions.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Invoke-TimeSignal {
    [CmdletBinding(DefaultParameterSetName = 'Start')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Start', Position = 1 )]
        [switch] $Start,
        
        [Parameter(Mandatory = $True, ParameterSetName = 'End', Position = 2 )]
        [switch] $End
    )

    $Time = (Get-Date)

    $Command = (Get-PSCallStack)[1].Command

    if ($Start) {
        if ($Script:TimeSignals.ContainsKey($Command)) {
            Write-PSFMessage -Level Verbose -Message "The command '$Command' was already taking part in time measurement. The entry has been update with current date and time."
            $Script:TimeSignals[$Command] = $Time
        }
        else {
            $Script:TimeSignals.Add($Command, $Time)
        }
    }
    else {
        if ($Script:TimeSignals.ContainsKey($Command)) {
            $TimeSpan = New-TimeSpan -End $Time -Start (($Script:TimeSignals)[$Command])

            Write-PSFMessage -Level Verbose -Message "Total time spent inside the function was $TimeSpan" -Target $TimeSpan -FunctionName $Command -Tag "TimeSignal"
            $null = $Script:TimeSignals.Remove($Command)
        }
        else {
            Write-PSFMessage -Level Verbose -Message "The command '$Command' was never started to take part in time measurement."
        }
    }
}


<#
    .SYNOPSIS
        Joins an array of ASCII words or single characters into a single FIGlet line.
        
    .DESCRIPTION
        This function combines an array of ASCII words or single characters into a single FIGlet line.
        It processes each element in the array and smushes it horizontally with the accumulated result
        using the specified smushing rules and options.
        
    .PARAMETER array
        An array of ASCII words or single characters. Each element is a hashtable with the following keys:
        - `fig`: The FIGlet representation of the word or character.
        - `overlap`: The number of overlapping characters to smush.
        
    .PARAMETER len
        The height of the FIGlet characters (number of rows).
        
    .PARAMETER opts
        A hashtable containing options for smushing, including:
        - `fittingRules.hLayout`: Specifies the horizontal layout type (e.g., Full, Fitted, ControlledSmushing).
        - Additional smushing rules for evaluating overlaps.
        
    .EXAMPLE
        $array = @(
        @{ fig = @("H", "H"); overlap = 1 },
        @{ fig = @("e", "e"); overlap = 1 },
        @{ fig = @("l", "l"); overlap = 1 },
        @{ fig = @("l", "l"); overlap = 1 },
        @{ fig = @("o", "o"); overlap = 1 }
        )
        $len = 2
        $opts = @{
        fittingRules = @{
        hLayout = [LayoutType]::ControlledSmushing
        }
        }
        $result = Join-FigArray -array $array -len $len -opts $opts
        
        This example joins the characters "H", "e", "l", "l", and "o" into a single FIGlet line.
        
    .NOTES
        This function relies on the `Horizontal-Smush` helper function to smush characters horizontally
        and the `New-FigChar` function to initialize the accumulator.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Join-FigArray {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [array]$array, # Array of ASCII words or single characters: {fig: array, overlap: number}
        [int]$len,     # Height of the characters (number of rows)
        [hashtable]$opts # Options object
    )

    $acc = New-FigChar -len $len
    foreach ($data in $array) {
        $acc = Horizontal-Smush -textBlock1 $acc -textBlock2 $data.fig -overlap $data.overlap -opts $opts
    }
    return $acc
}


<#
    .SYNOPSIS
        Loads a FIGlet font from the specified font path and parses its data.
        
    .DESCRIPTION
        This function loads a FIGlet font file by its name from the configured font path. If the font is already
        loaded in the global `$Script:FigFonts` hashtable, it retrieves the cached font data. Otherwise, it reads
        the font file, parses its content, and stores the parsed font options in the global hashtable for future use.
        
    .PARAMETER fontName
        The name of the FIGlet font to load. The font file should have a `.flf` extension and reside in the
        directory specified by `$Script:FigDefaults.fontPath`.
        
    .EXAMPLE
        $fontName = "Standard"
        $fontOptions = Load-Font -fontName $fontName
        
        This example loads the "Standard" FIGlet font and returns its parsed options.
        
    .NOTES
        This function relies on the `Parse-Font` helper function to parse the font data and extract its options.
        If the font file cannot be found or an error occurs during loading, the function logs an error message
        and stops execution.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Load-Font {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$fontName       # Name of the font to load
    )
    # Construct the font URL
    $fontPath = $Script:FigDefaults.fontPath
    $fontUrl =  Join-Path $fontPath "$fontName.flf"
    # Check if the font already exists in the global $Script:FigFonts hashtable
    if ($Script:FigFonts["$fontName"]) {
        return $Script:FigFonts["$fontName"]
    }

    # Fetch the font data
    try {
        $response = (Get-Content -Path $fontUrl -Raw)
        if ($response) {
            # Parse the font and store it in $Script:FigFonts
            $FontData = $response
            $fontOptions = Parse-Font -fontName $fontName -fontData $FontData
            $Script:FigFonts[$fontName] = $fontOptions

            return $fontOptions
        } else {
            throw
        }
    } catch {
        Write-PSFMessage -Level Error -Message "Something went wrong during request to ADO: $($_.ErrorDetails)" -Exception $PSItem.Exception
        Stop-PSFFunction -Message "Stopping because of errors"
        throw $($PSItem.Exception)
    }
}


<#
    .SYNOPSIS
        Creates a new empty ASCII placeholder with the specified number of rows.
        
    .DESCRIPTION
        This function generates an array of empty strings, where the number of elements in the array corresponds
        to the specified number of rows. It is typically used as a placeholder for FIGlet characters or ASCII art
        that will be populated later.
        
    .PARAMETER len
        The number of rows to include in the placeholder. Each row is represented as an empty string.
        
    .EXAMPLE
        $placeholder = New-FigChar -len 5
        
        This example creates a placeholder with 5 rows, each represented as an empty string.
        
    .NOTES
        This function is useful for initializing FIGlet character arrays or ASCII art structures.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function New-FigChar {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [OutputType([string[]])]
    param (
        [int]$len # Number of rows
    )

    $outputFigText = @()
    for ($row = 0; $row -lt $len; $row++) {
        $outputFigText += ""
    }
    return $outputFigText
}


<#
    .SYNOPSIS
        Pads each line in an array of strings with a specified number of spaces.
        
    .DESCRIPTION
        This function takes an array of strings (`lines`) and appends a specified number of spaces (`numSpaces`)
        to the end of each line. It returns a new array containing the padded lines.
        
    .PARAMETER lines
        An array of strings representing the lines to be padded.
        
    .PARAMETER numSpaces
        The number of spaces to append to the end of each line.
        
    .EXAMPLE
        $lines = @("Line1", "Line2", "Line3")
        $numSpaces = 4
        $paddedLines = Pad-Lines -lines $lines -numSpaces $numSpaces
        
        This example pads each line in the array with 4 spaces and returns the padded lines.
        
    .NOTES
        This function creates a new array to store the padded lines and does not modify the original input array.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Pad-Lines {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string[]]$lines,     # Array of lines to pad
        [int]$numSpaces       # Number of spaces to pad
    )

    # Create the padding string
    $padding = " " * $numSpaces

    # Create a new array with padded lines
    $paddedLines = @()
    foreach ($line in $lines) {
        $paddedLines += $line + $padding
    }

    return $paddedLines
}


<#
    .SYNOPSIS
        Parses data from a FIGlet font file and stores it in the global FIGlet fonts hashtable.
        
    .DESCRIPTION
        This function processes the raw data of a FIGlet font file, normalizes its line endings, and extracts
        metadata such as height, baseline, layout, and smushing rules. The parsed font data is stored in the
        global `$Script:FigFonts` hashtable under the specified font name. It also validates the header data
        to ensure the font file is correctly formatted.
        
    .PARAMETER FontName
        The name of the FIGlet font being parsed. This is used as the key in the `$Script:FigFonts` hashtable.
        
    .PARAMETER FontData
        The raw data of the FIGlet font file as a string. This data is parsed to extract font metadata and options.
        
    .EXAMPLE
        $FontName = "Standard"
        $FontData = Get-Content -Path "C:\Fonts\Standard.flf" -Raw
        Parse-Font -FontName $FontName -FontData $FontData
        
        This example parses the "Standard" FIGlet font file and stores its metadata and options in the global
        `$Script:FigFonts` hashtable.
        
    .NOTES
        This function relies on the `Get-SmushingRules` helper function to calculate smushing rules based on
        the font's layout values. It validates the header data to ensure the font file is properly formatted.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Parse-Font {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$FontName, # Name of the font
        [string]$FontData      # Data from the FIGlet font file
    )

    
    # Normalize line endings
    $FontData = "$FontData" -replace "`r`n", "`n" -replace "`r", "`n"
    $Script:FigFonts[$FontName] = @{}

    $lines = $FontData -split "`n"
    $headerData = ($lines[0] -split " ")
    $lines = $lines[1..($lines.Count - 1)]
    $figFont = $Script:FigFonts[$FontName]
    $opts = @{}
    # Parse header data
    $opts.hardBlank = $headerData[0].Substring(5, 1)
    $opts.height = [int]$headerData[1]
    $opts.baseline = [int]$headerData[2]
    $opts.maxLength = [int]$headerData[3]
    $opts.oldLayout = if([int]$headerData[4] -eq 0) { -1 } else { [int]$headerData[4] }
    $opts.numCommentLines = [int]$headerData[5]
    $opts.printDirection = if ($headerData.Count -ge 7) { [int]$headerData[6] } else { 0 }
    $opts.fullLayout = if ($headerData.Count -ge 8) { [int]$headerData[7] } else { $null }
    $opts.codeTagCount = if ($headerData.Count -ge 9) { [int]$headerData[8] } else { $null }
    $opts.fittingRules = Get-SmushingRules -oldLayout $opts.oldLayout -fullLayout $opts.fullLayout

    $figFont.options = $opts

    # Error check
    if (
        $opts.hardBlank.Length -ne 1 -or
        -not $opts.height -or
        -not $opts.baseline -or
        -not $opts.maxLength -or
        -not $opts.oldLayout -or
        -not $opts.numCommentLines
    ) {
        throw "FIGlet header contains invalid values."
    }

    # Define required character codes
    $charNums = @(32..126) + @(196, 214, 220, 228, 246, 252, 223)

    # Error check - validate that there are enough lines in the file
    if ($lines.Count -lt ($opts.numCommentLines + $opts.height * $charNums.Count)) {
        throw "FIGlet file is missing data."
    }

    # Parse the font data
    $figFont.comment = ($lines[0..($opts.numCommentLines - 1)] -join "`n")
    $lines = $lines[$opts.numCommentLines..($lines.Count - 1)]
    $figFont.numChars = 0

    while ($lines.Count -gt 0 -and $figFont.numChars -lt $charNums.Count) {
        $cNum = $charNums[$figFont.numChars]
        $figFont[$cNum] = $lines[0..($opts.height - 1)]
        $lines = $lines[$opts.height..($lines.Count - 1)]

        # Remove end sub-chars
        for ($ii = 0; $ii -lt $opts.height; $ii++) {
            if (-not $figFont[$cNum][$ii]) {
                $figFont[$cNum][$ii] = ""
            } else {
                $endChar = [regex]::Escape($figFont[$cNum][$ii].Substring($figFont[$cNum][$ii].Length - 1, 1))
                $figFont[$cNum][$ii] = $figFont[$cNum][$ii] -replace "$endChar+$", ""
            }
        }
        $figFont.numChars++
    }

    # Parse additional characters
    $parseError = $false
    while ($lines.Count -gt 0) {
        $cNum = ($lines[0] -split " ")[0]
        $lines = $lines[1..($lines.Count - 1)]
        if ($cNum -match "^0[xX][0-9a-fA-F]+$") {
            $cNum = [int]::Parse($cNum.Substring(2), [System.Globalization.NumberStyles]::HexNumber)
        } elseif ($cNum -match "^0[0-7]+$") {
            $cNum = [int]::Parse($cNum, [System.Globalization.NumberStyles]::None)
        } elseif ($cNum -match "^[0-9]+$") {
            $cNum = [int]$cNum
        } elseif ($cNum -match "^-0[xX][0-9a-fA-F]+$") {
            $cNum = -[int]::Parse($cNum.Substring(3), [System.Globalization.NumberStyles]::HexNumber)
        } else {
            if ($cNum -eq "") {
                break
            }
            Write-PSFMessage -Level Host -Message "Invalid data: $cNum" -ForegroundColor Red
            $parseError = $true
            break
        }
        $figFont[$cNum] = $lines[0..($opts.height - 1)]
        $lines = $lines[$opts.height..($lines.Count - 1)]

        
        # Remove end sub-chars
        for ($ii = 0; $ii -lt $opts.height; $ii++) {
            if (-not $figFont[$cNum][$ii]) {
                $figFont[$cNum][$ii] = ""
            } else {
                $endChar = [regex]::Escape($figFont[$cNum][$ii].Substring($figFont[$cNum][$ii].Length - 1, 1))
                $figFont[$cNum][$ii] = $figFont[$cNum][$ii] -replace "$endChar+$", ""
            }
        }
        $figFont.numChars++
    }

    # Error check
    if ($parseError) {
        throw "Error parsing data."
    }
    return $figFont
}


<#
    .SYNOPSIS
        Merges assigned options with the default font options for a FIGlet font.
        
    .DESCRIPTION
        This function takes the default font options (`fontOpts`) and merges them with the user-specified options
        (`options`). It overrides the default horizontal and vertical fitting rules if specified, and updates
        additional font properties such as `printDirection`, `showHardBlanks`, `width`, and `whitespaceBreak`.
        
    .PARAMETER fontOpts
        A hashtable containing the default font options, including fitting rules and other font properties.
        
    .PARAMETER options
        A hashtable containing user-specified options to override the default font options. These may include:
        - `horizontalLayout`: Specifies the horizontal layout type.
        - `verticalLayout`: Specifies the vertical layout type.
        - `printDirection`: The direction in which the text is printed.
        - `showHardBlanks`: A flag indicating whether to display hard blanks.
        - `width`: The maximum width of the text.
        - `whitespaceBreak`: A flag indicating whether to break lines at whitespace.
        
    .EXAMPLE
        $fontOpts = @{
        fittingRules = @{
        hLayout = "default"
        vLayout = "default"
        }
        printDirection = 0
        showHardBlanks = $true
        width = 80
        whitespaceBreak = $true
        }
        $options = @{
        horizontalLayout = "fitted"
        verticalLayout = "controlled smushing"
        printDirection = 1
        showHardBlanks = $false
        width = 100
        }
        $mergedOpts = Rework-FontOpts -fontOpts $fontOpts -options $options
        
        This example merges the user-specified options with the default font options and returns the updated options.
        
    .NOTES
        This function relies on the `Get-HorizontalFittingRules` and `Get-VerticalFittingRules` helper functions
        to calculate the fitting rules for the specified layouts.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Rework-FontOpts {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [hashtable]$fontOpts,  # Default font options
        [hashtable]$options    # Assigned options to merge with the defaults
    )

    # Make a copy of the font options
    $myOpts = $fontOpts.PSObject.Copy()

    # If the user specifies a horizontal layout, override the default font options
    if ($options.horizontalLayout) {
        $params = Get-HorizontalFittingRules -layout $options.horizontalLayout -options $fontOpts
        foreach ($prop in $params.Keys) {
            $myOpts.fittingRules[$prop] = $params[$prop]
        }
    }

    # If the user specifies a vertical layout, override the default font options
    if ($options.verticalLayout) {
        $params = Get-VerticalFittingRules -layout $options.verticalLayout -options $fontOpts
        foreach ($prop in $params.Keys) {
            $myOpts.fittingRules[$prop] = $params[$prop]
        }
    }

    # Set printDirection, showHardBlanks, width, and whitespaceBreak
    $myOpts.printDirection = if ($options.printDirection) { $options.printDirection } else { $fontOpts.printDirection }
    $myOpts.showHardBlanks = $options.showHardBlanks -or $false
    $myOpts.width = if ($options.width) { $options.width } else { -1 }
    $myOpts.whitespaceBreak = $options.whitespaceBreak -or $false

    return $myOpts
}


<#
    .SYNOPSIS
        Sets or overrides the default FIGlet font options.
        
    .DESCRIPTION
        This function initializes the global `$Script:FigDefaults` hashtable with default FIGlet font options
        if it is not already defined. It then merges the user-specified options (`$opts`) into the defaults,
        overriding any existing properties. The updated defaults are returned as a copy to prevent unintended
        modifications to the global hashtable.
        
    .PARAMETER opts
        A hashtable containing user-specified properties to override the default FIGlet font options.
        Supported properties include:
        - `font`: The name of the default FIGlet font.
        - `fontPath`: The path to the directory containing FIGlet font files.
        
    .EXAMPLE
        $opts = @{
        font = "Big"
        fontPath = "./custom_fonts"
        }
        $updatedDefaults = Set-Defaults -opts $opts
        
        This example sets the default font to "Big" and updates the font path to "./custom_fonts".
        
    .EXAMPLE
        $updatedDefaults = Set-Defaults -opts @{}
        
        This example returns the current default FIGlet font options without making any changes.
        
    .NOTES
        This function ensures that the global `$Script:FigDefaults` hashtable is always initialized before
        applying any overrides. It returns a copy of the updated defaults to prevent unintended modifications.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Set-Defaults {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    param (
        [hashtable]$opts # Hashtable containing properties to override
    )

    # Ensure $figDefaults is defined globally
    if (-not $Script:FigDefaults) {
        $Script:FigDefaults = @{
            font = "Standard"
            fontPath = "$Script:ModuleRoot\internal\misc\Fonts"
        }
    }

    # Override defaults if $opts is a hashtable and not null
    if ($opts -is [hashtable] -and $opts -ne $null) {
        foreach ($prop in $opts.Keys) {
            $Script:FigDefaults[$prop] = $opts[$prop]
        }
    }

    # Return a copy of the updated $figDefaults
    return $Script:FigDefaults.PSObject.Copy()
}


<#
    .SYNOPSIS
        Combines two sets of FIGlet text lines vertically with optional overlapping smushing.
        
    .DESCRIPTION
        The Smush-VerticalFigLines function takes two sets of FIGlet text lines (`output` and `lines`) and combines
        them vertically. If the lengths of the lines in the two sets differ, the shorter set is padded with spaces
        to match the length of the longer set. The function calculates the vertical smush distance using the provided
        smushing options and applies vertical smushing rules to the overlapping lines. The resulting text is returned
        as a single array of combined lines.
        
    .PARAMETER output
        An array of strings representing the first set of FIGlet text lines.
        
    .PARAMETER lines
        An array of strings representing the second set of FIGlet text lines.
        
    .PARAMETER options
        A hashtable containing options for vertical smushing, including:
        - `fittingRules.vLayout`: Specifies the vertical layout type (e.g., Full, Fitted, ControlledSmushing).
        - Additional smushing rules for evaluating overlaps.
        
    .EXAMPLE
        $output = @(
        "Hello",
        "World"
        )
        $lines = @(
        "Foo",
        "Bar"
        )
        $options = @{
        fittingRules = @{
        vLayout = [LayoutType]::ControlledSmushing
        }
        }
        $result = Smush-VerticalFigLines -output $output -lines $lines -options $options
        
        This example combines two sets of FIGlet text lines using ControlledSmushing rules.
        
    .NOTES
        This function relies on the following helper functions:
        - `Pad-Lines`: Pads the shorter set of lines with spaces to match the length of the longer set.
        - `Get-VerticalSmushDist`: Calculates the vertical smush distance between the two sets of lines.
        - `Vertical-Smush`: Performs the actual vertical smushing of the two sets of lines.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Smush-VerticalFigLines {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string[]]$output,    # First set of lines
        [string[]]$lines,     # Second set of lines
        [hashtable]$options      # Options for smushing
    )

    # Determine the lengths of the first lines in both arrays
    $len1 = $output[0].Length
    $len2 = $lines[0].Length
    $overlap = 0

    # Pad the shorter set of lines to match the length of the longer set
    if ($len1 -gt $len2) {
        $lines = Pad-Lines -lines $lines -numSpaces ($len1 - $len2)
    } elseif ($len2 -gt $len1) {
        $output = Pad-Lines -lines $output -numSpaces ($len2 - $len1)
    }

    # Calculate the vertical smush distance
    $overlap = Get-VerticalSmushDist -lines1 $output -lines2 $lines -opts $options
    $lines1 = $output
    $lines2 = $lines
    # Perform the vertical smush
    return Vertical-Smush -lines1 $lines1 -lines2 $lines2 -overlap $overlap -options $options
}


<#
    .SYNOPSIS
        Generates ASCII art text synchronously using a specified FIGlet font and options.
        
    .DESCRIPTION
        This function converts input text into ASCII art using the specified FIGlet font and rendering options.
        It validates the input, processes the provided options, and generates the ASCII art text by calling
        helper functions to load the font, rework font options, and render the text.
        
    .PARAMETER txt
        The input text to be converted into ASCII art.
        
    .PARAMETER options
        A hashtable containing font and rendering options. Supported properties include:
        - `font`: The name of the FIGlet font to use.
        - Additional font settings such as width, layout, and smushing rules.
        
    .EXAMPLE
        $txt = "Hello, World!"
        $options = @{
        font = "Standard"
        width = 80
        }
        $asciiArt = Text-Sync -txt $txt -options $options
        
        This example generates ASCII art for the text "Hello, World!" using the "Standard" FIGlet font.
        
    .EXAMPLE
        $txt = "Hello, World!"
        $asciiArt = Text-Sync -txt $txt -options "Standard"
        
        This example generates ASCII art for the text "Hello, World!" using the "Standard" FIGlet font by passing the font name directly.
        
    .NOTES
        This function relies on helper functions such as `Rework-FontOpts`, `Load-Font`, and `Generate-Text` to process
        the font and render the ASCII art.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Text-Sync {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$txt,          # Input text
        [hashtable]$options    # Options for font and settings
    )
    
    # Initialize fontName
    $fontName = ""

    # Validate inputs
    $txt = [string]$txt

    # Handle options
    if ($options -is [string]) {
        $fontName = $options
        $options = @{}
    } else {
        $options = if($options){$options}else{@{}}
        $fontName = if ($options.font) { $options.font } else { $Script:FigDefaults.font }
    }
    # Rework font options
    $fontOpts = Rework-FontOpts -fontOpts (Load-Font -fontName "$fontName").options -options $options

    # Generate the ASCII art text
    return Generate-Text -fontName $fontName -options $fontOpts -txt $txt
}


<#
    .SYNOPSIS
        Applies universal smushing by overlapping two characters.
        
    .DESCRIPTION
        This function implements universal smushing, where the earlier character (`ch1`) is overridden by the later
        character (`ch2`) to produce an overlapping effect. If the later character is a space or empty, the earlier
        character is retained. If the later character is a hardblank and the earlier character is not a space, the
        earlier character is retained. Otherwise, the later character is used.
        
    .PARAMETER ch1
        The first character to evaluate for smushing.
        
    .PARAMETER ch2
        The second character to evaluate for smushing.
        
    .PARAMETER hardBlank
        The character used to represent hardblanks in FIGlet fonts.
        
    .EXAMPLE
        $ch1 = "H"
        $ch2 = "e"
        $hardBlank = "@"
        $result = uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example applies universal smushing to the characters "H" and "e", resulting in "e".
        
    .EXAMPLE
        $ch1 = "H"
        $ch2 = " "
        $hardBlank = "@"
        $result = uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example retains the earlier character "H" because the later character is a space.
        
    .EXAMPLE
        $ch1 = "H"
        $ch2 = "@"
        $hardBlank = "@"
        $result = uni-Smush -ch1 $ch1 -ch2 $ch2 -hardBlank $hardBlank
        
        This example retains the earlier character "H" because the later character is a hardblank.
        
    .NOTES
        This function implements universal smushing as defined in FIGlet smushing rules.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function uni-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2,
        [string]$hardBlank
    )
    if ($ch2 -eq " " -or $ch2 -eq "") {
        return $ch1
    } elseif ($ch2 -eq $hardBlank -and $ch1 -ne " ") {
        return $ch1
    } else {
        return $ch2
    }
}


<#
    .SYNOPSIS
        Combines two sets of text lines vertically with optional overlapping smushing.
        
    .DESCRIPTION
        This function takes two sets of text lines (`lines1` and `lines2`) and combines them vertically.
        If an overlap is specified, the function applies vertical smushing rules to the overlapping lines
        using the `Vertically-SmushLines` helper function. The resulting text is returned as a single array
        of combined lines.
        
    .PARAMETER lines1
        An array of strings representing the first set of text lines.
        
    .PARAMETER lines2
        An array of strings representing the second set of text lines.
        
    .PARAMETER overlap
        The number of overlapping lines to smush. If set to 0, no smushing is applied, and the lines are simply concatenated.
        
    .PARAMETER opts
        A hashtable containing options for vertical smushing, including:
        - `fittingRules.vLayout`: Specifies the vertical layout type (e.g., Full, Fitted, ControlledSmushing).
        - Additional smushing rules for evaluating overlaps.
        
    .EXAMPLE
        $lines1 = @(
        "Hello",
        "World"
        )
        $lines2 = @(
        "Foo",
        "Bar"
        )
        $opts = @{
        fittingRules = @{
        vLayout = [LayoutType]::ControlledSmushing
        }
        }
        $result = Vertical-Smush -lines1 $lines1 -lines2 $lines2 -overlap 2 -opts $opts
        
        This example combines two sets of text lines with 2 lines of overlap using ControlledSmushing rules.
        
    .NOTES
        This function relies on the `Vertically-SmushLines` helper function to process overlapping lines
        and applies the specified smushing rules.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Vertical-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string[]]$lines1,  # First set of lines
        [string[]]$lines2,  # Second set of lines
        [int]$overlap,      # Overlap length
        [hashtable]$opts    # Options for smushing
    )

    # Calculate lengths of the input arrays
    $len1 = $lines1.Count
    $len2 = $lines2.Count

    # Split the input arrays into pieces
    $piece1 = $lines1[0..([math]::Max(0, $len1 - $overlap - 1))]
    $piece2_1 = $lines1[([math]::Max(0, $len1 - $overlap -1))..($len1)]
    $piece2_2 = $lines2[0..([math]::Min($overlap, $len2))]

    # Initialize variables
    $piece2 = @()

    # Process the overlapping lines
    $len = $piece2_1.Count
    for ($ii = 1; $ii -lt $len; $ii++) {
        if ($ii -ge $len2) {
            $line = $piece2_1[$ii]
        } else {
            $line = Vertically-SmushLines -line1 $piece2_1[$ii] -line2 $piece2_2[$ii] -opts $opts
        }
        $piece2 += $line
    }

    # Get the remaining lines from lines2
    $piece3 = $lines2[([math]::Min($overlap, $len2))..($len2 - 1)]

    # Concatenate all pieces and return the result
    return $piece1 + $piece2 + $piece3
}


<#
    .SYNOPSIS
        Smushes two lines of text vertically based on specified smushing rules.
        
    .DESCRIPTION
        This function takes two lines of text (`line1` and `line2`) and combines them vertically by applying
        vertical smushing rules. The smushing behavior is determined by the `vLayout` and individual smushing
        rules (`vRule1` to `vRule5`) provided in the `opts` parameter. If no valid smushing rule applies, the
        characters from both lines are retained as-is.
        
    .PARAMETER line1
        The first line of text to smush.
        
    .PARAMETER line2
        The second line of text to smush.
        
    .PARAMETER opts
        A hashtable containing smushing options, including:
        - `fittingRules.vLayout`: Specifies the vertical layout type (e.g., Fitted, UniversalSmushing).
        - `fittingRules.vRule1` to `vRule5`: Boolean flags indicating which smushing rules to apply.
        
    .EXAMPLE
        $line1 = "Hello"
        $line2 = "World"
        $opts = @{
        fittingRules = @{
        vLayout = [LayoutType]::UniversalSmushing
        vRule1 = $true
        vRule2 = $false
        vRule3 = $true
        vRule4 = $false
        vRule5 = $true
        }
        }
        $result = Vertically-SmushLines -line1 $line1 -line2 $line2 -opts $opts
        
        This example smushes the lines "Hello" and "World" using UniversalSmushing and the specified smushing rules.
        
    .NOTES
        This function relies on helper functions (`Uni-Smush`, `vRule1-Smush`, `vRule2-Smush`, `vRule3-Smush`, `vRule4-Smush`, and `vRule5-Smush`)
        to evaluate individual character pairs for smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Vertically-SmushLines {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [string]$line1,  # First line of text
        [string]$line2,  # Second line of text
        [hashtable]$opts # FIGlet options
    )

    # Determine the minimum length of the two lines
    $len = [math]::Min($line1.Length, $line2.Length)
    $result = ""

    # Iterate through each character in the lines
    for ($ii = 0; $ii -lt $len; $ii++) {
        $ch1 = $line1.Substring($ii, 1)
        $ch2 = $line2.Substring($ii, 1)

        if ($ch1 -ne " " -and $ch2 -ne " ") {
            if ($opts.fittingRules.vLayout -eq [LayoutType]::Fitted) {
                $result += Uni-Smush -ch1 $ch1 -ch2 $ch2
            } elseif ($opts.fittingRules.vLayout -eq [LayoutType]::UniversalSmushing) {
                $result += Uni-Smush -ch1 $ch1 -ch2 $ch2
            } else {
                $validSmush = $false
                if ($opts.fittingRules.vRule5) {
                    $validSmush = vRule5-Smush -ch1 $ch1 -ch2 $ch2
                }
                if (-not $validSmush -and $opts.fittingRules.vRule1) {
                    $validSmush = vRule1-Smush -ch1 $ch1 -ch2 $ch2
                }
                if (-not $validSmush -and $opts.fittingRules.vRule2) {
                    $validSmush = vRule2-Smush -ch1 $ch1 -ch2 $ch2
                }
                if (-not $validSmush -and $opts.fittingRules.vRule3) {
                    $validSmush = vRule3-Smush -ch1 $ch1 -ch2 $ch2
                }
                if (-not $validSmush -and $opts.fittingRules.vRule4) {
                    $validSmush = vRule4-Smush -ch1 $ch1 -ch2 $ch2
                }
                if ($validSmush) {
                    $result += $validSmush
                } else {
                    # If no smushing rule applies, append both characters
                    $result += $ch1 + $ch2
                }
            }
        } else {
            # If one of the characters is a space, use universal smushing
            $result += Uni-Smush -ch1 $ch1 -ch2 $ch2
        }
    }

    return $result
}


<#
    .SYNOPSIS
        Applies Rule 1: Equal Character Smushing for vertical smushing.
        
    .DESCRIPTION
        This function smushes two characters vertically if they are identical. Rule 1, known as "Equal Character Smushing,"
        ensures that identical characters are combined into one. If the characters are not the same, the function returns `$false`.
        
    .PARAMETER ch1
        The first character to evaluate for vertical smushing.
        
    .PARAMETER ch2
        The second character to evaluate for vertical smushing.
        
    .EXAMPLE
        $ch1 = "H"
        $ch2 = "H"
        $result = vRule1-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters "H" and "H" into a single "H".
        
    .EXAMPLE
        $ch1 = "H"
        $ch2 = "e"
        $result = vRule1-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters "H" and "e" and returns `$false`.
        
    .NOTES
        This function implements Rule 1 of the FIGlet vertical smushing rules: Equal Character Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function vRule1-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    if ($ch1 -eq $ch2) {
        return $ch1
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 2: Underscore Smushing for vertical smushing.
        
    .DESCRIPTION
        This function smushes an underscore (`_`) with specific characters (`|`, `/`, `\`, `[`, `]`, `{`, `}`, `(`, `)`, `<`, `>`)
        according to Rule 2 of the FIGlet vertical smushing rules. If one of the characters is an underscore and the other
        is in the allowed set, the underscore is replaced by the other character.
        
    .PARAMETER ch1
        The first character to evaluate for vertical smushing.
        
    .PARAMETER ch2
        The second character to evaluate for vertical smushing.
        
    .EXAMPLE
        $ch1 = "_"
        $ch2 = "|"
        $result = vRule2-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the underscore (`_`) with the pipe (`|`) and returns `|`.
        
    .EXAMPLE
        $ch1 = "/"
        $ch2 = "_"
        $result = vRule2-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the underscore (`_`) with the forward slash (`/`) and returns `/`.
        
    .EXAMPLE
        $ch1 = "_"
        $ch2 = "A"
        $result = vRule2-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the underscore (`_`) with the character `A` and returns `$false`.
        
    .NOTES
        This function implements Rule 2 of the FIGlet vertical smushing rules: Underscore Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function vRule2-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    $rule2Str = "|/\[]{}()<>"
    if ($ch1 -eq "_") {
        if ($rule2Str.Contains($ch2)) {
            return $ch2
        }
    } elseif ($ch2 -eq "_") {
        if ($rule2Str.Contains($ch1)) {
            return $ch1
        }
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 3: Hierarchy Smushing for vertical smushing.
        
    .DESCRIPTION
        This function smushes two characters vertically based on their hierarchy class according to Rule 3 of the FIGlet
        vertical smushing rules. A hierarchy of classes is defined: `|`, `/`, `\`, `[`, `]`, `{`, `}`, `(`, `)`, `<`, `>`.
        When two smushing characters belong to different classes, the character from the latter class in the hierarchy
        is used. If the characters belong to the same class, the function returns `$false`.
        
    .PARAMETER ch1
        The first character to evaluate for vertical smushing.
        
    .PARAMETER ch2
        The second character to evaluate for vertical smushing.
        
    .EXAMPLE
        $ch1 = "|"
        $ch2 = ">"
        $result = vRule3-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters "|" and ">" and returns ">".
        
    .EXAMPLE
        $ch1 = "("
        $ch2 = "["
        $result = vRule3-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters "(" and "[" and returns "[".
        
    .EXAMPLE
        $ch1 = "|"
        $ch2 = "|"
        $result = vRule3-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters "|" and "|" because they belong to the same class and returns `$false`.
        
    .NOTES
        This function implements Rule 3 of the FIGlet vertical smushing rules: Hierarchy Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function vRule3-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    # Define the hierarchy classes explicitly
    $rule3Classes = @("|", "/", "\", "[", "]", "{", "}", "(", ")", "<", ">")
    # Get the indices of the characters in the hierarchy
    $r3_pos1 = $rule3Classes.IndexOf($ch1)
    $r3_pos2 = $rule3Classes.IndexOf($ch2)

    # Ensure both characters are in the hierarchy
    if ($r3_pos1 -ne -1 -and $r3_pos2 -ne -1) {
        # Return $false if both characters are the same
        if ($r3_pos1 -eq $r3_pos2) {
            return $false
        }
        # Return the character from the latter class
        return $rule3Classes[[math]::Max($r3_pos1, $r3_pos2)]
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 4: Horizontal Line Smushing for vertical smushing.
        
    .DESCRIPTION
        This function smushes stacked pairs of `"-"` and `"_"` characters into a single `"="` sub-character
        according to Rule 4 of the FIGlet vertical smushing rules. The order of the characters does not matter;
        if one character is `"-"` and the other is `"_"`, they are replaced with `"="`. If the characters do not
        match this rule, the function returns `$false`.
        
    .PARAMETER ch1
        The first character to evaluate for vertical smushing.
        
    .PARAMETER ch2
        The second character to evaluate for vertical smushing.
        
    .EXAMPLE
        $ch1 = "-"
        $ch2 = "_"
        $result = vRule4-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `"-"` and `"_"` into `"="`.
        
    .EXAMPLE
        $ch1 = "_"
        $ch2 = "-"
        $result = vRule4-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `"_"` and `"-"` into `"="`.
        
    .EXAMPLE
        $ch1 = "-"
        $ch2 = "|"
        $result = vRule4-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters `"-"` and `"|"` and returns `$false`.
        
    .NOTES
        This function implements Rule 4 of the FIGlet vertical smushing rules: Horizontal Line Smushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function vRule4-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    if (($ch1 -eq "-" -and $ch2 -eq "_") -or ($ch1 -eq "_" -and $ch2 -eq "-")) {
        return "="
    }
    return $false
}


<#
    .SYNOPSIS
        Applies Rule 5: Vertical Line Supersmushing.
        
    .DESCRIPTION
        This function smushes stacked vertical bars (`|`) into a single vertical bar according to Rule 5 of the
        FIGlet vertical smushing rules. If both characters are vertical bars, they are replaced with a single
        vertical bar. If the characters do not match this rule, the function returns `$false`.
        
    .PARAMETER ch1
        The first character to evaluate for vertical smushing.
        
    .PARAMETER ch2
        The second character to evaluate for vertical smushing.
        
    .EXAMPLE
        $ch1 = "|"
        $ch2 = "|"
        $result = vRule5-Smush -ch1 $ch1 -ch2 $ch2
        
        This example smushes the characters `|` and `|` into a single `|`.
        
    .EXAMPLE
        $ch1 = "|"
        $ch2 = "-"
        $result = vRule5-Smush -ch1 $ch1 -ch2 $ch2
        
        This example does not smush the characters `|` and `-` and returns `$false`.
        
    .NOTES
        This function implements Rule 5 of the FIGlet vertical smushing rules: Vertical Line Supersmushing.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function vRule5-Smush {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    param (
        [string]$ch1,
        [string]$ch2
    )
    if ($ch1 -eq "|" -and $ch2 -eq "|") {
        return "|"
    }
    return $false
}


<#
    .SYNOPSIS
        Converts a given text into ASCII art using a specified font and customizable options.
        
    .DESCRIPTION
        The Convert-FSCPSTextToAscii function generates ASCII art from the provided text using the specified font.
        It supports optional customization, including border styles, text and border colors, layout types, and additional
        formatting options such as showing hard blanks or breaking lines at whitespace. The function is highly configurable
        and can be used to create visually appealing text banners or decorations for console outputs.
        
        The function also supports outputting the ASCII art with or without color to custom variables, allowing for
        further processing or storage of the generated ASCII art.
        
    .PARAMETER Text
        The text to be converted into ASCII art. This parameter is mandatory.
        
    .PARAMETER Font
        The font to be used for generating the ASCII art. This parameter is mandatory.
        
    .PARAMETER BorderType
        The type of border to apply around the ASCII art. Defaults to `None`.
        
    .PARAMETER TextColor
        The color to use for the ASCII art text. Defaults to `White`.
        
    .PARAMETER BorderColor
        The color to use for the border. Defaults to `Gray`.
        
    .PARAMETER Timestamp
        A switch to include a timestamp in the output. Defaults to `$false`.
        
    .PARAMETER VerticalLayout
        Specifies the vertical layout type for the ASCII art. Defaults to `Default`.
        
    .PARAMETER HorizontalLayout
        Specifies the horizontal layout type for the ASCII art. Defaults to `Default`.
        
    .PARAMETER ShowHardBlanks
        A switch to display hard blanks in the ASCII art. Defaults to `$false`.
        
    .PARAMETER WhitespaceBreak
        A switch to enable breaking lines at whitespace. Defaults to `$false`.
        
    .PARAMETER ScreenWigth
        The maximum width of the screen for rendering the ASCII art. Defaults to `100`.
        
    .PARAMETER Padding
        The padding to apply to the ASCII art. Defaults to `0`.
        
    .PARAMETER PrintDirection
        A switch to specify the print direction of the ASCII art. Defaults to left-to-right.
        
    .PARAMETER OutputColorVariable
        The name of the variable to store the ASCII art with color formatting.
        
    .PARAMETER OutputNoColorVariable
        The name of the variable to store the ASCII art without color formatting.
        
    .EXAMPLE
        PS C:\> Convert-FSCPSTextToAscii -Text "Hello, World!" -Font "Standard" -BorderType Box -TextColor Yellow -BorderColor Blue -Timestamp
        
        Converts the text "Hello, World!" into ASCII art using the "Standard" font, applies a box border, and uses yellow text with a blue border. A timestamp is included in the output.
        
    .EXAMPLE
        PS C:\> Convert-FSCPSTextToAscii -Text "PowerShell" -Font "Big" -BorderType Asterisk -TextColor Cyan -BorderColor Green -OutputColorVariable "ColoredOutput" -OutputNoColorVariable "PlainOutput"
        
        Converts the text "PowerShell" into ASCII art using the "Big" font, applies an asterisk border, and uses cyan text with a green border. The colored and plain outputs are stored in the variables `ColoredOutput` and `PlainOutput`, respectively.
        
    .NOTES
        This function uses the PSFramework module for logging and configuration management. Ensure the PSFramework module
        is installed and imported before using this function.
        
        Author: Oleksandr Nikolaiev (@onikolaiev)
#>
function Convert-FSCPSTextToAscii {
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter(Mandatory=$true)]
        [string]$Font,
    
        [Parameter(Mandatory=$false)]
        [BorderType]$BorderType = [BorderType]::None,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        [string]$TextColor = "White",

        [Parameter(Mandatory=$false)]
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        [string]$BorderColor = "Gray",

        [Parameter(Mandatory=$false)]
        [switch]$Timestamp,

        [Parameter(Mandatory=$false)]
        [LayoutType]$VerticalLayout = [LayoutType]::Default,

        [Parameter(Mandatory=$false)]
        [LayoutType]$HorizontalLayout = [LayoutType]::Default,

        [Parameter(Mandatory=$false)]
        [switch]$ShowHardBlanks,

        [Parameter(Mandatory=$false)]
        [switch]$WhitespaceBreak,

        [Parameter(Mandatory=$false)]
        [int]$ScreenWigth = 100,

        [Parameter(Mandatory=$false)]
        [int]$Padding = 0,

        [Parameter(Mandatory=$false)]
        [switch]$PrintDirection,

        [Parameter(Mandatory=$false)]
        [string]$OutputColorVariable,

        [Parameter(Mandatory=$false)]
        [string]$OutputNoColorVariable

    )
    begin {
        Invoke-TimeSignal -Start
        # Save the current state of the PSFramework message style settings
        $originalTimestampSetting = (Get-PSFConfig -Module PSFramework -Name 'Message.Style.Timestamp').Value        
        $originalFunctionNameSetting = (Get-PSFConfig -Module PSFramework -Name 'Message.Style.FunctionName').Value

        # Apply the detailed info setting
        if ($Timestamp) {
            Set-PSFConfig -Module PSFramework -Name 'Message.Style.Timestamp' -Value $true
            Set-PSFConfig -Module PSFramework -Name 'Message.Style.FunctionName' -Value $false
        } else {
            Set-PSFConfig -Module PSFramework -Name 'Message.Style.Timestamp' -Value $false
            Set-PSFConfig -Module PSFramework -Name 'Message.Style.FunctionName' -Value $false
        }

        $border = Get-BorderSymbol -BorderType $BorderType

        $_printDirection = 0

        if($PrintDirection) {
            $_printDirection = 1
        }

    }
    PROCESS {

        $options = @{
            font ="$Font"
            showHardBlanks = $ShowHardBlanks
            whitespaceBreak = $WhitespaceBreak
            verticalLayout = $VerticalLayout
            horizontalLayout = $HorizontalLayout
            width = $ScreenWigth
            printDirection = $_printDirection
        }
        # Call the function
        $outputLines = New-Object System.Collections.Generic.List[string]
        $resultColorLines = New-Object System.Collections.Generic.List[string]
        $resultNoColorLines = New-Object System.Collections.Generic.List[string]
        $null = (Get-FontMetadata -fontName $Font) 
        $arrayLines = (Text-Sync -txt $Text -options $options)
        foreach ($line in $arrayLines -split "`n") {
                $outputLines.Add(((' ' * $Padding) + $line + (' ' * $Padding)))
        }
        $outputLines = $outputLines -split "`n"

        # Determine max line length
        $maxLen = ($outputLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
        # Calculate the total width of the content including side borders
        $totalWidth = $maxLen
        if ($BorderType -ne [BorderType]::None) {
            # Repeat spacer patterns to match the required total width
            $topBorder = $border.TopSpacer * ([math]::Ceiling($totalWidth / $border.TopSpacer.Length))
            $topBorder = $topBorder.Substring(0, $topBorder.Length)  # Trim to exact length
            
            $bottomBorder = $border.BottomSpacer * [math]::Ceiling($totalWidth / $border.BottomSpacer.Length)
            $bottomBorder = $bottomBorder.Substring(0, $bottomBorder.Length)  # Trim to exact length
            
            # Draw top border
            $topBorderLine = $border.TopLeft + $topBorder + $border.TopRight
            $topBorderMessageColor = ('<c="'+$BorderColor.ToLower()+'">' + $topBorderLine + "</c>")
            $topBorderMessageNoColor = ($topBorderLine)
            $resultColorLines.Add($topBorderMessageColor)
            $resultNoColorLines.Add($topBorderMessageNoColor)
            Write-PSFMessage -Level Important -Message $topBorderMessageColor
            # Draw lines, padding each to the max length
            foreach ($line in $outputLines) {
                $curLineLength = $line.Length + $border.LeftSpacer.Length + $border.RightSpacer.Length 
                $curAdvDifference = ($topBorderLine.Length - ($curLineLength))
                $padded = $line.PadRight($line.Length + $curAdvDifference)
                $centerMessageColor = ('<c="'+$BorderColor.ToLower()+'">' + $border.LeftSpacer + "</c>" + '<c="'+$TextColor.ToLower()+'">' + $padded +"</c>" + '<c="'+$BorderColor.ToLower()+'">' + $border.RightSpacer + "</c>")
                $centerMessageNoColor = ($border.LeftSpacer + $padded + $border.RightSpacer)
                $resultColorLines.Add($centerMessageColor)
                $resultNoColorLines.Add($centerMessageNoColor)
                Write-PSFMessage -Level Important -Message $centerMessageColor
            }
            
            # Draw bottom border
            $bottomBorderMessageColor = ('<c="'+$BorderColor.ToLower()+'">' + $border.BottomLeft + $bottomBorder + $border.BottomRight  + "</c>")
            $bottomBorderMessageNoColor = ($border.BottomLeft + $bottomBorder + $border.BottomRight)
            $resultColorLines.Add($bottomBorderMessageColor)
            $resultNoColorLines.Add($bottomBorderMessageNoColor)
            Write-PSFMessage -Level Host -Message $bottomBorderMessageColor
        }
        else {
            # Draw lines without borders
            foreach ($line in $outputLines) {
                Write-PSFMessage -Level Host -Message  (('<c="'+$TextColor.ToLower()+'">' + $line + "</c>"))
            }
        }    
        # If the custom output variable is provided, set its value
        if ($PSBoundParameters.ContainsKey('OutputNoColorVariable') -and $OutputNoColorVariable) {
            Set-Variable -Name $OutputNoColorVariable -Value $resultNoColorLines -Scope 1
        }
        if ($PSBoundParameters.ContainsKey('OutputColorVariable') -and $OutputColorVariable) {
            Set-Variable -Name $OutputColorVariable -Value $resultColorLines -Scope 1
        }
    }
    END {
        # Restore the original state of the PSFramework message style settings
        Set-PSFConfig -Module PSFramework -Name 'Message.Style.Timestamp' -Value $originalTimestampSetting
        Set-PSFConfig -Module PSFramework -Name 'Message.Style.FunctionName' -Value $originalFunctionNameSetting
        Invoke-TimeSignal -End
    }    
}

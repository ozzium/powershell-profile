#Region '.\_PrefixCode.ps1' 0
# Code in here will be prepended to top of the psm1-file.
#EndRegion '.\_PrefixCode.ps1' 2
#Region '.\Public\ConvertTo-AsciiArt.ps1' 0
Function ConvertTo-AsciiArt {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ImagePath,
        [Parameter(Mandatory=$false)]
        [int]$Width = 80,
        [Parameter(Mandatory=$false)]
        [int]$Height = 160
    )

    # Load the System.Drawing namespace
    Add-Type -AssemblyName System.Drawing

    # Load the image file
    $image = [System.Drawing.Image]::FromFile($ImagePath)

    # Set the width and height of the ASCII art
    $width = $Width
    $height = $Height

    # Resize the image to fit the console
    $aspectRatio = $image.Width / $image.Height
    $newWidth = $height * $aspectRatio
    $newHeight = $width / $aspectRatio
    if ($newWidth -gt $width) {
        $consoleWidth = $width
        $consoleHeight = $newHeight
    } else {
        $consoleWidth = $newWidth
        $consoleHeight = $height
    }
    $image = $image.GetThumbnailImage($consoleWidth, $consoleHeight, $null, [IntPtr]::Zero)

    # Convert the image to ASCII art
    $ascii = ""
    for ($y = 0; $y -lt $image.Height; $y++) {
        for ($x = 0; $x -lt $image.Width; $x++) {
            $pixel = [System.Drawing.Color]$image.GetPixel($x, $y)
            $brightness = ($pixel.R + $pixel.G + $pixel.B) / 3
            if ($brightness -ge 230) {
                $ascii += " "
            } elseif ($brightness -ge 200) {
                $ascii += "."
            } elseif ($brightness -ge 180) {
                $ascii += ":"
            } elseif ($brightness -ge 160) {
                $ascii += "-"
            } elseif ($brightness -ge 130) {
                $ascii += "="
            } elseif ($brightness -ge 100) {
                $ascii += "+"
            } elseif ($brightness -ge 70) {
                $ascii += "*"
            } elseif ($brightness -ge 50) {
                $ascii += "#"
            } elseif ($brightness -ge 30) {
                $ascii += "%"
            } else {
                $ascii += "@"
            }
        }
        $ascii += "`n"
    }

    # Output the ASCII art to the console
    Write-Host $ascii
}
#EndRegion '.\Public\ConvertTo-AsciiArt.ps1' 69
#Region '.\Public\ConvertTo-AsciiArtColor.ps1' 0
Function ConvertTo-AsciiArtColor {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ImagePath,
        [Parameter(Mandatory=$false)]
        [int]$Width = 80,
        [Parameter(Mandatory=$false)]
        [int]$Height = 160
    )

    # Load the System.Drawing namespace
    Add-Type -AssemblyName System.Drawing

    # Load the image file
    $image = [System.Drawing.Image]::FromFile($ImagePath)

    # Set the width and height of the ASCII art
    $width = $Width
    $height = $Height

    # Resize the image to fit the console
    $aspectRatio = $image.Width / $image.Height
    $newWidth = $height * $aspectRatio
    $newHeight = $width / $aspectRatio
    if ($newWidth -gt $width) {
        $consoleWidth = $width
        $consoleHeight = $newHeight
    } else {
        $consoleWidth = $newWidth
        $consoleHeight = $height
    }
    $image = $image.GetThumbnailImage($consoleWidth, $consoleHeight, $null, [IntPtr]::Zero)

    # Convert the image to ASCII art
    for ($y = 0; $y -lt $image.Height; $y++) {
        $line = ""
        for ($x = 0; $x -lt $image.Width; $x++) {
            $pixel = [System.Drawing.Color]$image.GetPixel($x, $y)
            $brightness = ($pixel.R + $pixel.G + $pixel.B) / 3
            if ($brightness -ge 230) {
                $line += " "
            } elseif ($brightness -ge 200) {
                $line += "."
            } elseif ($brightness -ge 180) {
                $line += ":"
            } elseif ($brightness -ge 160) {
                $line += "-"
            } elseif ($brightness -ge 130) {
                $line += "="
            } elseif ($brightness -ge 100) {
                $line += "+"
            } elseif ($brightness -ge 70) {
                $line += "*"
            } elseif ($brightness -ge 50) {
                $line += "#"
            } elseif ($brightness -ge 30) {
                $line += "%"
            } else {
                $line += "@"
            }

            # Set the foreground color based on the pixel color
            $color = [System.ConsoleColor]::Black
            if ($pixel.R -ge 128) { $color += 1 }
            if ($pixel.G -ge 128) { $color += 2 }
            if ($pixel.B -ge 128) { $color += 4 }
            Write-Host -NoNewline $line[-1] -ForegroundColor $color
        }
        Write-Host ""
    }
}
#EndRegion '.\Public\ConvertTo-AsciiArtColor.ps1' 73

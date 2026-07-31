<#
.Synopsis
    Shuffles frames in video
.Description
    Shuffles frames in a video stream.
#>
# It's an extension
[Runtime.CompilerServices.Extension()]
# that extends Edit-Media            
[Management.Automation.Cmdlet("Edit","Media")]
# that is not inherited
[ComponentModel.Inheritance("Inherited")]
param(
# Set the destination indexes of input frames. 
# Number of indexes also sets maximal value that each index may have.
# ’-1’ index have special meaning and that is to drop frame.
[Parameter(Mandatory)]
[Alias('ShufflePixels')]
[switch]
$ShufflePixel,

[ValidateSet('forward','inverse')]
[string]
$ShufflePixelDirection,

[ValidateSet('horizontal','vertical','block')]
[string]
$ShufflePixelMode,

[int]
$ShufflePixelWidth,

[int]
$ShufflePixelHeight,

[int]
$ShufflePixelSeed
)

$filterArgs = @(
    if ($ShufflePixelDirection) {
        "direction=$($ShufflePixelDirection.ToLower())"
    }
    if ($ShufflePixelMode) {
        "mode=$($ShufflePixelMode.ToLower())"
    }
    if ($ShufflePixelWidth) {
        "width=$ShufflePixelWidth"
    }
    if ($ShufflePixelHeight) {
        "height=$ShufflePixelHeight"
    }
    if ($ShufflePixelSeed) {
        "seed=$ShufflePixelSeed"
    }
) -join ':'
"-vf"
"shufflepixels=$filterArgs"



<#
.Synopsis
    Shuffles planes in video
.Description
    Shuffles planes in a video stream.

    A plane is essentially a color channel in a video frame.

    For example, a video frame may have a red, green, blue, and alpha channel.
#>
# It's an extension
[Runtime.CompilerServices.Extension()]
# that extends Edit-Media            
[Management.Automation.Cmdlet("Edit","Media")]
# that is not inherited
[ComponentModel.Inheritance("Inherited")]
param(
# If set, will shuffle planes
[Parameter(Mandatory)]
[Alias('ShufflePlanes')]
[switch]
$ShufflePlane,

# The shuffle map.
# This is an array of integers that represent the destination indexes of input planes.
[int[]]
$ShuffePlaneMap
)

"-vf"
if (-not $ShuffePlaneMap) {
    $ShuffePlaneMap = 0..3 | Get-Random -Count 4
}
"shuffleplanes=$($ShuffePlaneMap -join ':')"



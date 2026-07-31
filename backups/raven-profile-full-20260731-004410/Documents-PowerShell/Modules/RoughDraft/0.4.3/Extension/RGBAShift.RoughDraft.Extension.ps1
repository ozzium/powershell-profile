<#
.SYNOPSIS
    RGBAShift
.DESCRIPTION
    Shift R/G/B/A pixels horizontally and/or vertically.
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#rgbashift
.EXAMPLE
    $TriangleRGBAShift = @{
        RGBAShift = $true
        RGBAShiftRedHorizontal=-10
        RGBAShiftRedVertical=10
        RGBAShiftGreenHorizontal= 10
        RGBAShiftGreenVertical= -10        
        RGBAShiftBlueVertical=10
    }
    Show-Media -InputPath ./a.mp4 @TriangleRGBAShift
#>
[Management.Automation.Cmdlet('(?>Edit|Show)', 'Media')]
param(
# If set, will use the rgbashift filter
[Parameter(Mandatory)]
[switch]
$RGBAShift,

# The amount to shift pixel red horizontally
[Alias('rgbashift_rh')]
[string]
$RGBAShiftRedHorizontal,

# The amount to shift pixel red vertically
[Alias('rgbashift_rv')]
[string]
$RGBAShiftRedVertical,

# The amount to shift pixel green horizontally
[Alias('rgbashift_gh')]
[string]
$RGBAShiftGreenHorizontal,

# The amount to shift pixel green vertically
[Alias('rgbashift_gv')]
[string]
$RGBAShiftGreenVertical,

# The amount to shift pixel blue horizontally
[Alias('rgbashift_bh')]
[string]
$RGBAShiftBlueHorizontal,

# The amount to shift pixel blue vertically
[Alias('rgbashift_bv')]
[string]
$RGBAShiftBlueVertical,

# The amount to shift pixel alpha horizontally
[Alias('rgbashift_ah')]
[string]
$RGBAShiftAlphaHorizontal,

# The amount to shift pixel alpha vertically
[Alias('rgbashift_av')]
[string]
$RGBAShiftAlphaVertical
)

$filterName = 'rgbashift'
$filterArgs = @(
    if ($RGBAShiftRedHorizontal) {"rh=$RGBAShiftRedHorizontal"}
    if ($RGBAShiftRedVertical) {"rv=$RGBAShiftRedVertical"}
    if ($RGBAShiftGreenHorizontal) {"gh=$RGBAShiftGreenHorizontal"}
    if ($RGBAShiftGreenVertical) {"gv=$RGBAShiftGreenVertical"}
    if ($RGBAShiftBlueHorizontal) {"bh=$RGBAShiftBlueHorizontal"}
    if ($RGBAShiftBlueVertical) {"bv=$RGBAShiftBlueVertical"}
    if ($RGBAShiftAlphaHorizontal) {"ah=$RGBAShiftAlphaHorizontal"}
    if ($RGBAShiftAlphaVertical) {"av=$RGBAShiftAlphaVertical"}
) -join ':'
'-vf'
"$filterName=$filterArgs" -replace "=$"

<#
.SYNOPSIS
    XBR effect
.DESCRIPTION
    Apply the xBR high-quality magnification filter which is designed for pixel art.
    
    It follows a set of edge-detection rules, see https://forums.libretro.com/t/xbr-algorithm-tutorial/123.
.NOTES
    This filter can help smooth the look of pixelart.
    
    It can be combined with the Pixelate effect to provide smoother pixelation within a video, 
    or used on its own to provide _very_ slight pixelation effects.
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#xbr
#>
[Runtime.CompilerServices.Extension()]          # It's an extension
[Management.Automation.Cmdlet("Edit","Media")]  # that extends Edit-Media
param(
# If set, will pixelate a video using xbr.  Values range from 2 to 4.
# The lower the value, the less pixelation blur will be present.
[Parameter(Mandatory)]
[ValidateRange(2,4)]
[int]
$XBR
)

"-vf"
"xbr=n=$xbr"
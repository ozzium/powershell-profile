<#
.SYNOPSIS
    Selective Color Extension
.DESCRIPTION
    Adjust cyan, magenta, yellow and black (CMYK) to certain ranges of colors
    (such as "reds", "yellows", "greens", "cyans", ...). 
    
    The adjustment range is defined by the "purity" of the color 
    (that is, how saturated it already is).

    This filter is similar to the Adobe Photoshop Selective Color tool.
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#selectivecolor
#>

[Management.Automation.Cmdlet("Edit","Media")]
[Management.Automation.Cmdlet("Show","Media")]
param(
# If set, will use the selective color filter
[Parameter(Mandatory)]
[Alias('SelectiveColour')]
[switch]
$SelectiveColor,

# The Select color correction method.
# Can be absolute or relative.
[Alias(
    'SelectiveColourCorrectionMethod',
    'selectivecolor_correction_method'
)]
[ValidateSet('absolute', 'relative')]
[string]
$SelectiveColorCorrectionMethod,

# Adjustments for red pixels (pixels where the red component is the maximum)
[Alias(
    'SelectiveColourRed','SelectiveColourReds',
    'selectivecolor_reds','SelectiveColorReds'
)]
[string]
$SelectiveColorRed,

# Adjustments for blue pixels (pixels where the blue component is the maximum)
[Alias(
    'SelectiveColourBlue','SelectiveColourBlues',
    'selectivecolor_Blues','SelectiveColorBlues'
)]
[string]
$SelectiveColorBlue,

# Adjustments for yellow pixels (pixels where the yellow component is the maximum)
[Alias(
    'SelectiveColourYellow','SelectiveColourYellows',
    'selectivecolor_yellows','SelectiveColorYellows'
)]
[string]
$SelectiveColorYellow,

# Adjustments for cyan pixels (pixels where the cyan component is the maximum)
[Alias(
    'SelectiveColourCyan','SelectiveColourCyans',
    'selectivecolor_cyans','SelectiveColorCyans'
)]
[string]
$SelectiveColorCyan,

# Adjustments for magenta pixels (pixels where the magenta component is the maximum)
[Alias(
    'SelectiveColourMagenta','SelectiveColourMagentas',
    'selectivecolor_magentas','SelectiveColorMagentas'
)]
[string]
$SelectiveColorMagenta,

# Adjustments for white pixels (pixels where all components are greater than 128)
[Alias(
    'SelectiveColourWhite','SelectiveColourWhites',
    'selectivecolor_whites','SelectiveColorWhites'
)]
[string]
$SelectiveColorWhite,

# Adjustments for black pixels (pixels where all components are lesser than 128)
[Alias(
    'SelectiveColourBlack','SelectiveColourBlacks',
    'selectivecolor_blacks','SelectiveColorBlacks'
)]
[string]
$SelectiveColorBlack,

# Adjustments for all pixels except pure black and pure white
[Alias(
    'SelectiveColourNeutral','SelectiveColourNeutrals',
    'selectivecolor_neutrals','SelectiveColorNeutrals'
)]
[string]
$SelectiveColorNeutral,

# Specify a Photoshop selective color file (.asv) to import the settings from.
[Alias(
    'SelectiveColourPSFile','SelectiveColourPhotoshopFile',
    'selectivecolor_psfile','SelectiveColorPhotoshopFile'
)]
[string]
$SelectiveColorPSFile
)

# Collect our filter arguments
$filterArgs  = @(
    if ($SelectiveColorRed) {"reds='$SelectiveColorRed'"}
    if ($SelectiveColorYellow) {"yellows='$SelectiveColorYellow'"}
    if ($SelectiveColorCyan) {"cyans='$SelectiveColorCyan'"}
    if ($SelectiveColorMagenta) {"magentas='$SelectiveColorMagenta'"}
    if ($SelectiveColorBlue) {"blues='$SelectiveColorBlue'"}
    if ($SelectiveColorWhite) { "whites='$SelectiveColorWhite'"}
    if ($SelectiveColorBlack) { "blacks='$SelectiveColorBlack'"}
    if ($SelectiveColorNeutral) { "neutrals='$SelectiveColorNeutrals'"}    
    if ($SelectiveColorPhotoshop) {
        "psfile='$SelectiveColorPhotoshop'"
    }    
    if ($SelectiveColorCorrectionMethod) {
        "correction_method=$($SelectiveColorCorrectionMethod.ToLower())"
    }
 ) -join ':'
"-vf"
"selectivecolor=$filterArgs" -replace '=$'
<#
.SYNOPSIS
    ColorCurve Extension
.DESCRIPTION
    Apply color adjustments using curves.

    This filter is similar to the Adobe Photoshop and GIMP curves tools.
    Each component (red, green and blue) has its values defined by 
    N key points tied from each other using a smooth curve.
    
    The x-axis represents the pixel values from the input frame,
    and the y-axis the new pixel values to be set for the output frame.

    By default, a component curve is defined by the two points (0;0) and (1;1).
    This creates a straight line where each original pixel value is "adjusted" to its own value, 
    which means no change to the image.

    The filter allows you to redefine these two points and add some more. 
    A new curve will be defined to pass smoothly through all these new coordinates.
    
    The new defined points need to be strictly increasing over the x-axis, and their x and y values must be in the [0;1] interval.
    The curve is formed by using a natural or monotonic cubic spline interpolation,
    depending on the interp option (default: natural).
    
    The natural spline produces a smoother curve in general while the monotonic (pchip) spline guarantees the transitions between the specified points to be monotonic.
    
    If the computed curves happened to go outside the vector spaces, the values will be clipped accordingly.
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#curves
.EXAMPLE
    Show-Media -InputPath ./SomeFile.mp4 -ColorCurveRed '0/0.11 .42/.51 1/0.95' -ColorCurveBlue '0/0.22 .49/.44 1/0.8' -ColorCurveGreen '0/0 0.50/0.48 1/1'
.EXAMPLE
    Show-Media -InputPath ./SomeFile.mp4 -ColorCurvePreset Vintage
#>
[Management.Automation.Cmdlet("Edit","Media")]
[Management.Automation.Cmdlet("Show","Media")]
param(
# If set, will adjust color curves
[Parameter(Mandatory)]
[Alias('curves','ColourCurve','ColorCurves','ColourCurves')]
[switch]
$ColorCurve,

# The red curve.
# This is a sequence of three ratios between 0-1
[Alias(
    'curves_red',
    'ColourCurveRed'
)]
[string]
$ColorCurveRed,

# The blue curve.
[Alias(
    'curves_blue',
    'ColourCurveBlue'
)]
[string]
$ColorCurveBlue,

# The green curve.
[Alias(
    'curves_green',
    'ColourCurveGreen'
)]
[string]
$ColorCurveGreen,

# The master color curve.
# Set the master key points. 
# These points will define a second pass mapping.
# It is sometimes called a "luminance" or "value" mapping.
# It can be used with r, g, b or all since it acts like a post-processing LUT.
[Alias(
    'curves_master',
    'ColorCurveLuminance','ColorCurveLuma',
    'ColourCurveLuminance','ColourCurveLuma',
    'ColourCurveMaster'
)]
[string]
$ColorCurveMaster,

# Set the key points for all components (not including master).
# Can be used in addition to the other key points component options.
# In this case, the unset component(s) will fallback on this all setting.
[Alias(
    'curves_all',
    'ColourCurveAll'
)]
[string]
$ColorCurveAll,

# The photoshop color curve file
[Alias(
    'curves_psfile',
    'ColorCurvePhotoshopFile','ColorCurvePSFile',
    'ColourCurvePhotoshop',
    'ColourCurvePhotoshopFile','ColourCurvePSFile'
)]
[string]
$ColorCurvePhotoshop,

# The GNU Plotfile used for the color curve.
[Alias(
    'curves_plot',
    'ColorCurveGnuPlot','ColorCurvePlotFile',
    'ColourCurvePlot','ColourCurveGnuPlot','ColourCurvePlotFile'    
)]
[string]
$ColorCurvePlot,

# The color curve preset.
[ValidateSet('color_negative','cross_process','darker','increase_contrast','lighter','linear_contrast','medium_contrast','negative','strong_contrast','vintage')]
[Alias('curves_preset', 'ColourCurvePreset')]
[string]
$ColorCurvePreset,

# The interpolation used for the color curve.
[ValidateSet('natural','pchip')]
[Alias('curves_interop','ColourCurveInterpolation')]
[string]
$ColorCurveInteroplation
)

# Collect our filter arguments
$filterArgs  = @(
    if ($ColorCurveRed) {"red='$ColorCurveRed'"}
    if ($ColorCurveBlue) {"blue='$ColorCurveBlue'"}
    if ($ColorCurveGreen) {"green='$ColorCurveGreen'"}
    if ($ColorCurveMaster) { "master='$ColorCurveMaster'"}
    if ($ColorCurveAll) { "all='$ColorCurveAll'"}
    if ($ColorCurvePreset) {
        "preset=$($ColorCurvePreset.ToLower())"
    }
    if ($ColorCurvePhotoshop) {
        "psfile='$colorCurvePhotoshop'"
    }
    if ($ColorCurvePlot) {
        "plot='$colorCurvePlot'"
    }
    if ($ColorCurveInteroplation) {
        "interp=$($ColorCurveInteroplation.ToLower())"
    }
 ) -join ':'
"-vf"
"curves=$filterArgs" -replace '=$'
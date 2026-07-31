<#
.SYNOPSIS
    Histogram Equalizer Extension
.DESCRIPTION
    This filter applies a global color histogram equalization on a per-frame basis.

    It can be used to correct video that has a compressed range of pixel intensities.
    The filter redistributes the pixel intensities to equalize their distribution across the intensity range.
    It may be viewed as an "automatically adjusting contrast filter".
    This filter is useful only for correcting degraded or poorly captured source video.
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#histogram
#>
[Management.Automation.Cmdlet("Edit","Media")]
[Management.Automation.Cmdlet("Show","Media")]
param(
# If set, will display a video histogram
[Parameter(Mandatory)]
[Alias('histeq')]
[switch]
$HistogramEqualizer,

# Determine the amount of equalization to be applied.
# As the strength is reduced, the distribution of pixel intensities more-and-more approaches that of the input frame.
# The value must be a float number in the range [0,1] and defaults to 0.200.
[ValidateRange(0,1)]
[Alias('histeq_strength')]
[float]
$HistogramEqualizerStrength,

# Set the maximum intensity that can generated and scale the output values appropriately. 
# The strength should be set as desired and then the intensity can be limited if needed to avoid washing-out.
# The value must be a float number in the range [0,1] and defaults to 0.210.
[ValidateRange(0,40)]
[float]
$HistogramEqualizerIntensity,

<#
Set the antibanding level. 
If enabled the filter will randomly vary the luminance of output pixels by a small amount to avoid banding of the histogram.
Possible values are none, weak or strong. 
#>
[ValidateSet('none','weak','strong')]
[Alias('histeq_antiband')]
[string]
$HistogramEqualizerAntibanding
)

$filterArgs  = @(
    if ($HistogramEqualizerAntibanding) {"antibanding=$($HistogramEqualizerAntibanding.ToLower())"}
    if ($HistogramEqualizerStrength) { "strength=$HistogramEqualizerStrength"}
    if ($HistogramEqualizerIntensity) { "intensity=$HistogramEqualizerIntensity"}
    
 ) -join ':'
"-vf"
"histeq=$filterArgs" -replace '=$'


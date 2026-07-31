<#
.Synopsis
    Offset the audio signal
.Description
    Offset the audio signal by a timespan.
.Link
    https://trac.ffmpeg.org/wiki/UnderstandingItsoffset
#>

[Management.Automation.Cmdlet('(?>Convert|Edit)', 'Media')]
param(
# Offset the audio signal by a timespan.
[Parameter(Mandatory)]
[TimeSpan]
$OffsetVideo
)

'-itsoffset'
$OffsetVideo.TotalSeconds
'-i'
$ri
'-map'
'0:a'
'-map'
'1:v'
'-c:a'
'copy'
'-c:v'
'copy'

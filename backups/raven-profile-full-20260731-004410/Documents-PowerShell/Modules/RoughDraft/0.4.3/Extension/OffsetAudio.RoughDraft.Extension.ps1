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
$OffsetAudio
)

'-itsoffset'
$OffsetAudio.TotalSeconds
'-i'
$ri
'-map'
'0:v'
'-map'
'1:a'
'-c:a'
'copy'
'-c:v'
'copy'

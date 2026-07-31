<#
.Synopsis
    Adjusts the rate of media.
.Description
    Adjusts the playback rate of media, making it slower or faster.
.Notes
    This uses a variety of filters:

    * setpts
    * atempo
    * asetpts
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#setpts
.LINK
    https://ffmpeg.org/ffmpeg-filters.html#atempo    
#>
[Management.Automation.Cmdlet("(?>Edit|Show)","Media")]   # It extends Edit or Show-Media
param(
# The new rate of the media.
[Parameter(Mandatory,ParameterSetName='Rate')]
[double]
$Rate,

# The target time for the media.  
# This will adjust the rate to match this target time.
[Parameter(Mandatory,ParameterSetName='TargetTime')]
[ValidateScript({
    if (
        $_ -isnot [TimeSpan] -and 
        $_ -isnot [int] -and
        $_ -isnot [double]
    ) {
        throw "Must be timespan, int, or double"
    }
    if (
        $_ -le 0
    ) {
        throw "Must be positive: $_"
    }
    return $true
})]
[psobject]
$TargetTime
)

$streams  = $MediaInfo.streams

$hasVideo = $streams | Where-Object { $_.Codec_Type -eq 'Video'}
$hasAudio = $streams | Where-Object { $_.Codec_Type -eq 'Audio'}

if ($targetTime -is [timespan]) {
    $rate = [TimeSpan]::FromSeconds($streams[0].duration) / $TargetTime
} elseif ($TargetTime) {
    $rate = $streams[0].duration / $TargetTime
}

if ($hasVideo -and $hasAudio) {
    $videoRate = 1 / $rate
    "-filter_complex"
    if ($rate -ge .05 -and $rate -le 100) {
        "[0:v]setpts=$videoRate*PTS[v];[0:a]atempo=$Rate[a]"
    } else {
        Write-Warning 'Stream Contains Audio and is being adjusted by a factor greater than 2. Audio frames will be dropped rather instead of adjusting the tempo.'
        "[0:v]setpts=$videoRate*PTS[v];[0:a]asetpts=$videoRate*PTS[a]"
    }
    "-map"
    '[v]'
    "-map"
    '[a]'
}
elseif ($hasVideo)
{
    $videoRate = 1 / $rate
    '-vf'
    "setpts=$videoRate*PTS"
}
elseif ($hasAudio) 
{
    '-af'
    if ($rate -ge .05 -and $rate -le 100) {
        "atempo=$Rate"
    } else {
        Write-Warning 'Stream Contains Audio and is being adjusted by a factor greater than 2. Audio frames will be dropped rather instead of adjusting the tempo.'
        "asetpts=$Rate*PTS"
    }
}

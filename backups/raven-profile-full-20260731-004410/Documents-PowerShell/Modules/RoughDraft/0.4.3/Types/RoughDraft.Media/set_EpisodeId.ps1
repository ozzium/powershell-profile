<#
.SYNOPSIS
    Sets the EpisodeID Metadata
.DESCRIPTION
    Changes the EpisodeID metadata for a media file (persistently, if possible)
.NOTES
    EpisodeID is stored within the ID3 tag `TVEN`.
#>
param()
$propertyToSet = @{"episode_id"="$args"}
if (-not $this.'.Metadata') {
    $this.'.Metadata' = [Ordered]@{}
}
$this.'.Metadata'.EpisodeID = $propertyToSet.episode_id
Set-Media -InputPath $this.InputPath -Property $propertyToSet


<#
.SYNOPSIS
    Sets the Mood Metadata
.DESCRIPTION
    Changes the Mood metadata for a media file (persistently, if possible)
.NOTES
    Mood is stored within the ID3 tag `WM/MOOD`.
#>
param()
$propertyToSet = @{"id3v2_priv.WM/MOOD"="$args";mood="$args"}
if (-not $this.'.Metadata') {
    $this.'.Metadata' = [Ordered]@{}
}
$this.'.Metadata'.Mood = $propertyToSet."id3v2_priv.WM/MOOD"
Set-Media -InputPath $this.InputPath -Property $propertyToSet


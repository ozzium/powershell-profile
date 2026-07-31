<#
.SYNOPSIS
    Gets Mood Metadata
.DESCRIPTION
    Gets the Mood Metadata, if present.
#>
param()
if ($this.'.Metadata'.Mood) {
    return ($this.'.Metadata'.Mood)
} elseif ($this.'.Metadata'.'WM/MOOD') {
    return ($this.'.Metadata'.'WM/MOOD')
} elseif ($this.'.Metadata'.'id3v2_priv.WM/MOOD') {
    return ($this.'.Metadata'.'id3v2_priv.WM/MOOD')
}


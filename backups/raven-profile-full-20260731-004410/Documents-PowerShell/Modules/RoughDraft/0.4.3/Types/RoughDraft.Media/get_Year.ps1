<#
.SYNOPSIS
    Gets Year Metadata
.DESCRIPTION
    Gets the Year Metadata, if present.
#>
param()
$yearInfo = if ($this.'.Metadata'.Year) {
    $this.'.Metadata'.Year
} elseif ($this.'.Metadata'.date) {
    $this.'.Metadata'.date
}

if ($yearInfo -match '^\d{4}$') {
    return ($yearInfo -as [int])
} elseif ($yearInfo -as [DateTime]) {
    return ([int]($yearInfo -as [datetime]).Year)
}



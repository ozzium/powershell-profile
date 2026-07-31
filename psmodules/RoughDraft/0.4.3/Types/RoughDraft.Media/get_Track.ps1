<#
.SYNOPSIS
    Gets Track Metadata
.DESCRIPTION
    Gets the Track Metadata, if present.
#>
param()
$trackAsInt = $this.'.Metadata'.Track -as [int]
if ($trackAsInt -gt 0) {
    return $trackAsInt
}


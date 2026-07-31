<#
.SYNOPSIS
    Gets Date Metadata
.DESCRIPTION
    Gets the Date Metadata, if present.
#>
param()
$dateInfo = 
    if ($this.'.Metadata'.date) {
        $this.'.Metadata'.date
    } elseif ($this.'.Metadata'.year) {
        $this.'.Metadata'.year
    }

if ($dateInfo -match '^\d{4}$') {
    return ([datetime]::ParseExact($dateInfo, "yyyy", $null))
} elseif ($dateInfo -as [DateTime]) {
    return ($dateInfo -as [DateTime])
}


<#
.SYNOPSIS
    Sets the Date Metadata
.DESCRIPTION
    Changes the Date metadata for a media file (persistently, if possible)
#>
param(
[ValidateScript({
    if ($_ -match '^\d{4}$') {
        return $true
    } elseif ($_ -is [DateTime]) {
        return $true
    } else {
        throw "Year must be a 4-digit number or a DateTime object"
    }
})]
[PSObject]
$Date
)


$propertyToSet = [Ordered]@{date="$Date"}
if (-not $this.'.Metadata') {
    $this.'.Metadata' = [Ordered]@{}
}
if ($Date -is [DateTime]) {
    $propertyToSet.date = $Date.ToString('yyyy-MM-dd')
    if (-not $this.'.Metadata'.year) {
        $propertyToSet.year = $Date.Year        
        $this.'.Metadata'.year = $propertyToSet.year
    }
}

$this.'.Metadata'.date = $propertyToSet.date
Set-Media -InputPath $this.InputPath -Property $propertyToSet


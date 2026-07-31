<#
.SYNOPSIS
    Sets the Year Metadata
.DESCRIPTION
    Changes the Year metadata for a media file (persistently, if possible)
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
$Year
)


$propertyToSet = [Ordered]@{year=$year}
if ($year -is [DateTime]) {
    $propertyToSet.year = $year.Year    
}
# $yearPortion = @($datePortion -split '-')[0]

if (-not $this.'.Metadata') {
    $this.'.Metadata' = [Ordered]@{}
}

if (-not $this.'.Metadata'.date) {
    $propertyToSet.date = $propertyToSet.year
    if ($year -is [DateTime]) {
        $propertyToSet.date = $year.ToString('yyyy-MM-dd')
    }
    $this.'.Metadata'.date = $propertyToSet.date    
}

$this.'.Metadata'.Year = $propertyToSet.year
Set-Media -InputPath $this.InputPath -Property $propertyToSet


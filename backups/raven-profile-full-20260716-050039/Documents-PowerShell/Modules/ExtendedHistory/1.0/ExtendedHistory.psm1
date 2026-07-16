# Module script (.psm1) for ExtendedHistory

# Import all the functions from the Functions folder
$functions = Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter *.ps1
foreach ($function in $functions) {
    . $function.fullname
    Export-ModuleMember -Function $function.basename
}

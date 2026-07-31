function Dismount-RoughDraft {
    <#
    .SYNOPSIS
        Dismounts paths to RoughDraft.
    .DESCRIPTION
        Dismounts a path related to RoughDraft.
    .EXAMPLE
        Dismount-RoughDraft -MountPath $MyMountedPath
    #>
    param(
    # The path to dismount
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('Fullname','Root')]
    [string]
    $MountPath
    )

    process {
        $driveFound = Get-PSDrive | 
            Where-Object { $_.Root -eq $MountPath -and $_.Name -match '^RoughDraft'}
            
        if ($driveFound) { 
            $driveFound | Remove-PSDrive
        } else {
            Write-Error "No RoughDraft drive found for $MountPath"
        }        
    }
}
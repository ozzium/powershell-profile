function Mount-RoughDraft {
    <#
    .SYNOPSIS
        Mounts paths to RoughDraft.
    .DESCRIPTION
        Mounts a path related to RoughDraft.
    #>
    param(
    # The path to mount
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('Fullname')]
    [string]
    $MountPath
    )

    process {
        if (Test-Path $mountPath) {
            New-PSDrive -Name "RoughDraft-$($MountPath | Split-Path -Leaf)" -PSProvider FileSystem -Root $mountPath -Scope Global
        }
    }
}
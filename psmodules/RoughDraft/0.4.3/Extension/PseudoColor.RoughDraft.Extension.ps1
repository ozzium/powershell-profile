
<#
.Synopsis
    pseudocolor
.Description
    Make pseudocolored video frames.
.Link
    https://ffmpeg.org/ffmpeg-filters.html#pseudocolor
#>

[Management.Automation.Cmdlet('Edit', 'Media')]

param(
    # Make pseudocolored video frames.
    [Parameter(Mandatory)]
    [switch]
    $Pseudocolor,
    # Set component #0 expression 
    [Alias('pseudocolor_c0')]
    [string]
    $PseudocolorComponent0,
    # set component #1 expression 
    [Alias('pseudocolor_c1')]
    [string]
    $PseudocolorComponent1,
    # set component #2 expression 
    [Alias('pseudocolor_c2')]
    [string]
    $PseudocolorComponent2,
    # set component #3 expression 
    [Alias('pseudocolor_c3')]
    [string]
    $PseudocolorComponent3,
    # set which component should be used as a base 
    [Alias('pseudocolor_i')]
    [ValidateRange(0, 3)]
    [int]
    $PseudoColorBaseIndex,

    # Sets the opacity of output colors.
    [ValidateRange(0,1)]
    [Alias('pseudocolor_opacity')]
    [float]
    $PseudocolorOpacity,

    [ValidateSet("magma","inferno","plasma","viridis","turbo","cividis","range1","range2","shadows","highlights","solar","nominal","preferred","total","spectral","cool","heat","fiery","blues","green","helix")]
    [Alias('pseudocolor_preset')]
    [string]
    $PseudoColorPreset
)



$filterName = 'pseudocolor'
$myCmd = $MyInvocation.MyCommand
$filterArgs = @(
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
        $match=  
            foreach ($paramAlias in $myCmd.Parameters[$kv.Key].Aliases) {
                $m = [Regex]::Match($paramAlias, '_(?<p>.+)$')
                if ($m.Success) {
                    $m;break
                }
            }
        
        if ($match.Success) {
            $v = $kv.Value
            $p = $match.Value -replace '^_'
            if ($v -is [switch]) {
                $v = ($v -as [bool] -as [int]).ToString().ToLower()
            }
            if ($v -is [string] -and $myCmd.Parameters[$kv.Key].ValidateSet) {
                $v = $v.ToLower()
            }
            "$p=$($v)"
        }
    }
) -join ':'
'-vf'


"$filterName=$filterArgs" -replace "=$"
 


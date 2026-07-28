# Get library name, from the PSM1 file name
$LibraryName = 'ImagePlayground.PowerShell'
$Library = "$LibraryName.dll"
$Class = "$LibraryName.Initialize"

$AssemblyFolders = Get-ChildItem -Path $PSScriptRoot\Lib -Directory -ErrorAction SilentlyContinue

# Lets find which libraries we need to load
$Default = $false
$Core = $false
$Standard = $false
foreach ($A in $AssemblyFolders.Name) {
    if ($A -eq 'Default') {
        $Default = $true
    } elseif ($A -eq 'Core') {
        $Core = $true
    } elseif ($A -eq 'Standard') {
        $Standard = $true
    }
}
if ($Standard -and $Core -and $Default) {
    $FrameworkNet = 'Default'
    $Framework = 'Standard'
} elseif ($Standard -and $Core) {
    $Framework = 'Standard'
    $FrameworkNet = 'Standard'
} elseif ($Core -and $Default) {
    $Framework = 'Core'
    $FrameworkNet = 'Default'
} elseif ($Standard -and $Default) {
    $Framework = 'Standard'
    $FrameworkNet = 'Default'
} elseif ($Standard) {
    $Framework = 'Standard'
    $FrameworkNet = 'Standard'
} elseif ($Core) {
    $Framework = 'Core'
    $FrameworkNet = ''
} elseif ($Default) {
    $Framework = ''
    $FrameworkNet = 'Default'
} else {
    Write-Error -Message 'No assemblies found'
}
if ($PSEdition -eq 'Core') {
    $LibFolder = $Framework
} else {
    $LibFolder = $FrameworkNet
}

try {
    $ImportModule = Get-Command -Name Import-Module -Module Microsoft.PowerShell.Core

    if (-not ($Class -as [type])) {
        & $ImportModule ([IO.Path]::Combine($PSScriptRoot, 'Lib', $LibFolder, $Library)) -ErrorAction Stop
    } else {
        $Type = "$Class" -as [Type]
        & $importModule -Force -Assembly ($Type.Assembly)
    }
} catch {
    if ($ErrorActionPreference -eq 'Stop') {
        throw
    } else {
        Write-Warning -Message "Importing module $Library failed. Fix errors before continuing. Error: $($_.Exception.Message)"
        # we will continue, but it's not a good idea to do so
        # return
    }
}
# Dot source all libraries by loading external file
. $PSScriptRoot\ImagePlayground.Libraries.ps1

function ConvertTo-Image {
    <#
    .SYNOPSIS
    Converts the image to the specified format.

    .DESCRIPTION
    Converts the image to the specified format. The output path must include the file extension.

    .PARAMETER FilePath
    File path to the image you want to convert.

    .PARAMETER OutputPath
    File path to the output image that will be created.

    .EXAMPLE
    ConvertTo-Image -FilePath $PSScriptRoot\Samples\LogoEvotec.png -OutputPath $PSScriptRoot\Output\LogoEvotec.jpg

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][string] $FilePath,
        [parameter(Mandatory)][string] $OutputPath
    )
    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        [ImagePlayground.ImageHelper]::ConvertTo($FilePath, $OutputPath)
    } else {
        Write-Warning -Message "Resize-Image - File $FilePath not found. Please check the path."
    }
}
function Get-Image {
    <#
    .SYNOPSIS
    Gets the image from the file path for further processing and image manipulation.

    .DESCRIPTION
    Gets the image from the file path for further processing and image manipulation.

    .PARAMETER FilePath
    File path to the image you want to read and manipulate.

    .EXAMPLE
    $Image = Get-Image -FilePath $PSScriptRoot\Samples\LogoEvotec.png
    $Image.BlackWhite()
    $Image.BackgroundColor("Red")
    Save-Image -Image $Image -Open -FilePath $PSScriptRoot\Output\LogoEvotecChanged.png

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Warning -Message "Get-Image - File $FilePath not found. Please check the path."
        return
    }
    $Image = [ImagePlayground.Image]::Load($FilePath)
    $Image
}
function Get-ImageBarCode {
    <#
    .SYNOPSIS
    Gets bar code from image

    .DESCRIPTION
    Gets bar code from image

    .PARAMETER FilePath
    File path to image to be processed for bar code reading

    .EXAMPLE
    Get-ImageBarCode -FilePath "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg"

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [string] $FilePath
    )
    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        $BarCode = [ImagePlayground.BarCode]::Read($FilePath)
        $BarCode
    } else {
        Write-Warning -Message "Get-ImageBarCode - File $FilePath not found. Please check the path."
    }
}
function Get-ImageExif {
    <#
    .SYNOPSIS
    Gets EXIF data from image

    .DESCRIPTION
    Gets EXIF data from image.

    .PARAMETER FilePath
    File path to image to be processed for Exif Tag reading

    .EXAMPLE
    Get-ImageExif -FilePath "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg"

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [switch] $Translate
    )
    if (-not (Test-Path $FilePath)) {
        Write-Warning -Message "Get-ImageExif - File not found: $FilePath"
        return
    }
    $Image = Get-Image -FilePath $FilePath
    if ($Translate) {
        $SingleExif = [ordered] @{}
        $Image.Metadata.ExifProfile.Values | ForEach-Object {
            $SingleExif[$_.Tag.ToString()] = $_.Value
        }
        [PSCustomObject] $SingleExif
    } else {
        $Image.Metadata.ExifProfile.Values
    }
}
function Get-ImageQRCode {
    <#
    .SYNOPSIS
    Gets QR code from image

    .DESCRIPTION
    Gets QR code from image

    .PARAMETER FilePath
    File path to image to be processed for QR code reading

    .EXAMPLE
    Get-ImageQRCode -FilePath "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg"

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [string] $FilePath
    )
    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        $QRCode = [ImagePlayground.QRCode]::Read($FilePath)
        $QRCode
    } else {
        Write-Warning -Message "Get-ImageQRCode - File $FilePath not found. Please check the path."
    }
}
function Merge-Image {
    <#
    .SYNOPSIS
    Merges two images into a single image

    .DESCRIPTION
    Merges two images into a single image

    .PARAMETER FilePath
    File path to image to be processed for merging of images. This image will be the base image.

    .PARAMETER FilePathToMerge
    File path to image to be merged into the base image.

    .PARAMETER FilePathOutput
    File path to output image.

    .PARAMETER ResizeToFit
    Resize the image to fit the base image. If not specified, the image will be added as is.

    .PARAMETER Placement
    Placement of the image to be merged. Default is bottom. Possible values: Top, Bottom, Left, Right

    .EXAMPLE
    Merge-Image -FilePath "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg" -FilePathToMerge "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg" -FilePathOutput "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg" -ResizeToFit -Placement Bottom

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [string] $FilePathToMerge,
        [string] $FilePathOutput,
        [switch] $ResizeToFit,
        [ImagePlayground.ImagePlacement] $Placement = [ImagePlayground.ImagePlacement]::Bottom
    )
    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Warning -Message "Merge-Image - File $FilePath not found. Please check the path."
        return
    }
    if (-not (Test-Path -LiteralPath $FilePathToMerge)) {
        Write-Warning -Message "Merge-Image - File $FilePathToMerge not found. Please check the path."
        return
    }
    [ImagePlayground.ImageHelper]::Combine($FilePath, $FilePathToMerge, $FilePathOutput, $ResizeToFit.IsPresent, $Placement)
}
function New-ImageBarCode {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][ImagePlayground.BarCode+BarcodeTypes] $Type,
        [parameter(Mandatory)][string] $Value,
        [parameter(Mandatory)][string] $FilePath
    )
    [ImagePlayground.BarCode]::Generate($Type, $Value, $filePath)
}
function New-ImageChart {
    [cmdletBinding()]
    param(
        [scriptblock] $ChartsDefinition,
        [int] $Width = 600,
        [int] $Height = 400,
        [string] $FilePath,
        [switch] $Show
    )
    $ValueHash = [ordered] @{}
    $Values = [System.Collections.Generic.List[double]]::new()
    $Labels = [System.Collections.Generic.List[string]]::new()
    $Positions = [System.Collections.Generic.List[int]]::new()
    $Plot = [ScottPlot.Plot]::new($Width, $Height)
    $Position = 0

    if ($ChartsDefinition) {
        $OutputDefintion = & $ChartsDefinition
        foreach ($Definition in $OutputDefintion) {
            if ($Definition.ObjectType -eq 'Bar') {
                $Type = 'Bar'
                for ($i = 0; $i -lt $Definition.Value.Count; $i++) {
                    if (-not $ValueHash["$i"]) {
                        $ValueHash["$i"] = [System.Collections.Generic.List[double]]::new()
                    }
                    $ValueHash["$i"].Add($Definition.Value[$i])
                }
                $Labels.Add($Definition.Name)
            } elseif ($Definition.ObjectType -eq 'Line') {
                $Type = 'Line'

                #if (-not $ValueHash["$Position"]) {
                # $ValueHash["$Position"] = [System.Collections.Generic.List[double]]::new()
                #}
                $ValueHash["$($Definition.Name)"] = $Definition.Value
            } elseif ($Definition.ObjectType -eq 'Pie') {
                $Type = 'Pie'
                $Values.Add($Definition.Value)
                $Labels.Add($Definition.Name)
            } elseif ($Definition.ObjectType -eq 'Radial') {
                $Type = 'Radial'
                $Values.Add($Definition.Value)
                $Labels.Add($Definition.Name)
            }
            $Positions.Add($Position)
            $Position++
        }
    }
    if ($Type -eq 'Bar') {
        #void SetAxisLimits(System.Nullable[double] xMin, System.Nullable[double] xMax, System.Nullable[double] yMin, System.Nullable[double] yMax, int xAxisIndex, int yAxisIndex)
        #void SetAxisLimits(ScottPlot.AxisLimits limits, int xAxisIndex, int yAxisIndex)
        # adjust axis limits so there is no padding below the bar graph
        # $Plot.SetAxisLimits(yMin: 0);
        if ($ValueHash) {
            foreach ($Value in $ValueHash.Keys) {
                $null = $Plot.AddBar($ValueHash[$Value])
            }
        }
        if ($Labels) {
            $null = $Plot.XTicks($Positions, $Labels)
        }
    } elseif ($Type -eq 'Line') {
        if ($ValueHash) {
            foreach ($Value in $ValueHash.Keys) {
                #ScottPlot.Plottable.SignalPlot AddSignal(double[] ys, double sampleRate = 1, System.Nullable[System.Drawing.Color] color = default, string label = null)
                #ScottPlot.Plottable.SignalPlotGeneric[T] AddSignal[T](T[] ys, double sampleRate = 1, System.Nullable[System.Drawing.Color] color = default, string label = null)
                $null = $Plot.AddSignal($ValueHash[$Value], 1, $null, $Value)
            }
        }
        $null = $Plot.Legend($true, 7)
    } elseif ($Type -eq 'Pie') {
        $PieChart = $Plot.AddPie($Values)
        $PieChart.SliceLabels = $Labels
        $PieChart.ShowLabels = $true
    } elseif ($Type -eq 'Radial') {
        $RadialChart = $Plot.AddRadialGauge($Values)
        $RadialChart.Labels = $Labels
        $null = $Plot.Legend($true, 7)
    }


    if (-not $FilePath) {
        $FilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).png")
        Write-Warning -Message "New-ImageChart - No file path specified, saving to $FilePath"
    }
    try {
        $null = $Plot.SaveFig($FilePath)
        if ($Show) {
            Invoke-Item -LiteralPath $FilePath
        }
    } catch {
        Write-Warning -Message "New-ImageChart - Error creating image chart $($_.Exception.Message)"
    }
}
function New-ImageChartBar {
    [cmdletBinding()]
    param(
        [alias('Label')][string] $Name,
        [Array] $Value
    )
    [PSCustomObject] @{
        ObjectType = 'Bar'
        Name       = $Name
        Value      = $Value
    }
}
function New-ImageChartBarOptions {
    [cmdletBinding()]
    param(
        [switch] $ShowValuesAboveBars
    )

    [PSCustomObject] @{
        ObjectType          = 'BarOptions'
        ShowValuesAboveBars = $ShowValuesAboveBars.IsPresent
    }
}
function New-ImageChartLine {
    [CmdletBinding()]
    param(
        [alias('Label')][string] $Name,
        [Array] $Value
    )
    [PSCustomObject] @{
        ObjectType = 'Line'
        Name       = $Name
        Value      = $Value
    }
}
function New-ImageChartPie {
    [cmdletbinding()]
    param(
        [alias('Label')][string] $Name,
        [double] $Value
    )
    [PSCustomObject] @{
        ObjectType = 'Pie'
        Name       = $Name
        Value      = $Value
    }
}
function New-ImageChartRadial {
    [cmdletbinding()]
    param(
        [alias('Label')][string] $Name,
        [double] $Value
    )
    [PSCustomObject] @{
        ObjectType = 'Radial'
        Name       = $Name
        Value      = $Value
    }
}
function New-ImageQRCode {
    <#
    .SYNOPSIS
    Creates QR code

    .DESCRIPTION
    Creates QR code

    .PARAMETER Content
    Content to be encoded in QR code

    .PARAMETER FilePath
    File path to where the image with QR code should be saved.

    .EXAMPLE
    New-ImageQRCode -Content 'https://evotec.xyz' -FilePath "$PSScriptRoot\Samples\QRCode.png" -Verbose

    .NOTES
    General notes
    #>
    [Alias('New-QRCode')]
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Content,
        [Parameter(Mandatory)][string] $FilePath
    )
    if (-not $FilePath) {
        $FilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).png")
        Write-Warning -Message "New-ImageQRCode - No file path specified, saving to $FilePath"
    }
    try {
        [ImagePlayground.QrCode]::Generate($Content, $FilePath, $false)

        if ($Show) {
            Invoke-Item -LiteralPath $FilePath
        }
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            throw
        } else {
            Write-Warning -Message "New-ImageQRCodeWiFi - Error creating image $($_.Exception.Message)"
        }
    }
}
function New-ImageQRCodeWiFi {
    <#
    .SYNOPSIS
    Creates QR code for WiFi connection

    .DESCRIPTION
    Creates QR code for WiFi connection

    .PARAMETER SSID
    SSID of the WiFi network

    .PARAMETER Password
    Password of the WiFi network

    .PARAMETER FilePath
    File path to where the image with QR code should be saved.

    .PARAMETER Show
    Opens the image in default image viewer after saving

    .EXAMPLE
    New-ImageQRCodeWiFi -SSID 'Evotec' -Password 'Evotec' -FilePath "$PSScriptRoot\Samples\QRCodeWiFi.png"

    .NOTES
    General notes
    #>
    [alias('New-QRCodeWiFi')]
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $SSID,
        [Parameter(Mandatory)][string] $Password,
        [Parameter(Mandatory)][string] $FilePath,
        [switch] $Show
    )
    if (-not $FilePath) {
        $FilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).png")
        Write-Warning -Message "New-ImageQRCodeWiFi - No file path specified, saving to $FilePath"
    }
    try {
        [ImagePlayground.QrCode]::GenerateWiFi($ssid, $password, $FilePath, $false)

        if ($Show) {
            Invoke-Item -LiteralPath $FilePath
        }
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            throw
        } else {
            Write-Warning -Message "New-ImageQRCodeWiFi - Error creating image $($_.Exception.Message)"
        }
    }
}
function New-ImageQRContact {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [QRCoder.PayloadGenerator+ContactData+ContactOutputType] $outputType = [QRCoder.PayloadGenerator+ContactData+ContactOutputType]::VCard4,
        [string] $Firstname,
        [string] $Lastname,
        [string] $Nickname ,
        [string] $Phone ,
        [string] $MobilePhone ,
        [string] $WorkPhone ,
        [string] $Email ,
        [DateTime] $Birthday ,
        [string] $Website ,
        [string] $Street ,
        [string] $HouseNumber ,
        [string] $City ,
        [string] $ZipCode ,
        [string] $Country ,
        [string] $Note ,
        [string] $StateRegion ,
        [ValidateSet('Default', 'Reversed')][string] $AddressOrder = 'Default',
        [string] $Org ,
        [string] $OrgTitle,
        [switch] $Show
    )

    if (-not $FilePath) {
        $FilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$($([System.IO.Path]::GetRandomFileName()).Split('.')[0]).png")
        Write-Warning -Message "New-ImageQRContact - No file path specified, saving to $FilePath"
    }
    try {
        [ImagePlayground.QrCode]::GenerateContact(
            $filePath, $outputType, $firstname,
            $lastname, $nickname, $phone,
            $mobilePhone, $workPhone, $email,
            $birthday, $website, $street, $houseNumber,
            $city, $zipCode, $country, $note, $stateRegion, $addressOrder,
            $org, $orgTitle, $false
        )

        if ($Show) {
            Invoke-Item -LiteralPath $FilePath
        }
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            throw
        } else {
            Write-Warning -Message "New-ImageQRContact - Error creating image $($_.Exception.Message)"
        }
    }
}
function Remove-ImageExif {
    <#
    .SYNOPSIS
    Removes EXIF data from image

    .DESCRIPTION
    Removes EXIF data from image.

    .PARAMETER FilePath
    File path to image to be processed for Exif Tag removal

    .PARAMETER FilePathOutput
    File path to where the image with removed Exif Tag should be saved. If not specified, the original image will be overwritten.

    .PARAMETER ExifTag
    Exif Tag to be removed from image

    .PARAMETER All
    Removes all Exif Tags from image

    .EXAMPLE
    Remove-ImageExif -FilePath "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg" -ExifTag [SixLabors.ImageSharp.Metadata.Profiles.Exif.ExifTag]::ExposureTime

    .EXAMPLE
    Remove-ImageExif -FilePath "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg" -All

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'RemoveExifTag')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory, ParameterSetName = 'RemoveExifTag')]
        [string] $FilePath,
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory, ParameterSetName = 'RemoveExifTag')]
        [string] $FilePathOutput,
        [Parameter(Mandatory, ParameterSetName = 'RemoveExifTag')]
        [SixLabors.ImageSharp.Metadata.Profiles.Exif.ExifTag[]] $ExifTag,
        [Parameter(Mandatory, ParameterSetName = 'All')][switch] $All
    )
    $Image = Get-Image -FilePath $FilePath
    if ($All) {
        Write-Verbose "Remove-ImageExif: Removing all Exif tags"
        $Image.Metadata.ExifProfile.Values.Clear()
    } else {
        foreach ($Tag in $ExifTag) {
            Write-Verbose "Remove-ImageExif: Removing $Tag"
            $Image.Metadata.ExifProfile.RemoveValue($Tag)
        }
    }
    if ($FilePathOutput) {
        Save-Image -Image $Image -FilePath $FilePathOutput
    } else {
        Save-Image -Image $Image -FilePath $FilePath
    }
}
function Resize-Image {
    <#
    .SYNOPSIS
    Resizes the image to given width and height or percentage.

    .DESCRIPTION
    Resizes the image to given width and height or percentage.
    By default it will respect aspect ratio. If you want to ignore it use -DontRespectAspectRatio switch.
    This means you can only provide Width and the height will be automatically calculated or vice versa.
    You can also use percentage to resize the image maintaining the aspect ratio.

    .PARAMETER FilePath
    File path to the image you want to resize

    .PARAMETER OutputPath
    File path to the output image that will be created

    .PARAMETER Width
    New width of the image

    .PARAMETER Height
    New height of the image

    .PARAMETER Percentage
    Percentage of the image to resize

    .PARAMETER DontRespectAspectRatio
    If you want to ignore aspect ratio use this switch. It only affects Width and Height parameters that are used separately.

    .EXAMPLE
    Resize-Image -FilePath $PSScriptRoot\Samples\LogoEvotec.png -OutputPath $PSScriptRoot\Output\LogoEvotecResize.png -Width 100 -Height 100

    .EXAMPLE
    Resize-Image -FilePath $PSScriptRoot\Samples\LogoEvotec.png -OutputPath $PSScriptRoot\Output\LogoEvotecResizeMaintainAspectRatio.png -Width 300

    .EXAMPLE
    Resize-Image -FilePath $PSScriptRoot\Samples\LogoEvotec.png -OutputPath $PSScriptRoot\Output\LogoEvotecResizePercent.png -Percentage 200

    .NOTES
    General notes
    #>
    [cmdletBinding(DefaultParameterSetName = 'HeightWidth')]
    param(
        [parameter(ParameterSetName = 'Percentage')]
        [parameter(ParameterSetName = 'HeightWidth')]
        [parameter(Mandatory)][string] $FilePath,

        [parameter(ParameterSetName = 'Percentage')]
        [parameter(ParameterSetName = 'HeightWidth')]
        [parameter(Mandatory)][string] $OutputPath,

        [parameter(ParameterSetName = 'HeightWidth')][int] $Width,
        [parameter(ParameterSetName = 'HeightWidth')][int] $Height,
        [parameter(ParameterSetName = 'Percentage')][int] $Percentage,
        [parameter(ParameterSetName = 'HeightWidth')][switch] $DontRespectAspectRatio
    )
    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        if ($Percentage) {
            [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $Percentage)
        } else {
            if ($DontRespectAspectRatio) {
                if ($PSBoundParameters.ContainsKey('Width') -and $PSBoundParameters.ContainsKey('Height')) {
                    [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $Width, $Height)
                } elseif ($PSBoundParameters.ContainsKey('Width')) {
                    [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $Width, $null, $false)
                } elseif ($PSBoundParameters.ContainsKey('Height')) {
                    [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $null, $Height, $false)
                } else {
                    Write-Warning -Message "Resize-Image - Please specify Width or Height or Percentage."
                }
            } else {
                if ($PSBoundParameters.ContainsKey('Width') -and $PSBoundParameters.ContainsKey('Height')) {
                    [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $Width, $Height)
                } elseif ($PSBoundParameters.ContainsKey('Width')) {
                    [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $Width, $null)
                } elseif ($PSBoundParameters.ContainsKey('Height')) {
                    [ImagePlayground.ImageHelper]::Resize($FilePath, $OutputPath, $null, $Height)
                } else {
                    Write-Warning -Message "Resize-Image - Please specify Width or Height or Percentage."
                }
            }
        }
    } else {
        Write-Warning -Message "Resize-Image - File $FilePath not found. Please check the path."
    }
}
function Save-Image {
    <#
    .SYNOPSIS
    Saves image that was open for processing

    .DESCRIPTION
    Saves image that was open for processing

    .PARAMETER Image
    Image object to be saved

    .PARAMETER FilePath
    File path to where the image should be saved. If not specified, the original image will be overwritten.

    .PARAMETER Open
    Opens the image in default image viewer after saving

    .EXAMPLE
    $Image = Get-Image -FilePath $PSScriptRoot\Samples\LogoEvotec.png
    $Image.BlackWhite()
    $Image.BackgroundColor("Red")
    Save-Image -Image $Image -Open -FilePath $PSScriptRoot\Output\LogoEvotecChanged.png

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][ImagePlayground.Image] $Image,
        [string] $FilePath,
        [switch] $Open
    )
    if ($FilePath) {
        $Image.Save($FilePath, $Open.IsPresent)
    } else {
        $Image.Save($Open.IsPresent)
    }
}
function Set-ImageExif {
    <#
    .SYNOPSIS
    Sets EXIF tag to specific value

    .DESCRIPTION
    Sets EXIF tag to specific value

    .PARAMETER FilePath
    File path to image to be processed for Exif Tag manipulation. If FilePathOutput is not specified, the image will be overwritten.

    .PARAMETER FilePathOutput
    File path to output image. If not specified, the image will be overwritten.

    .PARAMETER ExifTag
    Exif Tag to be set

    .PARAMETER Value
    Value to be set

    .EXAMPLE
    $setImageExifSplat = @{
        FilePath       = "C:\Users\przemyslaw.klys\Downloads\IMG_4644.jpeg"
        ExifTag        = ([SixLabors.ImageSharp.Metadata.Profiles.Exif.ExifTag]::DateTimeOriginal)
        Value          = ([DateTime]::Now).ToString("yyyy:MM:dd HH:mm:ss")
        FilePathOutput = "$PSScriptRoot\Output\IMG_4644.jpeg"
    }

    Set-ImageExif @setImageExifSplat

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [string] $FilePathOutput,
        [Parameter(Mandatory)][SixLabors.ImageSharp.Metadata.Profiles.Exif.ExifTag] $ExifTag,
        [Parameter(Mandatory)] $Value
    )
    if (-not (Test-Path $FilePath)) {
        Write-Warning -Message "Set-ImageExif - File not found: $FilePath"
        return
    }
    $Image = Get-Image -FilePath $FilePath
    # void SetValue[TValueType](SixLabors.ImageSharp.Metadata.Profiles.Exif.ExifTag[TValueType] tag, TValueType value)
    $Image.Metadata.ExifProfile.SetValue($ExifTag, $Value)
    if ($FilePathOutput) {
        Save-Image -Image $Image -FilePath $FilePathOutput
    } else {
        Save-Image -Image $Image -FilePath $FilePath
    }
}


if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -lt 461808) {
    Write-Warning "This module requires .NET Framework 4.7.2 or later."; return 
} 

# Export functions and aliases as required
Export-ModuleMember -Function @('ConvertTo-Image', 'Get-Image', 'Get-ImageBarCode', 'Get-ImageExif', 'Get-ImageQRCode', 'Merge-Image', 'New-ImageBarCode', 'New-ImageChart', 'New-ImageChartBar', 'New-ImageChartBarOptions', 'New-ImageChartLine', 'New-ImageChartPie', 'New-ImageChartRadial', 'New-ImageQRCode', 'New-ImageQRCodeWiFi', 'New-ImageQRContact', 'Remove-ImageExif', 'Resize-Image', 'Save-Image', 'Set-ImageExif') -Alias @('New-QRCode', 'New-QRCodeWiFi')
# SIG # Begin signature block
# MIItsQYJKoZIhvcNAQcCoIItojCCLZ4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDpQEt28JBCdaLy
# KDCVuPof6u1Npjy0zxvB4KH2Ic32qqCCJrQwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggWQMIIDeKADAgECAhAFmxtXno4hMuI5B72nd3VcMA0GCSqG
# SIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYD
# VR0PAQH/BAQDAgGGMB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzANBgkq
# hkiG9w0BAQwFAAOCAgEAu2HZfalsvhfEkRvDoaIAjeNkaA9Wz3eucPn9mkqZucl4
# XAwMX+TmFClWCzZJXURj4K2clhhmGyMNPXnpbWvWVPjSPMFDQK4dUPVS/JA7u5iZ
# aWvHwaeoaKQn3J35J64whbn2Z006Po9ZOSJTROvIXQPK7VB6fWIhCoDIc2bRoAVg
# X+iltKevqPdtNZx8WorWojiZ83iL9E3SIAveBO6Mm0eBcg3AFDLvMFkuruBx8lbk
# apdvklBtlo1oepqyNhR6BvIkuQkRUNcIsbiJeoQjYUIp5aPNoiBB19GcZNnqJqGL
# FNdMGbJQQXE9P01wI4YMStyB0swylIQNCAmXHE/A7msgdDDS4Dk0EIUhFQEI6FUy
# 3nFJ2SgXUE3mvk3RdazQyvtBuEOlqtPDBURPLDab4vriRbgjU2wGb2dVf0a1TD9u
# KFp5JtKkqGKX0h7i7UqLvBv9R0oN32dmfrJbQdA75PQ79ARj6e/CVABRoIoqyc54
# zNXqhwQYs86vSYiv85KZtrPmYQ/ShQDnUBrkG5WdGaG5nLGbsQAe79APT0JsyQq8
# 7kP6OnGlyE0mpTX9iV28hWIdMtKgK1TtmlfB2/oQzxm3i0objwG2J5VT6LaJbVu8
# aNQj6ItRolb58KaAoNYes7wPD1N1KarqE3fk3oyBIa0HEEcRrYc9B9F1vM/zZn4w
# ggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbS
# g9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9
# /UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXn
# HwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0
# VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4f
# sbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40Nj
# gHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0
# QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvv
# mz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T
# /jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk
# 42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5r
# mQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# AH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxp
# wc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIl
# zpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQ
# cAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfe
# Kuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+j
# Sbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJsh
# IUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6
# OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDw
# N7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR
# 81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2
# VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGsDCCBJigAwIBAgIQ
# CK1AsmDSnEyfXs2pvZOu2TANBgkqhkiG9w0BAQwFADBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjEwNDI5MDAw
# MDAwWhcNMzYwNDI4MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBT
# aWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA1bQvQtAorXi3XdU5WRuxiEL1M4zrPYGXcMW7xIUmMJ+k
# jmjYXPXrNCQH4UtP03hD9BfXHtr50tVnGlJPDqFX/IiZwZHMgQM+TXAkZLON4gh9
# NH1MgFcSa0OamfLFOx/y78tHWhOmTLMBICXzENOLsvsI8IrgnQnAZaf6mIBJNYc9
# URnokCF4RS6hnyzhGMIazMXuk0lwQjKP+8bqHPNlaJGiTUyCEUhSaN4QvRRXXegY
# E2XFf7JPhSxIpFaENdb5LpyqABXRN/4aBpTCfMjqGzLmysL0p6MDDnSlrzm2q2AS
# 4+jWufcx4dyt5Big2MEjR0ezoQ9uo6ttmAaDG7dqZy3SvUQakhCBj7A7CdfHmzJa
# wv9qYFSLScGT7eG0XOBv6yb5jNWy+TgQ5urOkfW+0/tvk2E0XLyTRSiDNipmKF+w
# c86LJiUGsoPUXPYVGUztYuBeM/Lo6OwKp7ADK5GyNnm+960IHnWmZcy740hQ83eR
# Gv7bUKJGyGFYmPV8AhY8gyitOYbs1LcNU9D4R+Z1MI3sMJN2FKZbS110YU0/EpF2
# 3r9Yy3IQKUHw1cVtJnZoEUETWJrcJisB9IlNWdt4z4FKPkBHX8mBUHOFECMhWWCK
# ZFTBzCEa6DgZfGYczXg4RTCZT/9jT0y7qg0IU0F8WD1Hs/q27IwyCQLMbDwMVhEC
# AwEAAaOCAVkwggFVMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFGg34Ou2
# O/hfEYb7/mF7CIhl9E5CMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9P
# MA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzB3BggrBgEFBQcB
# AQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggr
# BgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwHAYDVR0gBBUwEzAH
# BgVngQwBAzAIBgZngQwBBAEwDQYJKoZIhvcNAQEMBQADggIBADojRD2NCHbuj7w6
# mdNW4AIapfhINPMstuZ0ZveUcrEAyq9sMCcTEp6QRJ9L/Z6jfCbVN7w6XUhtldU/
# SfQnuxaBRVD9nL22heB2fjdxyyL3WqqQz/WTauPrINHVUHmImoqKwba9oUgYftzY
# gBoRGRjNYZmBVvbJ43bnxOQbX0P4PpT/djk9ntSZz0rdKOtfJqGVWEjVGv7XJz/9
# kNF2ht0csGBc8w2o7uCJob054ThO2m67Np375SFTWsPK6Wrxoj7bQ7gzyE84FJKZ
# 9d3OVG3ZXQIUH0AzfAPilbLCIXVzUstG2MQ0HKKlS43Nb3Y3LIU/Gs4m6Ri+kAew
# Q3+ViCCCcPDMyu/9KTVcH4k4Vfc3iosJocsL6TEa/y4ZXDlx4b6cpwoG1iZnt5Lm
# Tl/eeqxJzy6kdJKt2zyknIYf48FWGysj/4+16oh7cGvmoLr9Oj9FpsToFpFSi0HA
# SIRLlk2rREDjjfAVKM7t8RhWByovEMQMCGQ8M4+uKIw8y4+ICw2/O/TOHnuO77Xr
# y7fwdxPm5yg/rBKupS8ibEH5glwVZsxsDsrFhsP2JjMMB0ug0wcCampAMEhLNKhR
# ILutG4UI4lkNbcoFUCvqShyepf2gpx8GdOfy1lKQ/a+FSCH5Vzu0nAPthkX0tGFu
# v2jiJmCG6sivqf6UHedjGzqGVnhOMIIGwjCCBKqgAwIBAgIQBUSv85SdCDmmv9s/
# X+VhFjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5
# NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIzMDcxNDAwMDAwMFoXDTM0MTAx
# MzIzNTk1OVowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMzCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAKNTRYcdg45brD5UsyPgz5/X5dLnXaEOCdwvSKOX
# ejsqnGfcYhVYwamTEafNqrJq3RApih5iY2nTWJw1cb86l+uUUI8cIOrHmjsvlmbj
# aedp/lvD1isgHMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSUpIIa2mq62DvKXd4ZGIX7
# ReoNYWyd/nFexAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH9kgtXkV1lnX+3RChG4PB
# uOZSlbVH13gpOWvgeFmX40QrStWVzu8IF+qCZE3/I+PKhu60pCFkcOvV5aDaY7Mu
# 6QXuqvYk9R28mxyyt1/f8O52fTGZZUdVnUokL6wrl76f5P17cz4y7lI0+9S769Sg
# LDSb495uZBkHNwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZD+BYQfvYsSzhUa+0rRUG
# FOpiCBPTaR58ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOlO0L9c33u3Qr/eTQQfqZc
# ClhMAD6FaXXHg2TWdc2PEnZWpST618RrIbroHzSYLzrqawGw9/sqhux7UjipmAmh
# cbJsca8+uG+W1eEQE/5hRwqM/vC2x9XH3mwk8L9CgsqgcT2ckpMEtGlwJw1Pt7U2
# 0clfCKRwo+wK8REuZODLIivK8SgTIUlRfgZm0zu++uuRONhRB8qUt+JQofM604qD
# y0B7AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAW
# BgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglg
# hkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0O
# BBYEFKW27xPn783QZKHVVqllMaPe1eNJMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEy
# NTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZT
# SEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAIEa1t6g
# qbWYF7xwjU+KPGic2CX/yyzkzepdIpLsjCICqbjPgKjZ5+PF7SaCinEvGN1Ott5s
# 1+FgnCvt7T1IjrhrunxdvcJhN2hJd6PrkKoS1yeF844ektrCQDifXcigLiV4JZ0q
# BXqEKZi2V3mP2yZWK7Dzp703DNiYdk9WuVLCtp04qYHnbUFcjGnRuSvExnvPnPp4
# 4pMadqJpddNQ5EQSviANnqlE0PjlSXcIWiHFtM+YlRpUurm8wWkZus8W8oM3NG6w
# QSbd3lqXTzON1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF4UbFKNOt50MAcN7MmJ4Z
# iQPq1JE3701S88lgIcRWR+3aEUuMMsOI5ljitts++V+wQtaP4xeR0arAVeOGv6wn
# LEHQmjNKqDbUuXKWfpd5OEhfysLcPTLfddY2Z1qJ+Panx+VPNTwAvb6cKmx5Adza
# ROY63jg7B145WPR8czFVoIARyxQMfq68/qTreWWqaNYiyjvrmoI1VygWy2nyMpqy
# 0tg6uLFGhmu6F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjsHPW2obhDLN9OTH0eaHDA
# dwrUAuBcYLso/zjlUlrWrBciI0707NMX+1Br/wd3H3GXREHJuEbTbDJ8WC9nR2Xl
# G3O2mflrLAZG70Ee8PBf4NvZrZCARK+AEEGKMIIHXzCCBUegAwIBAgIQB8JSdCgU
# otar/iTqF+XdLjANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQg
# Q29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMB4XDTIzMDQxNjAw
# MDAwMFoXDTI2MDcwNjIzNTk1OVowZzELMAkGA1UEBhMCUEwxEjAQBgNVBAcMCU1p
# a2/FgsOzdzEhMB8GA1UECgwYUHJ6ZW15c8WCYXcgS8WCeXMgRVZPVEVDMSEwHwYD
# VQQDDBhQcnplbXlzxYJhdyBLxYJ5cyBFVk9URUMwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCUmgeXMQtIaKaSkKvbAt8GFZJ1ywOH8SwxlTus4McyrWmV
# OrRBVRQA8ApF9FaeobwmkZxvkxQTFLHKm+8knwomEUslca8CqSOI0YwELv5EwTVE
# h0C/Daehvxo6tkmNPF9/SP1KC3c0l1vO+M7vdNVGKQIQrhxq7EG0iezBZOAiukNd
# GVXRYOLn47V3qL5PwG/ou2alJ/vifIDad81qFb+QkUh02Jo24SMjWdKDytdrMXi0
# 235CN4RrW+8gjfRJ+fKKjgMImbuceCsi9Iv1a66bUc9anAemObT4mF5U/yQBgAuA
# o3+jVB8wiUd87kUQO0zJCF8vq2YrVOz8OJmMX8ggIsEEUZ3CZKD0hVc3dm7cWSAw
# 8/FNzGNPlAaIxzXX9qeD0EgaCLRkItA3t3eQW+IAXyS/9ZnnpFUoDvQGbK+Q4/bP
# 0ib98XLfQpxVGRu0cCV0Ng77DIkRF+IyR1PcwVAq+OzVU3vKeo25v/rntiXCmCxi
# W4oHYO28eSQ/eIAcnii+3uKDNZrI15P7VxDrkUIc6FtiSvOhwc3AzY+vEfivUkFK
# RqwvSSr4fCrrkk7z2Qe72Zwlw2EDRVHyy0fUVGO9QMuh6E3RwnJL96ip0alcmhKA
# BGoIqSW05nXdCUbkXmhPCTT5naQDuZ1UkAXbZPShKjbPwzdXP2b8I9nQ89VSgQID
# AQABo4ICAzCCAf8wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYD
# VR0OBBYEFHrxaiVZuDJxxEk15bLoMuFI5233MA4GA1UdDwEB/wQEAwIHgDATBgNV
# HSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQw
# OTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAy
# MUNBMS5jcmwwPgYDVR0gBDcwNTAzBgZngQwBBAEwKTAnBggrBgEFBQcCARYbaHR0
# cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMIGUBggrBgEFBQcBAQSBhzCBhDAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFwGCCsGAQUFBzAChlBo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2Rl
# U2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNydDAJBgNVHRMEAjAAMA0GCSqG
# SIb3DQEBCwUAA4ICAQC3EeHXUPhpe31K2DL43Hfh6qkvBHyR1RlD9lVIklcRCR50
# ZHzoWs6EBlTFyohvkpclVCuRdQW33tS6vtKPOucpDDv4wsA+6zkJYI8fHouW6Tqa
# 1W47YSrc5AOShIcJ9+NpNbKNGih3doSlcio2mUKCX5I/ZrzJBkQpJ0kYha/pUST2
# CbE3JroJf2vQWGUiI+J3LdiPNHmhO1l+zaQkSxv0cVDETMfQGZKKRVESZ6Fg61b0
# djvQSx510MdbxtKMjvS3ZtAytqnQHk1ipP+Rg+M5lFHrSkUlnpGa+f3nuQhxDb7N
# 9E8hUVevxALTrFifg8zhslVRH5/Df/CxlMKXC7op30/AyQsOQxHW1uNx3tG1DMgi
# zpwBasrxh6wa7iaA+Lp07q1I92eLhrYbtw3xC2vNIGdMdN7nd76yMIjdYnAn7r38
# wwtaJ3KYD0QTl77EB8u/5cCs3ShZdDdyg4K7NoJl8iEHrbqtooAHOMLiJpiL2i9Y
# n8kQMB6/Q6RMO3IUPLuycB9o6DNiwQHf6Jt5oW7P09k5NxxBEmksxwNbmZvNQ65Z
# n3exUAKqG+x31Egz5IZ4U/jPzRalElEIpS0rgrVg8R8pEOhd95mEzp5WERKFyXhe
# 6nB6bSYHv8clLAV0iMku308rpfjMiQkqS3LLzfUJ5OHqtKKQNMLxz9z185UCszGC
# BlMwggZPAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmluZyBS
# U0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQB8JSdCgUotar/iTqF+XdLjANBglghkgB
# ZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJ
# AzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8G
# CSqGSIb3DQEJBDEiBCC4XZ+ui5Gy7/hjoVu1HR2I1Zzw+KyOp0a3AR65COza0TAN
# BgkqhkiG9w0BAQEFAASCAgAmpkbYmYfP1LSSjoJosjaCPdATDCAGCkToO2G7HlWz
# vH5QlRX0HLKyQyxMF3BJ+u8JFMvsgRZx2qgM0JyRCDKwraO3D8UyY8NLvbjV6irP
# BmvwXee1h0nvejtjolA/hXwGHiXRzDzRIKTn3vtPkGFmnkM278+Bt09YKCrMY8mZ
# siBAYlur5nyVfQE7bOndM7NP86jKtKS1I8VsYAnE80Z2YV6mGfwzs9lNEqWJpvih
# pwitP9orBxlU4CyYy0ILHeG+gfURINQ1v0TtAcGLrAtsnC9WgcStXlZtjjmW6Fcj
# TBypVSXG8FidwK9MbUscVW37e67oQyA75g8bNHLofiDE/xFz5pXcz+ThyQ/SBBIH
# rksFLqrE3mt/Fc16ABi5y5K639N+xh3t4Fau6xHJOVNMI4zjLKLQcffnNzveX+xx
# 6EGzJtEbXlOraw5mmwFrMKh/BE5jKTsZ2Xc3Y1/G8JJnvFYIFwiXRmtJX9UoyB22
# el4FSNz8AspWBLSUYCX6cIJjmnJnHvEwnqlvRQIBZiH5nApPtCWBeK8qiRdqbA31
# 8EAYUdW91+MUltKa0Hf9MeGh8eeukIoxDbV3Cbk8llmsh480aUe4KOXi+ee+JqBE
# XxMa/en8UhAEHwUbuO2ni6YRg3od2xEMulIU7E+7bIpyVaHZa77PK3ZASIjYBOyH
# l6GCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAVEr/OUnQg5
# pr/bP1/lYRYwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0yNDA2MDUxNzE5MzdaMC8GCSqGSIb3DQEJBDEi
# BCDGNI4DP6/1CKCW586Sr0gZSr5eX/PSWIhT0FTheLuczjANBgkqhkiG9w0BAQEF
# AASCAgCJU/EYrGNgU+h5mhP//3zsDZj1w1IBjDeuKCzH7aWmaowlmK8k/wvHQEh4
# c+SKa0VASarLDtGSpjM5S6a8fLe41M2iCaWkks9hhnd74RSSebP3XRZLa2LcHfMd
# bAK0GK9ezsWnbd0NfVAw3hS9aQW5sVs/NsVzUW3Clq6pXzCC0gDph7/a20JEm+vh
# 1D8so6E77cySOjlnoBQ3Nt55t57kGI19NUDgwxEjfwwVA5a6AqUFKiF3Y58A7klS
# 7sVLifsTksowcIqZDwaIVXqUaqONtVKZiLXi6CLOiie65cb2grQqmt3nCeoEBzEl
# 7G+nLd0AHkEpNS49yzR1dnamM6BYw94JFBJYAviujmjtF9s9BwrMjJXE+rt9wpSn
# /+G7d8QSleHehP6g/b8v1Ac7C6nhcCvhacCaccm4WZCyykHIQVqq0IKn1DOGTqSr
# tu4dTXG+daQqLe2FpHV7o3ewyOpXgdZVyNDeh9bM1hZdXtgFafbgs8l2KuyKqhLT
# hgH6D/PjSgoTmymKQlW/JWEMl/YrycoyaxeuQhEJCIDo/cHaGvs2SlpNNSVtklzC
# K+rUu6lJH/FoLZBBksCLBUFeA39KlC/n3InINcwuitIbrcMSpVfYKf7R0sgvvrzP
# f/NdWrp1j4f87uqzbhn2aWXsjxh1Oq19Tpm2ywKvgBde97xl3Q==
# SIG # End signature block

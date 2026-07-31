Extension/RGBAShift.RoughDraft.Extension.ps1
--------------------------------------------

### Synopsis
RGBAShift

---

### Description

Shift R/G/B/A pixels horizontally and/or vertically.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#rgbashift](https://ffmpeg.org/ffmpeg-filters.html#rgbashift)

---

### Examples
> EXAMPLE 1

```PowerShell
$TriangleRGBAShift = @{
    RGBAShift = $true
    RGBAShiftRedHorizontal=-10
    RGBAShiftRedVertical=10
    RGBAShiftGreenHorizontal= 10
    RGBAShiftGreenVertical= -10        
    RGBAShiftBlueVertical=10
}
Show-Media -InputPath ./a.mp4 @TriangleRGBAShift
```

---

### Parameters
#### **RGBAShift**
If set, will use the rgbashift filter

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Switch]`|true    |named   |false        |

#### **RGBAShiftRedHorizontal**
The amount to shift pixel red horizontally

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |1       |false        |rgbashift_rh|

#### **RGBAShiftRedVertical**
The amount to shift pixel red vertically

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |2       |false        |rgbashift_rv|

#### **RGBAShiftGreenHorizontal**
The amount to shift pixel green horizontally

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |3       |false        |rgbashift_gh|

#### **RGBAShiftGreenVertical**
The amount to shift pixel green vertically

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |4       |false        |rgbashift_gv|

#### **RGBAShiftBlueHorizontal**
The amount to shift pixel blue horizontally

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |5       |false        |rgbashift_bh|

#### **RGBAShiftBlueVertical**
The amount to shift pixel blue vertically

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |6       |false        |rgbashift_bv|

#### **RGBAShiftAlphaHorizontal**
The amount to shift pixel alpha horizontally

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |7       |false        |rgbashift_ah|

#### **RGBAShiftAlphaVertical**
The amount to shift pixel alpha vertically

|Type      |Required|Position|PipelineInput|Aliases     |
|----------|--------|--------|-------------|------------|
|`[String]`|false   |8       |false        |rgbashift_av|

---

### Syntax
```PowerShell
Extension/RGBAShift.RoughDraft.Extension.ps1 -RGBAShift [[-RGBAShiftRedHorizontal] <String>] [[-RGBAShiftRedVertical] <String>] [[-RGBAShiftGreenHorizontal] <String>] [[-RGBAShiftGreenVertical] <String>] [[-RGBAShiftBlueHorizontal] <String>] [[-RGBAShiftBlueVertical] <String>] [[-RGBAShiftAlphaHorizontal] <String>] [[-RGBAShiftAlphaVertical] <String>] [<CommonParameters>]
```

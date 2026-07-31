Extension/PseudoColor.RoughDraft.Extension.ps1
----------------------------------------------

### Synopsis
pseudocolor

---

### Description

Make pseudocolored video frames.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#pseudocolor](https://ffmpeg.org/ffmpeg-filters.html#pseudocolor)

---

### Parameters
#### **Pseudocolor**
Make pseudocolored video frames.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Switch]`|true    |named   |false        |

#### **PseudocolorComponent0**
Set component #0 expression

|Type      |Required|Position|PipelineInput|Aliases       |
|----------|--------|--------|-------------|--------------|
|`[String]`|false   |1       |false        |pseudocolor_c0|

#### **PseudocolorComponent1**
set component #1 expression

|Type      |Required|Position|PipelineInput|Aliases       |
|----------|--------|--------|-------------|--------------|
|`[String]`|false   |2       |false        |pseudocolor_c1|

#### **PseudocolorComponent2**
set component #2 expression

|Type      |Required|Position|PipelineInput|Aliases       |
|----------|--------|--------|-------------|--------------|
|`[String]`|false   |3       |false        |pseudocolor_c2|

#### **PseudocolorComponent3**
set component #3 expression

|Type      |Required|Position|PipelineInput|Aliases       |
|----------|--------|--------|-------------|--------------|
|`[String]`|false   |4       |false        |pseudocolor_c3|

#### **PseudoColorBaseIndex**
set which component should be used as a base

|Type     |Required|Position|PipelineInput|Aliases      |
|---------|--------|--------|-------------|-------------|
|`[Int32]`|false   |5       |false        |pseudocolor_i|

#### **PseudocolorOpacity**
Sets the opacity of output colors.

|Type      |Required|Position|PipelineInput|Aliases            |
|----------|--------|--------|-------------|-------------------|
|`[Single]`|false   |6       |false        |pseudocolor_opacity|

#### **PseudoColorPreset**

Valid Values:

* magma
* inferno
* plasma
* viridis
* turbo
* cividis
* range1
* range2
* shadows
* highlights
* solar
* nominal
* preferred
* total
* spectral
* cool
* heat
* fiery
* blues
* green
* helix

|Type      |Required|Position|PipelineInput|Aliases           |
|----------|--------|--------|-------------|------------------|
|`[String]`|false   |7       |false        |pseudocolor_preset|

---

### Syntax
```PowerShell
Extension/PseudoColor.RoughDraft.Extension.ps1 -Pseudocolor [[-PseudocolorComponent0] <String>] [[-PseudocolorComponent1] <String>] [[-PseudocolorComponent2] <String>] [[-PseudocolorComponent3] <String>] [[-PseudoColorBaseIndex] <Int32>] [[-PseudocolorOpacity] <Single>] [[-PseudoColorPreset] <String>] [<CommonParameters>]
```

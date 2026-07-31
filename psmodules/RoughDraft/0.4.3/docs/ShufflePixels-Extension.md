Extension/ShufflePixels.RoughDraft.Extension.ps1
------------------------------------------------

### Synopsis
Shuffles frames in video

---

### Description

Shuffles frames in a video stream.

It's an extension

---

### Parameters
#### **ShufflePixel**
Set the destination indexes of input frames. 
Number of indexes also sets maximal value that each index may have.
’-1’ index have special meaning and that is to drop frame.

|Type      |Required|Position|PipelineInput|Aliases      |
|----------|--------|--------|-------------|-------------|
|`[Switch]`|true    |named   |false        |ShufflePixels|

#### **ShufflePixelDirection**

Valid Values:

* forward
* inverse

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |1       |false        |

#### **ShufflePixelMode**

Valid Values:

* horizontal
* vertical
* block

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |2       |false        |

#### **ShufflePixelWidth**

|Type     |Required|Position|PipelineInput|
|---------|--------|--------|-------------|
|`[Int32]`|false   |3       |false        |

#### **ShufflePixelHeight**

|Type     |Required|Position|PipelineInput|
|---------|--------|--------|-------------|
|`[Int32]`|false   |4       |false        |

#### **ShufflePixelSeed**

|Type     |Required|Position|PipelineInput|
|---------|--------|--------|-------------|
|`[Int32]`|false   |5       |false        |

---

### Syntax
```PowerShell
Extension/ShufflePixels.RoughDraft.Extension.ps1 -ShufflePixel [[-ShufflePixelDirection] <String>] [[-ShufflePixelMode] <String>] [[-ShufflePixelWidth] <Int32>] [[-ShufflePixelHeight] <Int32>] [[-ShufflePixelSeed] <Int32>] [<CommonParameters>]
```

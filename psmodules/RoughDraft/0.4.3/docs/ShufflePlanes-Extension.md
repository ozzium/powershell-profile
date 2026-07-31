Extension/ShufflePlanes.RoughDraft.Extension.ps1
------------------------------------------------

### Synopsis
Shuffles planes in video

---

### Description

Shuffles planes in a video stream.

A plane is essentially a color channel in a video frame.

For example, a video frame may have a red, green, blue, and alpha channel.

It's an extension

---

### Parameters
#### **ShufflePlane**
If set, will shuffle planes

|Type      |Required|Position|PipelineInput|Aliases      |
|----------|--------|--------|-------------|-------------|
|`[Switch]`|true    |named   |false        |ShufflePlanes|

#### **ShuffePlaneMap**
The shuffle map.
This is an array of integers that represent the destination indexes of input planes.

|Type       |Required|Position|PipelineInput|
|-----------|--------|--------|-------------|
|`[Int32[]]`|false   |1       |false        |

---

### Syntax
```PowerShell
Extension/ShufflePlanes.RoughDraft.Extension.ps1 -ShufflePlane [[-ShuffePlaneMap] <Int32[]>] [<CommonParameters>]
```

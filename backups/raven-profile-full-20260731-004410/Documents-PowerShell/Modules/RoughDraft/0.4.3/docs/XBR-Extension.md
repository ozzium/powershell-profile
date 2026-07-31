Extension/XBR.RoughDraft.Extension.ps1
--------------------------------------

### Synopsis
XBR effect

---

### Description

Apply the xBR high-quality magnification filter which is designed for pixel art.

It follows a set of edge-detection rules, see https://forums.libretro.com/t/xbr-algorithm-tutorial/123.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#xbr](https://ffmpeg.org/ffmpeg-filters.html#xbr)

---

### Parameters
#### **XBR**
If set, will pixelate a video using xbr.  Values range from 2 to 4.
The lower the value, the less pixelation blur will be present.

|Type     |Required|Position|PipelineInput|
|---------|--------|--------|-------------|
|`[Int32]`|true    |1       |false        |

---

### Notes
This filter can help smooth the look of pixelart.

It can be combined with the Pixelate effect to provide smoother pixelation within a video, 
or used on its own to provide _very_ slight pixelation effects.

---

### Syntax
```PowerShell
Extension/XBR.RoughDraft.Extension.ps1 [-XBR] <Int32> [<CommonParameters>]
```

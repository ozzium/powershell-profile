Extension/Rate.rd.ext.ps1
-------------------------

### Synopsis
Adjusts the rate of media.

---

### Description

Adjusts the playback rate of media, making it slower or faster.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#setpts](https://ffmpeg.org/ffmpeg-filters.html#setpts)

* [https://ffmpeg.org/ffmpeg-filters.html#atempo](https://ffmpeg.org/ffmpeg-filters.html#atempo)

---

### Parameters
#### **Rate**
The new rate of the media.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Double]`|true    |named   |false        |

#### **TargetTime**
The target time for the media.  
This will adjust the rate to match this target time.

|Type        |Required|Position|PipelineInput|
|------------|--------|--------|-------------|
|`[PSObject]`|true    |named   |false        |

---

### Notes
This uses a variety of filters:

* setpts
* atempo
* asetpts

---

### Syntax
```PowerShell
Extension/Rate.rd.ext.ps1 -Rate <Double> [<CommonParameters>]
```
```PowerShell
Extension/Rate.rd.ext.ps1 -TargetTime <PSObject> [<CommonParameters>]
```

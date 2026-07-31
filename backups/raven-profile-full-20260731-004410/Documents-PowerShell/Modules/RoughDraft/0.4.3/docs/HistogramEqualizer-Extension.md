Extension/HistogramEqualizer.RoughDraft.Extension.ps1
-----------------------------------------------------

### Synopsis
Histogram Equalizer Extension

---

### Description

This filter applies a global color histogram equalization on a per-frame basis.

It can be used to correct video that has a compressed range of pixel intensities.
The filter redistributes the pixel intensities to equalize their distribution across the intensity range.
It may be viewed as an "automatically adjusting contrast filter".
This filter is useful only for correcting degraded or poorly captured source video.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#histogram](https://ffmpeg.org/ffmpeg-filters.html#histogram)

---

### Parameters
#### **HistogramEqualizer**
If set, will display a video histogram

|Type      |Required|Position|PipelineInput|Aliases|
|----------|--------|--------|-------------|-------|
|`[Switch]`|true    |named   |false        |histeq |

#### **HistogramEqualizerStrength**
Determine the amount of equalization to be applied.
As the strength is reduced, the distribution of pixel intensities more-and-more approaches that of the input frame.
The value must be a float number in the range [0,1] and defaults to 0.200.

|Type      |Required|Position|PipelineInput|Aliases        |
|----------|--------|--------|-------------|---------------|
|`[Single]`|false   |1       |false        |histeq_strength|

#### **HistogramEqualizerIntensity**
Set the maximum intensity that can generated and scale the output values appropriately. 
The strength should be set as desired and then the intensity can be limited if needed to avoid washing-out.
The value must be a float number in the range [0,1] and defaults to 0.210.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Single]`|false   |2       |false        |

#### **HistogramEqualizerAntibanding**
Set the antibanding level. 
If enabled the filter will randomly vary the luminance of output pixels by a small amount to avoid banding of the histogram.
Possible values are none, weak or strong.
Valid Values:

* none
* weak
* strong

|Type      |Required|Position|PipelineInput|Aliases        |
|----------|--------|--------|-------------|---------------|
|`[String]`|false   |3       |false        |histeq_antiband|

---

### Syntax
```PowerShell
Extension/HistogramEqualizer.RoughDraft.Extension.ps1 -HistogramEqualizer [[-HistogramEqualizerStrength] <Single>] [[-HistogramEqualizerIntensity] <Single>] [[-HistogramEqualizerAntibanding] <String>] [<CommonParameters>]
```

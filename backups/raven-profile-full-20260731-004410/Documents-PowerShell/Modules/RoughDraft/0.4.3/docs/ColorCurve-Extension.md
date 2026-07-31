Extension/ColorCurve.RoughDraft.Extension.ps1
---------------------------------------------

### Synopsis
ColorCurve Extension

---

### Description

Apply color adjustments using curves.

This filter is similar to the Adobe Photoshop and GIMP curves tools.
Each component (red, green and blue) has its values defined by 
N key points tied from each other using a smooth curve.

The x-axis represents the pixel values from the input frame,
and the y-axis the new pixel values to be set for the output frame.

By default, a component curve is defined by the two points (0;0) and (1;1).
This creates a straight line where each original pixel value is "adjusted" to its own value, 
which means no change to the image.

The filter allows you to redefine these two points and add some more. 
A new curve will be defined to pass smoothly through all these new coordinates.

The new defined points need to be strictly increasing over the x-axis, and their x and y values must be in the [0;1] interval.
The curve is formed by using a natural or monotonic cubic spline interpolation,
depending on the interp option (default: natural).

The natural spline produces a smoother curve in general while the monotonic (pchip) spline guarantees the transitions between the specified points to be monotonic.

If the computed curves happened to go outside the vector spaces, the values will be clipped accordingly.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#curves](https://ffmpeg.org/ffmpeg-filters.html#curves)

---

### Examples
> EXAMPLE 1

```PowerShell
Show-Media -InputPath ./SomeFile.mp4 -ColorCurveRed '0/0.11 .42/.51 1/0.95' -ColorCurveBlue '0/0.22 .49/.44 1/0.8' -ColorCurveGreen '0/0 0.50/0.48 1/1'
```
> EXAMPLE 2

```PowerShell
Show-Media -InputPath ./SomeFile.mp4 -ColorCurvePreset Vintage
```

---

### Parameters
#### **ColorCurve**
If set, will adjust color curves

|Type      |Required|Position|PipelineInput|Aliases                                                |
|----------|--------|--------|-------------|-------------------------------------------------------|
|`[Switch]`|true    |named   |false        |curves<br/>ColourCurve<br/>ColorCurves<br/>ColourCurves|

#### **ColorCurveRed**
The red curve.
This is a sequence of three ratios between 0-1

|Type      |Required|Position|PipelineInput|Aliases                      |
|----------|--------|--------|-------------|-----------------------------|
|`[String]`|false   |1       |false        |curves_red<br/>ColourCurveRed|

#### **ColorCurveBlue**
The blue curve.

|Type      |Required|Position|PipelineInput|Aliases                        |
|----------|--------|--------|-------------|-------------------------------|
|`[String]`|false   |2       |false        |curves_blue<br/>ColourCurveBlue|

#### **ColorCurveGreen**
The green curve.

|Type      |Required|Position|PipelineInput|Aliases                          |
|----------|--------|--------|-------------|---------------------------------|
|`[String]`|false   |3       |false        |curves_green<br/>ColourCurveGreen|

#### **ColorCurveMaster**
The master color curve.
Set the master key points. 
These points will define a second pass mapping.
It is sometimes called a "luminance" or "value" mapping.
It can be used with r, g, b or all since it acts like a post-processing LUT.

|Type      |Required|Position|PipelineInput|Aliases                                                                                                                    |
|----------|--------|--------|-------------|---------------------------------------------------------------------------------------------------------------------------|
|`[String]`|false   |4       |false        |curves_master<br/>ColorCurveLuminance<br/>ColorCurveLuma<br/>ColourCurveLuminance<br/>ColourCurveLuma<br/>ColourCurveMaster|

#### **ColorCurveAll**
Set the key points for all components (not including master).
Can be used in addition to the other key points component options.
In this case, the unset component(s) will fallback on this all setting.

|Type      |Required|Position|PipelineInput|Aliases                      |
|----------|--------|--------|-------------|-----------------------------|
|`[String]`|false   |5       |false        |curves_all<br/>ColourCurveAll|

#### **ColorCurvePhotoshop**
The photoshop color curve file

|Type      |Required|Position|PipelineInput|Aliases                                                                                                                                   |
|----------|--------|--------|-------------|------------------------------------------------------------------------------------------------------------------------------------------|
|`[String]`|false   |6       |false        |curves_psfile<br/>ColorCurvePhotoshopFile<br/>ColorCurvePSFile<br/>ColourCurvePhotoshop<br/>ColourCurvePhotoshopFile<br/>ColourCurvePSFile|

#### **ColorCurvePlot**
The GNU Plotfile used for the color curve.

|Type      |Required|Position|PipelineInput|Aliases                                                                                                                    |
|----------|--------|--------|-------------|---------------------------------------------------------------------------------------------------------------------------|
|`[String]`|false   |7       |false        |curves_plot<br/>ColorCurveGnuPlot<br/>ColorCurvePlotFile<br/>ColourCurvePlot<br/>ColourCurveGnuPlot<br/>ColourCurvePlotFile|

#### **ColorCurvePreset**
The color curve preset.
Valid Values:

* color_negative
* cross_process
* darker
* increase_contrast
* lighter
* linear_contrast
* medium_contrast
* negative
* strong_contrast
* vintage

|Type      |Required|Position|PipelineInput|Aliases                            |
|----------|--------|--------|-------------|-----------------------------------|
|`[String]`|false   |8       |false        |curves_preset<br/>ColourCurvePreset|

#### **ColorCurveInteroplation**
The interpolation used for the color curve.
Valid Values:

* natural
* pchip

|Type      |Required|Position|PipelineInput|Aliases                                    |
|----------|--------|--------|-------------|-------------------------------------------|
|`[String]`|false   |9       |false        |curves_interop<br/>ColourCurveInterpolation|

---

### Syntax
```PowerShell
Extension/ColorCurve.RoughDraft.Extension.ps1 -ColorCurve [[-ColorCurveRed] <String>] [[-ColorCurveBlue] <String>] [[-ColorCurveGreen] <String>] [[-ColorCurveMaster] <String>] [[-ColorCurveAll] <String>] [[-ColorCurvePhotoshop] <String>] [[-ColorCurvePlot] <String>] [[-ColorCurvePreset] <String>] [[-ColorCurveInteroplation] <String>] [<CommonParameters>]
```

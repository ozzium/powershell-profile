Extension/SelectiveColor.RoughDraft.Extension.ps1
-------------------------------------------------

### Synopsis
Selective Color Extension

---

### Description

Adjust cyan, magenta, yellow and black (CMYK) to certain ranges of colors
(such as "reds", "yellows", "greens", "cyans", ...). 

The adjustment range is defined by the "purity" of the color 
(that is, how saturated it already is).

This filter is similar to the Adobe Photoshop Selective Color tool.

---

### Related Links
* [https://ffmpeg.org/ffmpeg-filters.html#selectivecolor](https://ffmpeg.org/ffmpeg-filters.html#selectivecolor)

---

### Parameters
#### **SelectiveColor**
If set, will use the selective color filter

|Type      |Required|Position|PipelineInput|Aliases        |
|----------|--------|--------|-------------|---------------|
|`[Switch]`|true    |named   |false        |SelectiveColour|

#### **SelectiveColorCorrectionMethod**
The Select color correction method.
Can be absolute or relative.
Valid Values:

* absolute
* relative

|Type      |Required|Position|PipelineInput|Aliases                                                             |
|----------|--------|--------|-------------|--------------------------------------------------------------------|
|`[String]`|false   |1       |false        |SelectiveColourCorrectionMethod<br/>selectivecolor_correction_method|

#### **SelectiveColorRed**
Adjustments for red pixels (pixels where the red component is the maximum)

|Type      |Required|Position|PipelineInput|Aliases                                                                                  |
|----------|--------|--------|-------------|-----------------------------------------------------------------------------------------|
|`[String]`|false   |2       |false        |SelectiveColourRed<br/>SelectiveColourReds<br/>selectivecolor_reds<br/>SelectiveColorReds|

#### **SelectiveColorBlue**
Adjustments for blue pixels (pixels where the blue component is the maximum)

|Type      |Required|Position|PipelineInput|Aliases                                                                                      |
|----------|--------|--------|-------------|---------------------------------------------------------------------------------------------|
|`[String]`|false   |3       |false        |SelectiveColourBlue<br/>SelectiveColourBlues<br/>selectivecolor_Blues<br/>SelectiveColorBlues|

#### **SelectiveColorYellow**
Adjustments for yellow pixels (pixels where the yellow component is the maximum)

|Type      |Required|Position|PipelineInput|Aliases                                                                                              |
|----------|--------|--------|-------------|-----------------------------------------------------------------------------------------------------|
|`[String]`|false   |4       |false        |SelectiveColourYellow<br/>SelectiveColourYellows<br/>selectivecolor_yellows<br/>SelectiveColorYellows|

#### **SelectiveColorCyan**
Adjustments for cyan pixels (pixels where the cyan component is the maximum)

|Type      |Required|Position|PipelineInput|Aliases                                                                                      |
|----------|--------|--------|-------------|---------------------------------------------------------------------------------------------|
|`[String]`|false   |5       |false        |SelectiveColourCyan<br/>SelectiveColourCyans<br/>selectivecolor_cyans<br/>SelectiveColorCyans|

#### **SelectiveColorMagenta**
Adjustments for magenta pixels (pixels where the magenta component is the maximum)

|Type      |Required|Position|PipelineInput|Aliases                                                                                                  |
|----------|--------|--------|-------------|---------------------------------------------------------------------------------------------------------|
|`[String]`|false   |6       |false        |SelectiveColourMagenta<br/>SelectiveColourMagentas<br/>selectivecolor_magentas<br/>SelectiveColorMagentas|

#### **SelectiveColorWhite**
Adjustments for white pixels (pixels where all components are greater than 128)

|Type      |Required|Position|PipelineInput|Aliases                                                                                          |
|----------|--------|--------|-------------|-------------------------------------------------------------------------------------------------|
|`[String]`|false   |7       |false        |SelectiveColourWhite<br/>SelectiveColourWhites<br/>selectivecolor_whites<br/>SelectiveColorWhites|

#### **SelectiveColorBlack**
Adjustments for black pixels (pixels where all components are lesser than 128)

|Type      |Required|Position|PipelineInput|Aliases                                                                                          |
|----------|--------|--------|-------------|-------------------------------------------------------------------------------------------------|
|`[String]`|false   |8       |false        |SelectiveColourBlack<br/>SelectiveColourBlacks<br/>selectivecolor_blacks<br/>SelectiveColorBlacks|

#### **SelectiveColorNeutral**
Adjustments for all pixels except pure black and pure white

|Type      |Required|Position|PipelineInput|Aliases                                                                                                  |
|----------|--------|--------|-------------|---------------------------------------------------------------------------------------------------------|
|`[String]`|false   |9       |false        |SelectiveColourNeutral<br/>SelectiveColourNeutrals<br/>selectivecolor_neutrals<br/>SelectiveColorNeutrals|

#### **SelectiveColorPSFile**
Specify a Photoshop selective color file (.asv) to import the settings from.

|Type      |Required|Position|PipelineInput|Aliases                                                                                                         |
|----------|--------|--------|-------------|----------------------------------------------------------------------------------------------------------------|
|`[String]`|false   |10      |false        |SelectiveColourPSFile<br/>SelectiveColourPhotoshopFile<br/>selectivecolor_psfile<br/>SelectiveColorPhotoshopFile|

---

### Syntax
```PowerShell
Extension/SelectiveColor.RoughDraft.Extension.ps1 -SelectiveColor [[-SelectiveColorCorrectionMethod] <String>] [[-SelectiveColorRed] <String>] [[-SelectiveColorBlue] <String>] [[-SelectiveColorYellow] <String>] [[-SelectiveColorCyan] <String>] [[-SelectiveColorMagenta] <String>] [[-SelectiveColorWhite] <String>] [[-SelectiveColorBlack] <String>] [[-SelectiveColorNeutral] <String>] [[-SelectiveColorPSFile] <String>] [<CommonParameters>]
```

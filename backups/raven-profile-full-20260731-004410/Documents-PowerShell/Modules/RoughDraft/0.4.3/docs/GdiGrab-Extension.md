Extension/GdiGrab.RoughDraft.Extension.ps1
------------------------------------------

### Synopsis
GDIGrab Extension

---

### Description

The GDIGrab extension lets you use GDI input devices

---

### Related Links
* [https://ffmpeg.org/ffmpeg-devices.html#gdigrab](https://ffmpeg.org/ffmpeg-devices.html#gdigrab)

---

### Examples
> EXAMPLE 1

```PowerShell
Show-Media -GDIGrab # Shows a recursive grab of the current desktop
```

---

### Parameters
#### **GdiGrab**
If set, will use `gdigrab` as the input type

|Type      |Required|Position|PipelineInput|Aliases|
|----------|--------|--------|-------------|-------|
|`[Switch]`|true    |named   |false        |gdi    |

#### **GdiDevice**
The GDI device to use.  This can be:
* desktop - The entire desktop
* title=WINDOW_NAME - A window with the specified title
* hwnd=WINDOW_HANDLE - A window with the specified handle
If not specified, defaults to "desktop"

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |1       |false        |

#### **GdiWindowTitle**
The title of the window to capture.  This is ignored if -GdiDevice is set.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |2       |false        |

#### **GdiFramerate**
The framerate to capture at.  If not specified, defaults to 30.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |3       |false        |

#### **GdiOffsetX**
The X offset to start capturing at.  If not specified, defaults to 0.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |4       |false        |

#### **GdiOffsetY**
The Y offset to start capturing at.  If not specified, defaults to 0.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |5       |false        |

#### **GdiVideoSize**
The video size to capture.  This should be in the format of a well known size (like vga) or resolution.  
If not specified, defaults to the full size of the desktop or window.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[String]`|false   |6       |false        |

#### **GdiHideMouse**
If set, will hide the mouse cursor in the capture.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Switch]`|false   |named   |false        |

#### **GdiShowRegion**
If set, will show the region being captured.  This is useful for debugging.

|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Switch]`|false   |named   |false        |

---

### Syntax
```PowerShell
Extension/GdiGrab.RoughDraft.Extension.ps1 -GdiGrab [[-GdiDevice] <String>] [[-GdiWindowTitle] <String>] [[-GdiFramerate] <String>] [[-GdiOffsetX] <String>] [[-GdiOffsetY] <String>] [[-GdiVideoSize] <String>] [-GdiHideMouse] [-GdiShowRegion] [<CommonParameters>]
```

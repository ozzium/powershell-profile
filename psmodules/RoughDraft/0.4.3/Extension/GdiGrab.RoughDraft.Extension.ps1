<#
.Synopsis
    GDIGrab Extension
.Description
    The GDIGrab extension lets you use GDI input devices
.EXAMPLE
    Show-Media -GDIGrab # Shows a recursive grab of the current desktop
.LINK
    https://ffmpeg.org/ffmpeg-devices.html#gdigrab
#>
[Management.Automation.Cmdlet("Receive","Media")]
[Management.Automation.Cmdlet("Send","Media")]
[Management.Automation.Cmdlet("Show","Media")]
param(
# If set, will use `gdigrab` as the input type
[Parameter(Mandatory)]
[Alias('gdi')]
[switch]
$GdiGrab,

# The GDI device to use.  This can be:
# * desktop - The entire desktop
# * title=WINDOW_NAME - A window with the specified title
# * hwnd=WINDOW_HANDLE - A window with the specified handle
# If not specified, defaults to "desktop"
[string]
$GdiDevice = "desktop",

# The title of the window to capture.  This is ignored if -GdiDevice is set.
[string]
$GdiWindowTitle,

# The framerate to capture at.  If not specified, defaults to 30.
[string]
$GdiFramerate,

# The X offset to start capturing at.  If not specified, defaults to 0.
[string]
$GdiOffsetX,

# The Y offset to start capturing at.  If not specified, defaults to 0.
[string]
$GdiOffsetY,

# The video size to capture.  This should be in the format of a well known size (like vga) or resolution.  
# If not specified, defaults to the full size of the desktop or window.
[string]
$GdiVideoSize,

# If set, will hide the mouse cursor in the capture.
[switch]
$GdiHideMouse,

# If set, will show the region being captured.  This is useful for debugging.
[switch]
$GdiShowRegion
)

if (-not $GdiDevice) { $GdiDevice = "desktop" }

$deviceString = @(
    if ($GdiWindowTitle) {"title=$GdiWindowTitle"}
    elseif ($GdiDevice) { $GdiDevice } 
    else {"desktop"}    
) -join ':'

'-f'
'gdigrab'
'-i'
$deviceString
if ($GdiFramerate) {
    '-framerate'
    $GdiFramerate
}
if ($GdiOffsetX -or $GdiOffsetY) {
    '-offset_x'
    if ($GdiOffsetX) { $GdiOffsetX } else { 0 }
    '-offset_y'
    if ($GdiOffsetY) { $GdiOffsetY } else { 0 }
}
if ($GdiVideoSize) {
    '-video_size'
    $GdiVideoSize
}
if ($GdiHideMouse) {
    '-draw_mouse'
    '0'
}

if ($GdiShowRegion) {
    '-show_region'
    1
}
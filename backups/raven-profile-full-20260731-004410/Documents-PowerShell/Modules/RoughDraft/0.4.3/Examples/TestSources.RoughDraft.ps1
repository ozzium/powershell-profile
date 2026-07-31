$OutputDirectory = $PSScriptRoot

Push-Location $OutputDirectory

$global:ErrorActionPreference = $errorActionPreference = 'continue'

New-Media -TestSource rgbtestsrc -OutputPath "RGB.TestSource.png" -FrameCount 1 -Resolution 1920x1080
New-Media -TestSource pal100bars -OutputPath "PAL100.TestSource.png" -FrameCount 1 -Resolution 1920x1080
New-Media -TestSource pal75bars -OutputPath "PAL75.TestSource.png" -FrameCount 1 -Resolution 1920x1080
New-Media -TestSource yuvtestsrc -OutputPath "YUV.TestSource.png" -FrameCount 1 -Resolution 1920x1080
New-Media -TestSource testsrc2 "TestSource2.png" -FrameCount 1 -Resolution 1920x1080
New-Media -TestSource testsrc2 "TestSource2.mp4" -Duration "00:00:01" -Resolution 1920x1080

Pop-Location
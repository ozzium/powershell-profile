---

title: RoughDraft 0.4.1
sourceURL: https://github.com/StartAutomating/RoughDraft/releases/tag/v0.4.1
tag: release
---
> Like It? [Star It](https://github.com/StartAutomating/RoughDraft)
> Love It? [Support It](https://github.com/sponsors/StartAutomating)

## 0.4.1

* RoughDraft in Docker
  * Added Dockerfile ( [#251](https://github.com/StartAutomating/RoughDraft/issues/251) )
  * Publishing to https://ghcr.io/startautomating/roughdraft ( [#252](https://github.com/StartAutomating/RoughDraft/issues/252) )
    * `Container.init.ps1` initializes the container ( [#277](https://github.com/StartAutomating/RoughDraft/issues/277) )
    * `Container.start.ps1` is the entry point ( [#278](https://github.com/StartAutomating/RoughDraft/issues/278) )
    * `Container.stop.ps1` is the exit point ( [#279](https://github.com/StartAutomating/RoughDraft/issues/279) )
  * RoughDraft Docker on Kali ( [#311](https://github.com/StartAutomating/RoughDraft/issues/311) )

* Massive Metadata improvements!
  * Get-Media now stores Metadata within '.Metadata' ( [#224](https://github.com/StartAutomating/RoughDraft/issues/224) )
  * Media Formatting ( [#30](https://github.com/StartAutomating/RoughDraft/issues/30) )
  * Gettable / Settable properties on every `Get-Media` result:
    * RoughDraft.Media.AspectRatio ( [#217](https://github.com/StartAutomating/RoughDraft/issues/217) )
    * RoughDraft.Media.PixelFormat ( [#218](https://github.com/StartAutomating/RoughDraft/issues/218) )
    * RoughDraft.Media.Video/AudioBitrate ( [#216](https://github.com/StartAutomating/RoughDraft/issues/216), [#219](https://github.com/StartAutomating/RoughDraft/issues/219) )
    * RoughDraft.Media.FilePath/FileName ( [#220](https://github.com/StartAutomating/RoughDraft/issues/220), [#221](https://github.com/StartAutomating/RoughDraft/issues/221) )
    * RoughDraft.Media.get_MediaType ( [#212](https://github.com/StartAutomating/RoughDraft/issues/212) )
  * Media metadata can be set with script properties
    * RoughDraft.Media.get/set_Artist ( [#249](https://github.com/StartAutomating/RoughDraft/issues/249) )
    * RoughDraft.Media.get/set_Date ( [#271](https://github.com/StartAutomating/RoughDraft/issues/271) )
    * RoughDraft.Media.get/set_Year ( [#248](https://github.com/StartAutomating/RoughDraft/issues/248) )
    * RoughDraft.Media.get/set_Track ( [#247](https://github.com/StartAutomating/RoughDraft/issues/247) )
    * RoughDraft.Media.get/set_Synopsis ( [#246](https://github.com/StartAutomating/RoughDraft/issues/246) )
    * RoughDraft.Media.get/set_Subtitle ( [#245](https://github.com/StartAutomating/RoughDraft/issues/245) )
    * RoughDraft.Media.get/set_Publisher/Show ( [#243](https://github.com/StartAutomating/RoughDraft/issues/243), [#244](https://github.com/StartAutomating/RoughDraft/issues/244) )
    * RoughDraft.Media.get/set_Network/Producer ( [#241](https://github.com/StartAutomating/RoughDraft/issues/241), [#242](https://github.com/StartAutomating/RoughDraft/issues/242) )
    * RoughDraft.Media.get/set_Mood ( [#240](https://github.com/StartAutomating/RoughDraft/issues/240) )
    * RoughDraft.Media.get/set_Location ( Fixes [#260](https://github.com/StartAutomating/RoughDraft/issues/260) )
    * RoughDraft.Media.get/set_Lyric ( [#239](https://github.com/StartAutomating/RoughDraft/issues/239) )
    * RoughDraft.Media.get/set_InitialKey ( [#238](https://github.com/StartAutomating/RoughDraft/issues/238) )
    * RoughDraft.Media.get/set_Genre/Grouping ( [#236](https://github.com/StartAutomating/RoughDraft/issues/236), [#237](https://github.com/StartAutomating/RoughDraft/issues/237) )
    * RoughDraft.Media.get/set_EpisodeId ( [#235](https://github.com/StartAutomating/RoughDraft/issues/235) )
    * RoughDraft.Media.get/set_Disc ( [#234](https://github.com/StartAutomating/RoughDraft/issues/234) )
    * RoughDraft.Media.get/set_Description ( [#233](https://github.com/StartAutomating/RoughDraft/issues/233) )
    * RoughDraft.Media.get/set_CreationTime ( [#232](https://github.com/StartAutomating/RoughDraft/issues/232) )
    * RoughDraft.Media.get/set_Comment/Composer ( [#229](https://github.com/StartAutomating/RoughDraft/issues/229), [#230](https://github.com/StartAutomating/RoughDraft/issues/230) )
    * RoughDraft.Media.get/set_Copyright ( [#231](https://github.com/StartAutomating/RoughDraft/issues/231) )
    * RoughDraft.Media.get/set_Comment ( [#229](https://github.com/StartAutomating/RoughDraft/issues/229) )
    * RoughDraft.Media.get/set_BPM ( [#228](https://github.com/StartAutomating/RoughDraft/issues/228) )
    * RoughDraft.Media.get/set_Album/AlbumArtist ( [#226](https://github.com/StartAutomating/RoughDraft/issues/226), [#227](https://github.com/StartAutomating/RoughDraft/issues/227) )
    * RoughDraft.Media.get/set_Title ( [#225](https://github.com/StartAutomating/RoughDraft/issues/225) )

* Edit-Media -Offset ( [#299](https://github.com/StartAutomating/RoughDraft/issues/299) )
* Convert/Edit/New-Media -FrameCount ([#303](https://github.com/StartAutomating/RoughDraft/issues/303))

* New Commands:
  * Repair-Media ( [#208](https://github.com/StartAutomating/RoughDraft/issues/208) )
  * Mount-RoughDraft ( [#288](https://github.com/StartAutomating/RoughDraft/issues/288) )
  * Dismount-RoughDraft ( [#289](https://github.com/StartAutomating/RoughDraft/issues/289) )

* New Extensions:
  * ChromaHold ( [#190](https://github.com/StartAutomating/RoughDraft/issues/190) )
  * Crossfade ([#18](https://github.com/StartAutomating/RoughDraft/issues/18))
  * ExtractSubtitle ([#186](https://github.com/StartAutomating/RoughDraft/issues/186))
  * FixPlaylistPath ( [#209](https://github.com/StartAutomating/RoughDraft/issues/209) )
  * GdiGrab ( [#313](https://github.com/StartAutomating/RoughDraft/issues/313) )
  * GifPalette ([#71](https://github.com/StartAutomating/RoughDraft/issues/71))  
  * NoLogo ([#17](https://github.com/StartAutomating/RoughDraft/issues/17))
  * OffsetAudio ( [#297](https://github.com/StartAutomating/RoughDraft/issues/297) )
  * OffsetVideo ( [#298](https://github.com/StartAutomating/RoughDraft/issues/298) )
  * PseudoColor ( [#305](https://github.com/StartAutomating/RoughDraft/issues/305) )  
  * ShufflePixels ( [#304](https://github.com/StartAutomating/RoughDraft/issues/304) )
  * ShufflePlanes ( [#306](https://github.com/StartAutomating/RoughDraft/issues/306) )
  * SplitEqually ( [#197](https://github.com/StartAutomating/RoughDraft/issues/197) )  
  * SwapRect ( [#191](https://github.com/StartAutomating/RoughDraft/issues/191) )
  * Vibrance ( [#192](https://github.com/StartAutomating/RoughDraft/issues/192) )
  
* Fixes / Improvements
  * Fixing -VideoCodec ([#189](https://github.com/StartAutomating/RoughDraft/issues/189))
  * YouTube downloader
    * Swapping YouTube Downloader to `yt-dlp` ( [#196](https://github.com/StartAutomating/RoughDraft/issues/196) )
    * Adding additional options ([#257](https://github.com/StartAutomating/RoughDraft/issues/257))
  * Join-Media should not always transcode ( [#195](https://github.com/StartAutomating/RoughDraft/issues/195) )
  * Quoting Fixes
    * Set-Media quoting ( [#222](https://github.com/StartAutomating/RoughDraft/issues/222) )
    * Set-Media -AlbumArt quoting ( [#255](https://github.com/StartAutomating/RoughDraft/issues/255) )
    * Mirror Extension Overquoting ( [#301](https://github.com/StartAutomating/RoughDraft/issues/301) )
    * Pixelate Extension Overquoting ( [#300](https://github.com/StartAutomating/RoughDraft/issues/300) )
    * Rotate filter quoting fix ( [#259](https://github.com/StartAutomating/RoughDraft/issues/259) )
  * Get-Media -VolumeLevel ( [#254](https://github.com/StartAutomating/RoughDraft/issues/254) )
  * Edit-Media removing default -PixelFormat ( Fixes [#302](https://github.com/StartAutomating/RoughDraft/issues/302) )
  * Removing pixel format from visualizers ( [#312](https://github.com/StartAutomating/RoughDraft/issues/312) )
  * Workflow fixes
    * RoughDraft PublishTestResults workflow fix ( [#310](https://github.com/StartAutomating/RoughDraft/issues/310) )
  
* Module Features:
  * Mounting `RoughDraft:` ( [#201](https://github.com/StartAutomating/RoughDraft/issues/201) )
  * Exporting `$RoughDraft` ( [#202](https://github.com/StartAutomating/RoughDraft/issues/202) )
* Organization ([#203](https://github.com/StartAutomating/RoughDraft/issues/203), [#204](https://github.com/StartAutomating/RoughDraft/issues/204), [#205](https://github.com/StartAutomating/RoughDraft/issues/205), [#206](https://github.com/StartAutomating/RoughDraft/issues/206))
  * Moving Build definitions into /Build ( [#204](https://github.com/StartAutomating/RoughDraft/issues/204) )
  * Moving Functions into /Commands ( [#205](https://github.com/StartAutomating/RoughDraft/issues/205) )
  * Moving Formatting and Types into /Types ([#206](https://github.com/StartAutomating/RoughDraft/issues/206))
* Community Standards
  * Added `CODE_OF_CONDUCT.md` ([#293](https://github.com/StartAutomating/RoughDraft/issues/293))
  * Added `CONTRIBUTING.md` ([#294](https://github.com/StartAutomating/RoughDraft/issues/294))
  * Added `SECURITY.md` ([#295](https://github.com/StartAutomating/RoughDraft/issues/295))
* Action Improvements ( [#282](https://github.com/StartAutomating/RoughDraft/issues/282), [#283](https://github.com/StartAutomating/RoughDraft/issues/283), [#284](https://github.com/StartAutomating/RoughDraft/issues/284) )
  * RoughDraft action no longer uses set-output ( [#281](https://github.com/StartAutomating/RoughDraft/issues/281) )
  * RoughDraft action summarization ( [#282](https://github.com/StartAutomating/RoughDraft/issues/282) )
  * RoughDraft action refactored into internal functions ( [#283](https://github.com/StartAutomating/RoughDraft/issues/283) )
  * Using actorID in checkins ([#284](https://github.com/StartAutomating/RoughDraft/issues/284))
  * Supporting -InstallModule ([#285](https://github.com/StartAutomating/RoughDraft/issues/285))

---

Additional Changes in [CHANGELOG](https://github.com/StartAutomating/RoughDraft/blob/main/CHANGELOG.md)

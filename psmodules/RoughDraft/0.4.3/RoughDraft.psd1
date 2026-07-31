@{
    CompanyName='Start-Automating'
    ModuleVersion='0.4.3'
    ModuleToProcess='RoughDraft.psm1'
    GUID='c192ebbf-57a3-493e-bc82-da7553038794'
    Description='A Fun PowerShell Module for Multimedia'
    Copyright='2011-2026 Start-Automating'
    Author='James Brundage'
    FormatsToProcess  = 'RoughDraft.format.ps1xml'
    TypesToProcess = 'RoughDraft.types.ps1xml'
    PrivateData = @{
        PSData = @{
            Tags = 'Media', 'Multimedia','Audio', 'Video', 'FFMpeg', 'mp3','mp4','jpg','png'
            ProjectURI = 'https://github.com/StartAutomating/RoughDraft'
            LicenseURI = 'https://github.com/StartAutomating/RoughDraft/blob/main/LICENSE'
            IconURI    = 'https://github.com/StartAutomating/RoughDraft/blob/main/Assets/RoughDraft.png'
            ReleaseNotes = @'
## 0.4.3

* Fixing Rate Extension (#327)
* Adding -TargetTime to Rate extension (#328)
* Adding RGBAShift Extension (#329)

---

Additional Changes in [CHANGELOG](https://github.com/StartAutomating/RoughDraft/blob/main/CHANGELOG.md)
'@
        }
        Taglines = @(
            'A Fun PowerShell Module for Multimedia',
            'FFMpeg made easier with PowerShell',
            'Manipulate Audio and Video with PowerShell',
            'PowerShell and FFMpeg, together at last'
        )
        
    }
}

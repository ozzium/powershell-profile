@{
    RootModule            = 'Markdown.psm1'
    ModuleVersion         = '1.2.5'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '00f4c8ff-1f36-479c-8904-9aef2bbec4be'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module to handle markdown'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Set-MarkdownCodeBlock'
        'Set-MarkdownDetails'
        'Set-MarkdownParagraph'
        'Set-MarkdownSection'
        'Set-MarkdownTable'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Block'
        'CodeBlock'
        'CodeFence'
        'Details'
        'Fence'
        'Header'
        'Heading'
        'Paragraph'
        'Section'
        'Table'
    )
    ModuleList            = @()
    FileList              = @(
        'Markdown.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'Linux'
                'MacOS'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Markdown/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Markdown'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Markdown/main/icon/icon.png'
        }
    }
}

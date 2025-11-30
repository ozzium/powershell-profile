# ===============================
#   RAVEN INLINE AI SUGGESTIONS
# ===============================

function Invoke-RavenInlineSuggestion {
    param([string]$CurrentLine)

    if (-not $CurrentLine -or -not $CurrentLine.Trim()) { return $null }

    $prompt = @"
You are Raven, the AI muse embedded inside this terminal.
Complete or improve the following PowerShell command.
Return ONLY the improved command — no commentary.

Current line:
$CurrentLine
"@

    $resp = Invoke-RavenCore -Prompt $prompt
    if (-not $resp) { return $null }

    $first = $resp -split "`n" | Select-Object -First 1
    return ($first.Trim())
}

Set-PSReadLineKeyHandler -Key "Ctrl+Space" -ScriptBlock {
    param($key, $arg)

    $line = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $s = Invoke-RavenInlineSuggestion -CurrentLine $line

    if ($s) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replaces($line, $s)
    }
}

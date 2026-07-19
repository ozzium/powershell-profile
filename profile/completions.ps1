# Custom completions for git / npm / deno

$script:PSProfile_CustomCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $customCompletions = @{
        'git'  = @('status','add','commit','push','pull','clone','checkout')
        'npm'  = @('install','start','run','test','build')
        'deno' = @('run','compile','bundle','test','lint','fmt','cache','info','doc','upgrade')
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_,$_, 'ParameterValue', $_)
            }
    }
}

Register-ArgumentCompleter -Native -CommandName git,npm,deno -ScriptBlock $script:PSProfile_CustomCompleter

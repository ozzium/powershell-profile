Function Load-Powershell_7{

    function New-OutOfProcRunspace {
        param($ProcessId)

        $connectionInfo = New-Object -TypeName System.Management.Automation.Runspaces.NamedPipeConnectionInfo -ArgumentList @($ProcessId)

        $TypeTable = [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles()

        #$Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateOutOfProcessRunspace($connectionInfo,$Host,$TypeTable)
        $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($connectionInfo,$Host,$TypeTable)

        $Runspace.Open()
        $Runspace
    }

    $Process = Start-Process PWSH -ArgumentList @("-NoExit") -PassThru -WindowStyle Hidden

    $Runspace = New-OutOfProcRunspace -ProcessId $Process.Id

    $Host.PushRunspace($Runspace)
}
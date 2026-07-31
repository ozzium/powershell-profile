param(
[string[]]
$ListenerPrefix = @('http://localhost:8279/')
)

# If we're running in a container and the listener prefix is not http://*:80/,
if ($env:IN_CONTAINER -and $listenerPrefix -ne 'http://*:80/') {
    # then set the listener prefix to http://*:80/ (listen to all incoming requests on port 80).
    $listenerPrefix = 'http://*:80/'
}

# If we do not have a global RoughDraftHttpListener object,   
if (-not $global:RoughDraftHttpListener) {
    # then create a new HttpListener object.
    $global:RoughDraftHttpListener = [Net.HttpListener]::new()
    # and add the listener prefixes.
    foreach ($prefix in $ListenerPrefix) {
        if ($global:RoughDraftHttpListener.Prefixes -notcontains $prefix) {
            $global:RoughDraftHttpListener.Prefixes.Add($prefix)
        }    
    }
}

# The RoughDraftServerJob will start the HttpListener and listen for incoming requests.
$script:RoughDraftServerJob = 
    Start-ThreadJob -Name RoughDraftServer -ScriptBlock {
        param([Net.HttpListener]$Listener)
        # Start the listener.
        try { $Listener.Start() }
        # If the listener cannot start, write a warning and return.
        catch { Write-Warning "Could not start listener: $_" ;return }
        # While the listener is running,
        while ($true) {
            # get the context of the incoming request.
            $listener.GetContextAsync() |
                . { process {
                    # by enumerating the result, we effectively 'await' the result
                    $context = $(try { $_.Result } catch { $_ })
                    # and can just return a context object
                    $context
                } }
        }    
    } -ArgumentList $global:RoughDraftHttpListener

# If PowerShell is exiting, close the HttpListener.
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $global:RoughDraftHttpListener.Close()
}

# Keep track of the creation time of the RoughDraftServerJob.
$RoughDraftServerJob | Add-Member -MemberType NoteProperty Created -Value ([DateTime]::now) -Force
# Jobs have .Output, which in turn has a .DataAdded event.
# this allows us to have an event-driven webserver.
$subscriber = Register-ObjectEvent -InputObject $RoughDraftServerJob.Output -EventName DataAdded -Action {
    $context = $event.Sender[$event.SourceEventArgs.Index]
    # When a context is added to the output, create a new event with the context and the time.
    New-Event -SourceIdentifier HTTP.Request -MessageData ($event.MessageData + [Ordered]@{
        Context = $context        
        Time    = [DateTime]::Now
    })
} -SupportEvent -MessageData ([Ordered]@{Job = $RoughDraftServerJob})
# Add the subscriber to the RoughDraftServerJob (just in case).
$RoughDraftServerJob | Add-Member -MemberType NoteProperty OutputSubscriber -Value $subscriber -Force

# Our custom 'HTTP.Request' event will process the incoming requests.
Register-EngineEvent -SourceIdentifier HTTP.Request -Action {
    $context = $event.MessageData.Context
    # Get the request and response objects from the context.
    $request, $response = $context.Request, $context.Response
    # Do everything from here on in a try/catch block, so errors don't hurt the server.
    try {
        # Forget favicons.
        if ($request.Url.LocalPath -eq '/favicon.ico') {
            $response.StatusCode = 404
            $response.Close()
            return
        }
        $outputMessage = 
            if ($RoughDraft.Serve.ScriptBlock) {
                # If the RoughDraft.Serve function exists, call it with the request and response objects.
                & $RoughDraft.Serve -Request $request
            } else {
                "Nothing to Serve"
            }

        if ($outputMessage.ContentType) {
            # If the output message has a ContentType, set the response content type.
            $response.ContentType = $outputMessage.ContentType
        }
        $headerHashtableKeys = 'Headers', 'Header'
        foreach ($key in $headerHashtableKeys) {
            if ($outputMessage.$key -is [Collections.IDictionary]) {
                # If the output message has a Headers or Header key, set the response headers.
                foreach ($headerKey in $outputMessage[$key].Keys) {
                    $response.Headers.Add($headerKey, $outputMessage[$key][$headerKey])
                }
            }
        }

        $outputBuffer = 
            if ($outputMessage -is [string]) {
                # At this point our output message is a string, so we can convert it to bytes.
                $OutputEncoding.GetBytes($outputMessage)
            } 
            elseif ($outputMessage -is [Collections.IDictionary]) {
                
            } elseif ($(
                $outputMessageBytes = $outputMessage -as [byte[]]
                $outputMessageBytes
            )) {
                $outputMessageBytes
            }
        
        if ($outputBuffer) {
            # and write the output buffer to the response stream.
            $response.OutputStream.Write($outputBuffer, 0, $outputBuffer.Length)
        }
        
        # and we're done.
        $response.Close()
    } catch {
        # If anything goes wrong, write a warning
        # (this will be written to the console, making it easier for an admin to see what went wrong).
        Write-Warning "Error processing request: $_"
    }    
}

# Write a message to the console that the dice server has started.
@{"Message" = "RoughDraft server started on $listenerPrefix @ $([datetime]::now.ToString('o'))"} | ConvertTo-Json | Out-Host

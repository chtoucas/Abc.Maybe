# https://github.com/MicrosoftDocs/PowerShell-Docs/issues/1583

#Requires -Version 7

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "eng\abc.ps1")

function raise {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    if ($PSBoundParameters['ErrorAction']) {
        $exitOnError = $PSBoundParameters['ErrorAction'] -eq "Stop" ? $true : $false
    }
    else {
        $exitOnError = $false
    }

    # The first element is for "raise", and the last one is useless, let's remove them.
    $stack = Get-PSCallStack
    $c = $stack.Count
    if ($c -gt 2)     { $message += "`n  " + ($stack[1..($c-2)] -join "`n  ") }
    elseif ($c -eq 2) { $message += "`n  " + $stack[1] }

    if ($exitOnError) {
        $Script:___Died = $true

        $Host.UI.WriteErrorLine($message)

        exit 1
    }
    else {
        $Script:___Warned = $true

        Write-Warning $message
    }
}

function hey {
    [CmdletBinding()]
    param()

    $onError = $PSBoundParameters['ErrorAction'] ?? $ErrorActionPreference

    raise "I carped" -ErrorAction:$onError
}

try {
    ___BEGIN___

    hey -ErrorAction:SilentlyContinue
    hey -ErrorAction:Stop
}
catch {
    ___CATCH___
}
finally {
    if (-not $?) { say "finally KO" } else { say "finally OK" }

    ___END___
}

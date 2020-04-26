#Requires -Version 4.0

<#
.SYNOPSIS
Reset the solution.

.PARAMETER Force
Do not ask for confirmation.
#>
[CmdletBinding()]
param(
    [Alias("f")] [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

################################################################################

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Force -or (Confirm-Yes "Hard clean?")) {
        Say "  Deleting 'bin' and 'obj' directories."

        Remove-BinAndObj $SRC_DIR
    }

    if ($Force -or (Confirm-Yes "Restore packages?")) {
        Say "  Restoring packages."

        & dotnet restore `
            -p:TargetFrameworks='\"net461;netstandard2.0;netstandard2.1;netcoreapp3.1\"'
    }
}
catch {
    Croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
        -StackTrace $_.ScriptStackTrace
}
finally {
    popd
}

################################################################################

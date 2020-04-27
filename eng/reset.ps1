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
}
catch {
    Croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
        -StackTrace $_.ScriptStackTrace
}
finally {
    popd
}

################################################################################

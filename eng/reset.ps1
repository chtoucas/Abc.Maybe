#Requires -Version 4.0

<#
.SYNOPSIS
Reset the solution.

.PARAMETER Force
Do not ask for confirmation.
#>
[CmdletBinding()]
param(
    [Alias("y")] [switch] $Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

################################################################################

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Yes -or (Confirm-Yes "Hard clean?")) {
        Say "  Deleting 'bin' and 'obj' directories."

        Remove-BinAndObj $SRC_DIR
        Remove-BinAndObj $TEST_OUTDIR
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

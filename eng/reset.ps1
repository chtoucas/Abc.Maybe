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

function Remove-Dir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $path
    )

    Write-Verbose "Removing $path."

    if (-not (Test-Path $path)) {
        Write-Verbose "Ignoring '$path'; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        Carp "Ignoring '$path'; the path MUST be absolute."
        return
    }

    Write-Verbose "Processing directory '$path'."

    rm $path -Force -Recurse
}

################################################################################

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Yes -or (Confirm-Yes "Hard clean the src directory?")) {
        Say "  Deleting 'bin' and 'obj' directories."
        Remove-BinAndObj $SRC_DIR
    }

    if ($Yes -or (Confirm-Yes "Hard clean the test directory?")) {
        Say "  Deleting 'bin' and 'obj' directories."
        Remove-BinAndObj $TEST_DIR
    }

    if ($Yes -or (Confirm-Yes "Clear local NuGet feed?")) {
        Say "  Clearing local NuGet feed."
        Remove-Dir (Join-Path $NUGET_LOCAL_FEED "abc.maybe")
    }

    if ($Yes -or (Confirm-Yes "Clear local NuGet cache?")) {
        Say "  Clearing local NuGet cache."
        Remove-Dir (Join-Path $NUGET_LOCAL_CACHE "abc.maybe")
    }
}
catch {
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
}
finally {
    popd
}

################################################################################

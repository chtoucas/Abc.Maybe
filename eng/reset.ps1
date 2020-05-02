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

function Remove-Packages {
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

    ls $path -Include "*.nupkg" -Recurse | ?{
        Write-Verbose "Deleting '$_'."

        rm $_.FullName -Force
    }
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

    if ($Yes -or (Confirm-Yes "Reset local NuGet feed/cache?")) {
        # When we reset the NuGet feed, better to clear the cache too, this is
        # not mandatory but it keeps cache and feed in sync.
        # The inverse is also true.
        # If we clear the cache but don't reset the feed, things will continue
        # to work but packages from the local NuGet feed will then be restored
        # to the global cache, exactly what we wanted to avoid.

        # We can't delete the directory, otherwise "dotnet restore" will fail.
        Say "  Resetting local NuGet feed."
        Remove-Packages $NUGET_LOCAL_FEED
        #Remove-Dir $NUGET_LOCAL_FEED

        # "dotnet restore" will recreate the directory if needed.
        Say "  Clearing local NuGet cache."
        #Remove-Dir (Join-Path $NUGET_LOCAL_CACHE "abc.maybe")
        Remove-Dir $NUGET_LOCAL_CACHE
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

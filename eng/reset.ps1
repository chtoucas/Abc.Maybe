#Requires -Version 4.0

<#
.SYNOPSIS
Reset the solution.

.PARAMETER Yes
Do not ask for confirmation.
#>
[CmdletBinding()]
param(
    [Alias("y")] [switch] $Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

Approve-RepositoryRoot

try {
    pushd $ROOT_DIR

    Reset-SourceTree      -Yes:$Yes.IsPresent
    Reset-TestTree        -Yes:$Yes.IsPresent
    Reset-PackageOutDir   -Yes:$Yes.IsPresent
    Reset-PackageCIOutDir -Yes:$Yes.IsPresent
    Reset-LocalNuGet      -Yes:$Yes.IsPresent
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

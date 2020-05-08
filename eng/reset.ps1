# See LICENSE in the project root for license information.

<#
.SYNOPSIS
Reset the repository.

.PARAMETER Restore
Restore NuGet packages and tools thereafter.

.PARAMETER Yes
Do not ask for confirmation.
#>
[CmdletBinding()]
param(
    [Alias("r")] [switch] $Restore,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

if ($Help) {
    Say @"

Reset the repository.

Usage: reset.ps1 [options]
  -r|-Restore  restore NuGet packages and tools thereafter.
  -y|-Yes      do not ask for confirmation.
  -h|-Help     print this help and exit.

"@

    exit 0
}

try {
    pushd $ROOT_DIR

    Reset-SourceTree      -Yes:$Yes
    Reset-TestTree        -Yes:$Yes
    Reset-PackageOutDir   -Yes:$Yes
    Reset-PackageCIOutDir -Yes:$Yes
    Reset-LocalNuGet      -Yes:$Yes

    if ($Restore) {
        Say-LOUDLY "Restoring dependencies, please wait..."
        & dotnet tool restore
        & dotnet restore
    }
}
catch {
    Confess $_
}
finally {
    popd
}

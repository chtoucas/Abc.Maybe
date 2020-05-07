# See LICENSE in the project root for license information.

<#
.SYNOPSIS
Reset the repository.

.PARAMETER Yes
Do not ask for confirmation.
#>
[CmdletBinding()]
param(
    [Alias("y")] [switch] $Yes
)

. (Join-Path $PSScriptRoot "abc.ps1")


try {
    pushd $ROOT_DIR

    Reset-SourceTree      -Yes:$Yes
    Reset-TestTree        -Yes:$Yes
    Reset-PackageOutDir   -Yes:$Yes
    Reset-PackageCIOutDir -Yes:$Yes
    Reset-LocalNuGet      -Yes:$Yes
}
catch {
    Confess $_
}
finally {
    popd
}

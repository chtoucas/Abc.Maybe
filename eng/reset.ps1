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
                 [switch] $Restore,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

if ($Help) {
    say @"

Reset the repository.

Usage: reset.ps1 [arguments]
     -Restore  restore NuGet packages and tools thereafter.
  -y|-Yes      do not ask for confirmation.
  -h|-Help     print this help and exit.

"@

    exit 0
}

Hello "this is the reset script.`n"

try {
    ___BEGIN___

    # Folders that we do NOT reset:
    # 1) __\coverlet\
    # 2) __\opencover\
    # 3) __\tools\
    # 4) eng\NETFrameworkTools\

    Reset-SourceTree      -Yes:$Yes
    Reset-TestTree        -Yes:$Yes
    Reset-PackageOutDir   -Yes:$Yes
    Reset-PackageCIOutDir -Yes:$Yes
    Reset-LocalNuGet      -Yes:$Yes

    if ($Restore) {
        SAY-LOUDLY "`nRestoring dependencies, please wait..."

        Restore-NETFrameworkTools
        Restore-NETCoreTools
        Restore-Solution

        say-softly "Dependencies successfully restored."
    }
}
catch {
    confess $_
}
finally {
    ___END___
}

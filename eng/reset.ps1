# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Reset the repository.

.PARAMETER Extended
Delete even more untracked files.

.PARAMETER Restore
Restore NuGet packages and tools thereafter.

.PARAMETER Yes
Do not ask for confirmation.
#>
[CmdletBinding()]
param(
    [Alias("x")] [switch] $Extended,
                 [switch] $Restore,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

#endregion
################################################################################
#region Tasks.

function Delete-Artifacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $dirname,

        [Alias("y")] [switch] $yes
    )

    if ($yes) { say "`nDeleting artifacts directory ""$dirname""." }

    if ($yes -or (yesno "`nDelete artifacts directory ""$dirname""?")) {
        Remove-Dir (Join-Path $ARTIFACTS_DIR $dirname)
        say-softly "Directory ""$dirname"" was deleted."
    }
}

# ------------------------------------------------------------------------------

function Reset-EngTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { say "`nResetting engineering tree." }

    if ($yes -or (yesno "`nReset the engineering tree?")) {
        Remove-BinAndObj $ENG_DIR
        say-softly "The engineering tree was reset."
    }
}

#endregion
################################################################################

if ($Help) {
    say @"

Reset the repository.

Usage: reset.ps1 [arguments]
     -Restore  restore NuGet packages and tools thereafter.
  -y|-Yes      do not ask for confirmation.
  -h|-Help     print this help and exit.

"@

    exit
}

Hello "this is the cleanup script."

try {
    ___BEGIN___

    Reset-EngTree         -Yes:$Yes
    Reset-SourceTree      -Yes:$Yes
    Reset-TestTree        -Yes:$Yes
    Reset-PackageOutDir   -Yes:$Yes
    Reset-PackageCIOutDir -Yes:$Yes
    Reset-LocalNuGet      -Yes:$Yes

    if ($Extended) {
        # TODO: reset folder "__\tools\".

        Delete-Artifacts "benchmarks" -Yes:$Yes
        Delete-Artifacts "coverlet"   -Yes:$Yes
        Delete-Artifacts "opencover"  -Yes:$Yes
    }

    if ($Restore) {
        SAY-LOUDLY "`nRestoring dependencies, please wait..."

        Restore-NETFxTools
        Restore-NETCoreTools
        Restore-Solution

        say-softly "Dependencies successfully restored."
    }
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

################################################################################

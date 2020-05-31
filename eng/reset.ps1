# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Reset the repository.

.PARAMETER WipeOut
Enable hard reset?

.PARAMETER Extended
Delete even more temporary files?

.PARAMETER Restore
Restore NuGet packages and tools thereafter?

.PARAMETER Yes
Do not ask for confirmation?
#>
[CmdletBinding()]
param(
    [Alias("w")] [switch] $WipeOut,
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

# ------------------------------------------------------------------------------

function Reset-NETFxTools {
    [CmdletBinding()]
    param(
                     [switch] $all,
        [Alias("y")] [switch] $yes
    )

    if ($yes) { say "`nResetting local .NET Frameworks tools." }

    if ($yes -or (yesno "`nReset local .NET Frameworks tools?")) {
        if ($all) {
            ___confess "Deleting cache for .NET Frameworks tools."
            Remove-Dir $NET_FRAMEWORK_TOOLS_DIR
            say-softly "Cache for local .NET Frameworks tools was deleted."
        }
        else {
            ___confess "Cleaning cache for .NET Frameworks tools."
            Remove-Dir (Join-Path $NET_FRAMEWORK_TOOLS_DIR "opencover")
            Remove-Dir (Join-Path $NET_FRAMEWORK_TOOLS_DIR "xunit.runner.console")
            say-softly "Cache for local .NET Frameworks tools was cleaned."
        }
    }
}

#endregion
################################################################################
#region Main.

if ($Help) {
    say @"

Reset the repository.

Usage: reset.ps1 [arguments]
  -w|-WipeOut  enable hard reset?
  -x|-Extended delete even more temporary files?
     -Restore  restore NuGet packages and tools thereafter?
  -y|-Yes      do not ask for confirmation?
  -h|-Help     print this help and exit?

"@

    exit
}

Hello "this is the cleanup script."

try {
    ___BEGIN___

    Reset-EngTree         -Yes:$Yes
    Reset-SourceTree      -Yes:$Yes
    Reset-TestTree        -Yes:$Yes
    Reset-PackageOutDir   -Yes:$Yes -Delete:$WipeOut
    Reset-PackageCIOutDir -Yes:$Yes -Delete:$WipeOut
    Reset-LocalNuGet      -Yes:$Yes -All:$WipeOut

    if ($Extended) {
        Delete-Artifacts "benchmarks" -Yes:$Yes
        Delete-Artifacts "coverlet"   -Yes:$Yes
        Delete-Artifacts "opencover"  -Yes:$Yes

        Reset-NETFxTools -Yes:$Yes -All:$WipeOut
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

#endregion
################################################################################

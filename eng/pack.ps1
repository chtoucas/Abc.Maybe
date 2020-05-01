#Requires -Version 4.0

<#
.SYNOPSIS
Create a NuGet package.

.PARAMETER Retail
Build Retail packages.

.PARAMETER NoTest
Do NOT run the test suite. Retail option only.

.PARAMETER Force
Force packing even when there are uncommited changes.

.PARAMETER Safe
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories.

.PARAMETER MyVerbose
Verbose mode. Display settings used to compile each DLL.

.PARAMETER Help
Print help.

.EXAMPLE
PS>pack.ps1
Create an EDGE package. Append -f to discard warnings about obsolete git infos.

.EXAMPLE
PS>pack.ps1 -r -n -f
Fast packing, retail mode, no test, maybe obsolete git infos.

.EXAMPLE
PS>pack.ps1 -r -s
Safe packing, retail mode.
#>
[CmdletBinding()]
param(
                 [switch] $Retail,
    [Alias("n")] [switch] $NoTest,
    [Alias("f")] [switch] $Force,
    [Alias("s")] [switch] $Safe,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

New-Variable -Name "CONFIGURATION" -Value "Release" -Scope Script -Option Constant

################################################################################

function Write-Usage {
    Say @"

Create a NuGet package for Abc.Maybe

Usage: pack.ps1 [switches]
    |-Retail      build Retail packages.
  -n|-NoTest      do NOT run the test suite.
  -f|-Force       force packing even when there are uncommited changes.
  -s|-Safe        hard clean the solution before creating the package.
  -v|-MyVerbose   display settings used to compile each DLL.
  -h|-Help        print this help and exit.

"@
}

# ------------------------------------------------------------------------------

function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName
    )

    $proj = Join-Path $ENG_DIR "$projectName.props" -Resolve

    $xml = [Xml] (Get-Content $proj)
    $node = (Select-Xml -Xml $xml -XPath "//Project/PropertyGroup/MajorVersion/..").Node

    $major = $node | Select -First 1 -ExpandProperty MajorVersion
    $minor = $node | Select -First 1 -ExpandProperty MinorVersion
    $patch = $node | Select -First 1 -ExpandProperty PatchVersion
    $prere = $node | Select -First 1 -ExpandProperty PreReleaseTag

    @($major, $minor, $patch, $prere)
}

# In the past, we used to generate the id's within MSBuild but then it is nearly
# impossible to override the global properties PackageVersion and VersionSuffix.
# Besides that, generating the id's outside ensures that all assemblies inherit
# the same id's.
function Generate-Uids {
    [CmdletBinding()]
    param()

    $vswhere = Find-VsWhere
    $fsi = Find-Fsi $vswhere

    Write-Verbose "Executing genuids.fsx."

    $uids = & $fsi "$PSScriptRoot\genuids.fsx"

    $uids.Split(";")
}

# Find commit hash and branch.
function Get-GitInfo {
    [CmdletBinding()]
    param(
        [switch] $force
    )

    $commit = ""
    $branch = ""

    $git = Find-GitExe
    if ($git -eq $null) {
        Confirm-Continue "Continue even without any git metadata?"
    }
    else {
        # Keep Approve-GitStatus before $force: we always want to see a warning
        # when there are uncommited changes.
        if ((Approve-GitStatus $git) -or $force) {
            $commit = Get-GitCommitHash $git
            $branch = Get-GitBranch $git
        }
        if ($commit -eq "") { Carp "The commit hash will be empty. Maybe use -Force?" }
        if ($branch -eq "") { Carp "The branch name will be empty. Maybe use -Force?" }
    }

    return @($commit, $branch)
}

function Get-PackageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [switch] $retail
    )

    if ($retail) {
        return Join-Path $PKG_OUTDIR "$projectName.$version.nupkg"
    }
    else {
        return Join-Path $PKG_EDGE_OUTDIR "$projectName.$version.nupkg"
    }
}

function Test-PackageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $package,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version
    )

    # Check dandling package file.
    # NB: only meaningful when in Retail mode; otherwise the id is unique.
    if (Test-Path $package) {
        Carp "A package with the same version ($version) already exists."
        Confirm-Continue "Do you wish to proceed anyway?"

        # Not necessary, dotnet will remove it, but I prefer to play safe.
        Say "  The old package file will be removed now."
        Remove-Item $package
    }
}

function Publish-Local {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $package
    )

    $nuget = Find-Nuget
    if ($nuget -eq $null) {
        Croak "Cannot publish package to the local feed: couldn't find nuget.exe. "
    }

    & $nuget add $package -source $NUGET_LOCAL_FEED | Out-Host
    Assert-CmdSuccess -ErrMessage "Failed to publish package to local feed."
}

# ------------------------------------------------------------------------------

function Invoke-Test {
    SAY-LOUD "Testing."

    & dotnet test -c $CONFIGURATION -v minimal --nologo | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed."

    SAY-LOUD "Testing (net461)."

    & dotnet test -c $CONFIGURATION -v minimal --nologo /p:TargetFramework=net461 | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting net461."
}

function Invoke-Pack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [switch] $retail,
        [switch] $force,
        [switch] $myVerbose
    )

    SAY-LOUD "Packing."

    $major, $minor, $patch, $prere = Get-PackageVersion $projectName
    $buildNumber, $revisionNumber, $serialNumber = Generate-Uids
    $commit, $branch = Get-GitInfo -Force:$force.IsPresent

    if ($retail) {
        $output = $PKG_OUTDIR
        $args = ""
    }
    else {
        # For EDGE packages, we use a custom prerelease label (SemVer 2.0.0).
        if ($prere -eq "") {
            # TODO: what to do if $prere = "rc".
            # If the current version does not have a prerelease label, we
            # increase the patch number to guarantee a version higher than the
            # public one.
            $patch = 1 + [int]$patch
        }
        $prere = "edge.$serialNumber"
        $output = $PKG_EDGE_OUTDIR
        $args = "--version-suffix:$prere", "-p:NoWarnX=NU5105"
    }

    if ($myVerbose) {
        $args = $args, "-p:DisplaySettings=true"
    }

    $version = "$major.$minor.$patch-$prere"
    $package = Get-PackageFile $projectName $version -Retail:$retail.IsPresent

    if ($retail) { Test-PackageFile $package $version }

    $proj = Join-Path $SRC_DIR $projectName -Resolve

    Say "Packing version $version --- build $buildNumber, rev. $revisionNumber" -NoNewline
    if ($branch -and $commit) {
        $abbrv = $commit.Substring(0, 7)
        Say " on branch ""$branch"", commit $abbrv."
    }
    else { Say " on branch ""???"", commit ???." }

    # Do NOT use --no-restore or --no-build (option Safe removes everything).
    & dotnet pack $proj -c $CONFIGURATION --nologo $args --output $output `
        -p:TargetFrameworks='\"netstandard2.1;netstandard2.0;netstandard1.0;net461\"' `
        -p:BuildNumber=$buildNumber `
        -p:RevisionNumber=$revisionNumber `
        -p:RepositoryCommit=$commit `
        -p:RepositoryBranch=$branch `
        -p:Retail=true `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Pack task failed."

    if ($retail) {
        Chirp "Package successfully created."
    }
    else {
        Chirp "EDGE package successfully created."
    }

    $package
}

function Invoke-Publish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $package,

        [switch] $retail
    )

    if ($retail) {
        # TODO: add an option to publish the package for us?
        # --interactive
        # --skip-duplicate (not necessary it is for multiple packages)
        Chirp "To publish the package:"
        Chirp "> dotnet nuget push $package -s https://www.nuget.org/ -k MYKEY"
    }
    else {
        Publish-Local $package

        Chirp "EDGE package successfully installed."
    }
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Retail -and (-not $NoTest)) { Invoke-Test }

    # Safe packing?
    if ($Safe) {
        if (Confirm-Yes "Hard clean?") {
            Say "  Deleting 'bin' and 'obj' directories."

            Remove-BinAndObj $SRC_DIR
        }
    }

    $package = Invoke-Pack "Abc.Maybe" `
        -Retail:$Retail.IsPresent `
        -Force:$Force.IsPresent `
        -MyVerbose:$MyVerbose.IsPresent

    Invoke-Publish $package -Retail:$Retail.IsPresent
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

#Requires -Version 4.0

<#
.SYNOPSIS
Create a NuGet package.

.PARAMETER Clean
Clean the solution before anything else.

.PARAMETER NoTest
Do NOT run the test suite.

.PARAMETER Force
Force packing even when there are uncommited changes.

.PARAMETER Safe
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories. Normally, it should not be necessary.

.PARAMETER Help
Print help.

.EXAMPLE
PS>pack.ps1 -n -f
Fast packing, no test, maybe obsolete git infos.

.EXAMPLE
PS>pack.ps1 -c -s
Clean & safe packing.
#>
[CmdletBinding()]
param(
    [Alias("c")] [switch] $Clean,
    [Alias("n")] [switch] $NoTest,
    [Alias("f")] [switch] $Force,
    [Alias("s")] [switch] $Safe,
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
  -c|-Clean    soft clean the solution before anything else.
  -n|-NoTest   do NOT run the test suite.
  -f|-Force    force packing even when there are uncommited changes.
  -s|-Safe     hard clean the solution before creating the package.
  -h|-Help     print this help and exit.

"@
}

function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectName
    )

    $proj = Join-Path $ENG_DIR "$ProjectName.props" -Resolve

    $xml = [Xml] (Get-Content $proj)
    $node = (Select-Xml -Xml $xml -XPath "//Project/PropertyGroup/MajorVersion/..").Node

    $major = $node | Select -First 1 -ExpandProperty MajorVersion
    $minor = $node | Select -First 1 -ExpandProperty MinorVersion
    $patch = $node | Select -First 1 -ExpandProperty PatchVersion
    $prere = $node | Select -First 1 -ExpandProperty PreReleaseTag

    if ($prere.StartsWith("DEV")) {
        Croak "We disallow the creation of DEV packages."
    }

    "$major.$minor.$patch-$prere"
}

function Invoke-Clean {
    SAY-LOUD "Cleaning."

    & dotnet clean -c $CONFIGURATION -v minimal --nologo

    Assert-CmdSuccess -ErrMessage "Clean task failed."
}

function Invoke-Test {
    SAY-LOUD "Testing w/ netcoreapp3.1."

    & dotnet test -c $CONFIGURATION -v minimal --nologo

    Assert-CmdSuccess -ErrMessage "Test task failed when targeting netcoreapp3.1."

    SAY-LOUD "Testing w/ net461."

    & dotnet test -c $CONFIGURATION -v minimal --nologo /p:TargetFramework=net461

    Assert-CmdSuccess -ErrMessage "Test task failed when targeting net461."
}

function Invoke-Pack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectName,

        [switch] $Force
    )

    SAY-LOUD "Packing."

    $version = Get-PackageVersion $ProjectName

    $proj = Join-Path $SRC_DIR $ProjectName -Resolve
    $pkg = Join-Path $PKG_OUTDIR "$ProjectName.$version.nupkg"

    if (Test-Path $pkg) {
        Carp "A package with the same version ($version) already exists."
        Confirm-Continue "Do you wish to proceed anyway?"

        Say "  The old package file will be removed now."
        Remove-Item $pkg
    }

    # Find commit hash and branch.
    $commit = ""
    $branch = ""
    $git = Find-GitExe
    if ($git -eq $null) {
        Confirm-Continue "Continue even without any git metadata?"
    }
    else {
        # Keep Approve-GitStatus before $Force: we always want to see a warning
        # when there are uncommited changes.
        if ((Approve-GitStatus $git) -or $Force) {
            $commit = Get-GitCommitHash $git
            $branch = Get-GitBranch $git
        }
        if ($commit -eq "") { Carp "The commit hash will be empty. Maybe use -Force?" }
        if ($branch -eq "") { Carp "The branch name will be empty. Maybe use -Force?" }
    }

    # Safe packing?
    if ($Safe) {
        if (Confirm-Yes "Hard clean?") {
            Say "  Deleting 'bin' and 'obj' directories."

            Remove-BinAndObj $SRC_DIR
        }
    }

    # Do NOT use --no-restore or --no-build (option Safe removes everything).
    # NB: netstandard2.1 is not currently enabled within the proj file.
    # Remove DebugType to use plain pdb's.
    & dotnet pack $proj -c $CONFIGURATION --nologo `
        --output $PKG_OUTDIR `
        -p:DisplaySettings=true `
        -p:TargetFrameworks='\"netstandard2.1;netstandard2.0;netcoreapp3.1;net461\"' `
        -p:Retail=true `
        -p:RepositoryCommit=$commit `
        -p:RepositoryBranch=$branch `
        -p:DebugType=embedded

    Assert-CmdSuccess -ErrMessage "Pack task failed."

    Chirp "To publish the package:"
    Chirp "> dotnet nuget push $pkg -s https://www.nuget.org/ -k MYKEY"
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Clean) { Invoke-Clean }
    if (-not $NoTest) { Invoke-Test }

    Invoke-Pack "Abc.Maybe" -Force:$Force.IsPresent
}
catch {
    Croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
        -StackTrace $_.ScriptStackTrace
}
finally {
    popd
}

################################################################################

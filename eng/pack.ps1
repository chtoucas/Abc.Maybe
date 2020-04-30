#Requires -Version 4.0

<#
.SYNOPSIS
Create a NuGet package.

.PARAMETER Retail
Build Retail packages.

.PARAMETER NoTest
Do NOT run the test suite.
Retail option only.

.PARAMETER Force
Force packing even when there are uncommited changes.
Retail option only.

.PARAMETER Safe
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories. Normally, it should not be necessary.
Retail option only.

.PARAMETER Help
Print help.

.EXAMPLE
PS>pack.ps1 -n -f
Fast packing, no test, maybe obsolete git infos.

.EXAMPLE
PS>pack.ps1 -s
Safe packing.
#>
[CmdletBinding()]
param(
                 [switch] $Retail,
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
    |-Retail   build Retail packages.
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
        [string] $projectName
    )

    $proj = Join-Path $ENG_DIR "$projectName.props" -Resolve

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

function Invoke-Test {
    SAY-LOUD "Testing."

    & dotnet test -c $CONFIGURATION -v minimal --nologo
    Assert-CmdSuccess -ErrMessage "Test task failed."

    SAY-LOUD "Testing (net461)."

    & dotnet test -c $CONFIGURATION -v minimal --nologo /p:TargetFramework=net461
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting net461."
}

# TODO: WIP
function Invoke-PackEDGE {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName
    )

    SAY-LOUD "Packing EDGE."

    $proj = Join-Path $SRC_DIR $projectName -Resolve

    # Find commit hash and branch.
    $commit = ""
    $branch = ""
    $git = Find-GitExe
    if ($git -ne $null) {
        Approve-GitStatus $git | Out-Null
        $commit = Get-GitCommitHash $git
        $branch = Get-GitBranch $git
        if ($commit -eq "") { Carp "The commit hash will be empty." }
        if ($branch -eq "") { Carp "The branch name will be empty." }
    }

    & dotnet pack $proj -c $CONFIGURATION --nologo -v n `
        --output $PKG_EDGE_OUTDIR `
        -p:DisplaySettings=true `
        -p:TargetFrameworks=netstandard2.0 `
        -p:RepositoryCommit=$commit `
        -p:RepositoryBranch=$branch `
        -p:Retail=true `
        -p:EDGE=true

    Assert-CmdSuccess -ErrMessage "Pack EDGE task failed."

    Chirp "The package is here: $PKG_EDGE_OUTDIR."
}

function Invoke-Pack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [switch] $force
    )

    SAY-LOUD "Packing."

    $version = Get-PackageVersion $projectName

    $proj = Join-Path $SRC_DIR $projectName -Resolve
    $pkg = Join-Path $PKG_OUTDIR "$projectName.$version.nupkg"

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
        # Keep Approve-GitStatus before $force: we always want to see a warning
        # when there are uncommited changes.
        if ((Approve-GitStatus $git) -or $force) {
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
    & dotnet pack $proj -c $CONFIGURATION --nologo `
        --output $PKG_OUTDIR `
        -p:DisplaySettings=true `
        -p:TargetFrameworks='\"netstandard2.1;netstandard2.0;netstandard1.0;net461\"' `
        -p:RepositoryCommit=$commit `
        -p:RepositoryBranch=$branch `
        -p:Retail=true

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

    if ($Retail) {
        if (-not $NoTest) { Invoke-Test }

        Invoke-Pack "Abc.Maybe" -Force:$Force.IsPresent
    }
    else {
        Invoke-PackEDGE "Abc.Maybe"
    }
}
catch {
    Croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
        -StackTrace $_.ScriptStackTrace
}
finally {
    popd
}

################################################################################

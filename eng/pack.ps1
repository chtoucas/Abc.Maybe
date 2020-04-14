#Requires -Version 4.0

<#
.SYNOPSIS
Create a NuGet package.

.PARAMETER Clean
Clean the solution before anything else.

.PARAMETER NoTest
Do NOT run the test suite.
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
  -c|-Clean    clean the solution before anything else.
  -n|-NoTest   do NOT run the test suite.
  -f|-Force    force packaging even without a git commit hash -or- when there are uncommited changes.
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

    "$major.$minor.$patch-$prere"
}

function Invoke-Clean {
    SAY-LOUD "Cleaning."

    & dotnet clean -c $CONFIGURATION -v minimal --nologo

    Assert-CmdSuccess -ErrMessage "Clean task failed."
}

function Invoke-Test {
    SAY-LOUD "Testing."

    # SignAssembly is not necessary but I want to check that InternalsVisibleTo
    # works as expected.
    & dotnet test -c $CONFIGURATION -v minimal --nologo -p:SignAssembly=true

    Assert-CmdSuccess -ErrMessage "Test task failed."
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

        Say "The old package file will be removed now."
        Remove-Item $pkg
    }

    # Find commit hash and branch.
    $commit = ""
    $branch = ""
    $git = Find-GitExe
    if ($git -ne $null) {
        # Keep Approve-GitStatus before $Force: we always want to see a warning
        # when there are uncommited changes.
        if ((Approve-GitStatus $git) -or $Force) {
            $commit = Get-GitCommitHash $git
            $branch = Get-GitBranch $git
        }
    }
    if ($commit -eq "") { Carp "The commit hash will be empty." }
    if ($branch -eq "") { Carp "The branch name will be empty." }

    # Safe packing?
    if ($Safe) {
        if (Confirm-Yes "Hard clean?") {
            Say "Deleting 'bin' and 'obj' directories."

            Remove-BinAndObj $SRC_DIR
        }
    }

    # Do NOT use --no-restore or --no-build; netstandard2.1 is not currently
    # enabled within the proj file.
    # Remove DebugType to use plain pdb's.
    & dotnet pack $proj -c $CONFIGURATION --nologo `
        --output $PKG_OUTDIR `
        -p:TargetFrameworks='\"netstandard2.0;netstandard2.1;netcoreapp3.1\"' `
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

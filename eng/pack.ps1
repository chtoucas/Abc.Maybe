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
  [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

New-Variable -Name "CONFIGURATION" -Value "Release" -Scope Script -Option Constant

################################################################################

function Write-Usage {
  Say "`nCreate a NuGet package for Abc.Maybe.`n"
  Say "Usage: pack.ps1 [switches]"
  Say "  -c|-Clean    clean the solution before anything else."
  Say "  -n|-NoTest   do NOT run the test suite."
  Say "  -f|-Force    force packaging even without a git commit hash -or- when there are uncommited changes."
  Say "  -h|-Help     print this help and exit.`n"
}

function Get-PackageVersion([string] $projName) {
  $proj = Join-Path $ENG_DIR "$projName.props"

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

  Assert-CmdSuccess "Clean task failed."
}

function Invoke-Test {
  SAY-LOUD "Testing."

  # SignAssembly is not necessary but I want to check that InternalsVisibleTo
  # works as expected.
  & dotnet test -c $CONFIGURATION -v minimal --nologo -p:SignAssembly=true

  Assert-CmdSuccess "Test task failed."
}

function Invoke-Pack([string] $projName, [switch] $force) {
  SAY-LOUD "Packing."

  $version = Get-PackageVersion $projName

  $proj = Join-Path $SRC_DIR $projName
  $pkg = Join-Path $PKG_OUTDIR "$projName.$version.nupkg"

  if (Test-Path $pkg) {
    Carp "A package with the same version ($version) already exists."

    Confirm-Continue "Do you wish to proceed anyway?"

    Say "The old package file will be removed now."
    Remove-Item $pkg
  }

  # Find commit hash and branch.
  $commit = ""
  $branch = ""
  $git = Find-GitExe -Force:$force.IsPresent
  if ($git -ne $null) {
    $commit = Get-GitCommitHash $git
    $branch = Get-GitBranch $git
  }
  if ($commit -eq "") { Carp "The commit hash will be empty. Maybe use -Force?" }
  if ($branch -eq "") { Carp "The branch name will be empty. Maybe use -Force?" }

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

  Assert-CmdSuccess "Pack task failed."

  Write-Recap "To publish the package:"
  Write-Recap "> dotnet nuget push $pkg -s https://www.nuget.org/ -k MYKEY"
}

################################################################################

if ($Help) {
  Write-Usage
  exit 0
}

try {
  pushd (Approve-ProjectRoot)

  if ($Clean) { Invoke-Clean }
  if (-not $NoTest) { Invoke-Test }

  Invoke-Pack "Abc.Maybe" -Force:$force.IsPresent
}
catch {
  Croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
    -StackTrace $_.ScriptStackTrace
}
finally {
  popd
}

################################################################################

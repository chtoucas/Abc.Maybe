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

. (Join-Path $PSScriptRoot "shared.ps1")

New-Variable -Name "CONFIGURATION" -Value "Release" -Scope Script -Option Constant

################################################################################

function print-usage {
  say "`nCreate a NuGet package for Abc.Maybe.`n"
  say "Usage: pack.ps1 [switches]"
  say "  -c|-Clean    clean the solution before anything else."
  say "  -n|-NoTest   do NOT run the test suite."
  say "  -f|-Force    force packaging even without a git commit hash -or- when there are uncommited changes."
  say "  -h|-Help     print this help and exit.`n"
}

function get-pkgversion([string] $proj) {
  $xml = [Xml] (Get-Content $proj)
  $node = (Select-Xml -Xml $xml -XPath "//Project/PropertyGroup/MajorVersion/..").Node

  $major = $node | Select -First 1 -ExpandProperty MajorVersion
  $minor = $node | Select -First 1 -ExpandProperty MinorVersion
  $patch = $node | Select -First 1 -ExpandProperty PatchVersion
  $prere = $node | Select -First 1 -ExpandProperty PreReleaseTag

  "$major.$minor.$patch-$prere"
}

function run-clean {
  say-loud "Cleaning."

  & dotnet clean -c $CONFIGURATION -v minimal --nologo

  on-lastcmderr "Clean task failed."
}

function run-test {
  say-loud "Testing."

  # SignAssembly is not necessary but I want to check that InternalsVisibleTo
  # works as expected.
  & dotnet test -c $CONFIGURATION -v minimal --nologo -p:SignAssembly=true

  on-lastcmderr "Test task failed."
}

function run-pack([string] $projName, [switch] $force) {
  say-loud "Packing."

  $version = get-pkgversion (Join-Path $ENG_DIR "$projName.props")

  $proj = Join-Path $SRC_DIR $projName
  $pkg = Join-Path $PKG_OUTDIR "$projName.$version.nupkg"

  if (Test-Path $pkg) {
    carp "A package with the same version ($version) already exists."

    $question = "Do you wish to proceed anyway? [y/n]"
    $answer = Read-Host $question
    while ($answer -ne "y") {
      if ($answer -eq "n") { exit 0 }
      $answer = Read-Host $question
    }

    say "The old package file will be removed now."
    Remove-Item $pkg
  }

  # Find commit hash and branch.
  $commit = ""
  $branch = ""
  $git = Get-GitExe -Force:$force.IsPresent
  if ($git -ne $null) {
    $commit = Get-GitCommitHash $git
    $branch = Get-GitBranch $git
  }
  if ($commit -eq "") { carp "The commit hash will be empty." }
  if ($branch -eq "") { carp "The branch name will be empty." }

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

  on-lastcmderr "Pack task failed."

  recap "To publish the package:"
  recap "> dotnet nuget push $pkg -s https://www.nuget.org/ -k MYKEY"
}

################################################################################

if ($Help) {
  print-usage
  exit 0
}

try {
  pushd $ROOT_DIR

  if ($Clean) { run-clean }
  if (-not $NoTest) { run-test }

  run-pack "Abc.Maybe" -Force:$force.IsPresent
}
catch {
  croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
    -StackTrace $_.ScriptStackTrace
}
finally {
  popd
}

################################################################################

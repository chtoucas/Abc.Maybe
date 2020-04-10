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

. (join-path $PSScriptRoot "eng\shared.ps1")
. (join-path $PSScriptRoot "eng\git.ps1")

"Release" | New-Variable -Name CONFIGURATION -Scope Script -Option Constant

################################################################################

function print-usage {
  say "`nCreate a NuGet package for Abc.Maybe.`n"
  say "Usage: pack.ps1 [switches]"
  say "  -c|-Clean    clean the solution before anything else."
  say "  -n|-NoTest   do NOT run the test suite."
  say "  -f|-Force    force packaging even without a git commit hash -or- when there are uncommited changes."
  say "  -h|-Help     print this help and exit.`n"
}

function get-version([string] $proj) {
  $xml = [Xml] (get-content $proj)
  $node = (select-xml -Xml $xml -XPath "//Project/PropertyGroup/MajorVersion/..").Node

  $major = $node | select -First 1 -ExpandProperty MajorVersion
  $minor = $node | select -First 1 -ExpandProperty MinorVersion
  $patch = $node | select -First 1 -ExpandProperty PatchVersion
  $label = $node | select -First 1 -ExpandProperty PreReleaseLabel

  "$major.$minor.$patch-$label"
}

function get-commit([switch] $force) {
  $git = Get-GitExe

  if ($git -eq $null) {
      carp "git.exe could not be found in your PATH. Please ensure git is installed."
      return ""
  }

  $status = Get-GitStatus $git

  if ($status -eq $null) {
    carp "Unabled to verify the git status."
    if (-not $force) { return "" }
  }
  elseif ($status -ne '') {
    carp "Uncommitted changes are pending."
    if (-not $force) { return "" }
  }

  Get-GitCommitHash $git
}

function run-clean {
  say-loud "Cleaning."

  & dotnet clean -c $CONFIGURATION -v minimal --nologo

  on-lastcmderr "Clean task failed."
}

function run-test {
  say-loud "Testing."

  & dotnet test -c $CONFIGURATION -v minimal --nologo

  on-lastcmderr "Test task failed."
}

function run-pack([string] $projName, [switch] $force) {
  say-loud "Packing."

  $version = get-version (join-path $ROOT_DIR "eng\Retail.props")

  $proj = join-path $SRC_DIR $projName
  $pkg = join-path $PKG_DIR "$projName.$version.nupkg"

  if (test-path $pkg) {
    carp "A package with the same version ($version) already exists."

    $question = "Do you wish to proceed anyway? [y/n]"
    $answer = read-host $question
    while ($answer -ne "y") {
      if ($answer -eq "n") { exit 0 }
      $answer = read-host $question
    }

    remove-item $pkg
  }

  $commit = get-commit -Force:$force.IsPresent
  if ($commit -eq '') { carp "The commit hash is empty." }

  # Do NOT use --no-restore; netstandard2.1 is not currently enabled within the
  # proj file.
  & dotnet pack $proj -c $CONFIGURATION --nologo `
    --output $PKG_DIR `
    -p:TargetFrameworks='\"netstandard2.0;netstandard2.1;netcoreapp3.1\"' `
    -p:Retail=true `
    -p:RepositoryCommit=$commit

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

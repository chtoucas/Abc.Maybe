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
  [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (join-path $PSScriptRoot "eng\shared.ps1")

"Release" | New-Variable -Name CONFIGURATION -Scope Script -Option Constant

################################################################################

function print-usage {
  say "`nCreate a NuGet package for Abc.Maybe.`n"
  say "Usage: pack.ps1 [switches]"
  say "  -c|-Clean    clean the solution before anything else."
  say "  -n|-NoTest   do NOT run the test suite."
  say "  -h|-Help     print this help and exit.`n"
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

function run-pack([string] $projName, [string] $version) {
  say-loud "Packing."

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
  }

  # Do NOT use --no-restore; netstandard2.1 is not currently declared within the
  # proj file.
  & dotnet pack $proj -c $CONFIGURATION --nologo `
    --output $PKG_DIR `
    -p:TargetFrameworks='\"netstandard2.0;netstandard2.1;netcoreapp3.1\"' `
    -p:Deterministic=true `
    -p:PackageVersion=$version `

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

  run-pack "Abc.Maybe" "1.0.0-alpha-2"
}
catch {
  croak ("An unexpected error occured: {0}." -f $_.Exception.Message)
}
finally {
  popd
}

################################################################################

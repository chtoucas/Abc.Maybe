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
  [switch] $Clean,
  [switch] $NoTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (join-path $PSScriptRoot "shared.ps1")

(join-path $ARTIFACTS_DIR "packages") `
  | New-Variable -Name PKG_DIR -Scope Script -Option Constant

"Release" | New-Variable -Name CONFIGURATION -Scope Script -Option Constant

################################################################################

function run-clean {
  say-loud "Cleaning."

  & dotnet clean -c $CONFIGURATION -v minimal --nologo

  if ($LastExitCode -ne 0) { croak "Clean task failed." }
}

function run-test {
  say-loud "Testing."

  & dotnet test -c $CONFIGURATION -v minimal --nologo

  if ($LastExitCode -ne 0) { croak "Test task failed." }
}

function run-pack([string] $projName, [string] $version) {
  say-loud "Packing."

  $proj = join-path $SRC_DIR $projName
  $pkg = join-path $PKG_DIR "$projName.$version.nupkg"

  if (test-path $pkg) {
    carp "A package with the same version ($version) already exists."

    $question = "Do you wish to proceed anyway? [y/n]"
    $continue = read-host $question
    while ($continue -ne "y") {
      if ($continue -eq "n") { exit 0 }
        $continue = read-host $question
      }
  }

  # Do NOT use --no-restore; netstandard2.1 is not currently declared within the
  # proj file.
  & dotnet pack $proj -c $CONFIGURATION --nologo `
    --output $PKG_DIR `
    -p:TargetFrameworks='\"netstandard2.0;netstandard2.1;netcoreapp3.1\"' `
    -p:Deterministic=true `
    -p:PackageVersion=$version `

  if ($LastExitCode -ne 0) { croak "Pack task failed." }

  confess "To publish the package:"
  confess "> dotnet nuget push $pkg -s https://www.nuget.org/ -k MYKEY"
}

################################################################################

try {
  pushd $ROOT_DIR

  if ($Clean) { run-clean }
  if (-not $NoTest) { run-test }

  run-pack "Abc.Maybe" "1.0.0-alpha-2"
} catch {
  carp ("An unexpected error occured: {0}." -f $_.Exception.Message)
  exit 1
} finally {
  popd
}

################################################################################

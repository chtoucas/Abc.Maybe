#Requires -Version 4.0

<#
.SYNOPSIS
Run the Code Coverage script and build human-readable reports.

.DESCRIPTION
Run the Code Coverage script w/ either Coverlet (default) or OpenCover,
then optionally build human-readable reports and badges.

Prerequesites: NuGet packages and tools must have been restored before.

OpenCover is slow when compared to Coverlet, but we get risk hotspots
(NPath complexity, crap score) and the list of unvisited methods.
Furthermore, the results differ slightly (LINQ and async so far) which
makes the two tools complementary --- line counts may differ too but
that's just a detail.

.PARAMETER OpenCover
Use OpenCover instead of Coverlet.

.PARAMETER NoReport
Dot not build HTML/text reports and badges w/ ReportGenerator.

.PARAMETER ReportOnly
Dot not run any Code Coverage tool.

.EXAMPLE
PS>cover.ps1
Run Coverlet then build the human-readable reports.

.EXAMPLE
PS>cover.ps1 -x
Run OpenCover then build the human-readable reports.

.EXAMPLE
PS>cover.ps1 -OpenCover -NoReport
Run OpenCover, do NOT build human-readable reports and badges.
#>
[CmdletBinding()]
param(
  [Alias("x")] [switch] $OpenCover,
  [switch] $NoReport,
  [switch] $ReportOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir.
$ARTIFACTS_DIR = "__"
$CONFIGURATION = "Debug"

. (join-path $PSScriptRoot "say.ps1")

################################################################################

function run-opencover([string] $outxml) {
  say-loud "Running OpenCover."

  $proj = "src\Abc.Tests\Abc.Tests.csproj"

  # Find the OpenCover version.
  $xml = [Xml] (get-content $proj)
  $version = `
    select-xml -Xml $xml `
      -XPath "//Project/ItemGroup/PackageReference[@Include='OpenCover']" `
    | select -ExpandProperty Node `
    | select -First 1 -ExpandProperty Version

  $exe = join-path $env:USERPROFILE `
    ".nuget\packages\opencover\$version\tools\OpenCover.Console.exe"

  $filters = `
    "+[Abc.Maybe]*",
    "-[Abc.Future]*",
    "-[Abc.Test*]*",
    "-[Abc*]System.Diagnostics.CodeAnalysis.*",
    "-[Abc*]System.Runtime.CompilerServices.*",
    "-[Abc*]Microsoft.CodeAnalysis.*"
  $filter = "$filters"

  # See https://github.com/opencover/opencover/wiki/Usage
  & $exe -oldStyle -register:user `
    -hideskipped:All `
    -showunvisited `
    -output:$outxml `
    -target:dotnet.exe `
    -targetargs:"test $proj -v quiet -c $CONFIGURATION --no-restore /p:DebugType=Full" `
    -filter:$filter `
    -excludebyattribute:*.ExcludeFromCodeCoverageAttribute

  if ($LastExitCode -ne 0) { croak "OpenCover failed." }
}

function run-coverlet([string] $outxml) {
  say-loud "Running Coverlet."

  $excludes = `
    "[Abc*]System.Diagnostics.CodeAnalysis.*",
    "[Abc*]System.Runtime.CompilerServices.*",
    "[Abc*]Microsoft.CodeAnalysis.*"
  $exclude = '\"' + ($excludes -join ",") + '\"'

  & dotnet test -c $CONFIGURATION --no-restore `
    /p:CollectCoverage=true `
    /p:CoverletOutputFormat=opencover `
    /p:CoverletOutput=$outxml `
    /p:Include="[Abc.Maybe]*" `
    /p:Exclude=$exclude

  if ($LastExitCode -ne 0) { croak "Coverlet failed." }
}

function run-rg([string] $reports, [string] $targetdir) {
  say-loud "Running ReportGenerator."

  & dotnet tool run reportgenerator `
    -verbosity:Warning `
    -reporttypes:"HtmlInline;Badges;TextSummary" `
    -reports:$reports `
    -targetdir:$outdir

  if ($LastExitCode -ne 0) { croak "ReportGenerator failed." }
}

################################################################################

try {
  pushd $PSScriptRoot

  $tool = if ($OpenCover) { "opencover" } else { "coverlet" }
  $outdir = join-path $ARTIFACTS_DIR $tool
  $outxml = join-path $outdir "$tool.xml"

  # Create the directory if it does not already exist.
  # Do not remove this, it must be done before calling OpenCover.
  if (-not (test-path $outdir)) {
    mkdir -Force -Path $outdir | out-null
  }

  if ($ReportOnly) {
    carp "On your request, we do not run any Code Coverage tool."
  } elseif ($OpenCover) {
    run-opencover $outxml
  } else {
    # coverlet.msbuild uses the path relative to the test project.
    run-coverlet (join-path $PSScriptRoot $outxml)
  }

  if ($NoReport) {
    carp "On your request, we do not run ReportGenerator."
  } else {
    run-rg $outxml $outdir

    try {
      pushd $outdir

      cp -Force -Path "badge_combined.svg" -Destination (join-path ".." "$tool.svg")
      cp -Force -Path "Summary.txt" -Destination (join-path ".." "$tool.txt")
    } finally {
      popd
    }
  }
} catch {
  carp ("An unexpected error occured: {0}." -f $_.Exception.Message)
  exit 1
} finally {
  popd
}

################################################################################

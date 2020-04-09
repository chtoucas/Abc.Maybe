#Requires -Version 4.0

<#
.SYNOPSIS
Run the Code Coverage script and build human-readable reports.

.DESCRIPTION
Run the Code Coverage script w/ either Coverlet (default) or OpenCover,
then optionally build human-readable reports and badges.

Prerequesites: NuGet packages and tools must have been restored before. If not
the script may fail with not even a single warning... (eg w/ Coverlet).

OpenCover is slow when compared to Coverlet, but we get risk hotspots
(NPath complexity, crap score) and the list of unvisited methods.
Furthermore, the results differ slightly (LINQ and async so far) which
makes the two tools complementary --- line counts may differ too but
that's just a detail.

.PARAMETER OpenCover
Use OpenCover instead of Coverlet.

.PARAMETER NoReport
Do NOT build HTML/text reports and badges w/ ReportGenerator.

.PARAMETER ReportOnly
Do NOT run any Code Coverage tool.

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
  [switch] $ReportOnly,
  [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (join-path $PSScriptRoot "eng\shared.ps1")

"Debug" | New-Variable -Name CONFIGURATION -Scope Script -Option Constant

################################################################################

function print-usage {
  say "`nRun the Code Coverage script and build human-readable reports.`n"
  say "Usage: cover.ps1 [switches]"
  say "  -x|-OpenCover    use OpenCover instead of Coverlet."
  say "     -NoReport     do NOT run ReportGenerator."
  say "     -ReportOnly   do NOT run any Code Coverage tool."
  say "  -h|-Help         print this help and exit.`n"
}

function get-opencover([string] $proj) {
  # Find the OpenCover version.
  $xml = [Xml] (get-content $proj)
  $xpath = "//Project/ItemGroup/PackageReference[@Include='OpenCover']"
  $version = select-xml -Xml $xml -XPath $xpath `
    | select -ExpandProperty Node `
    | select -First 1 -ExpandProperty Version

  join-path $env:USERPROFILE `
    ".nuget\packages\opencover\$version\tools\OpenCover.Console.exe"
}

function run-opencover {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string] $exe,

    [string] $output)

  say-loud "Running OpenCover."

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
    -output:$output `
    -target:dotnet.exe `
    -targetargs:"test -v quiet -c $CONFIGURATION --no-restore /p:DebugType=Full" `
    -filter:$filter `
    -excludebyattribute:*.ExcludeFromCodeCoverageAttribute

  on-lastcmderr "OpenCover failed."
}

function run-coverlet([string] $output) {
  say-loud "Running Coverlet."

  $excludes = `
    "[Abc*]System.Diagnostics.CodeAnalysis.*",
    "[Abc*]System.Runtime.CompilerServices.*",
    "[Abc*]Microsoft.CodeAnalysis.*"
  $exclude = '\"' + ($excludes -join ",") + '\"'

  & dotnet test -c $CONFIGURATION --no-restore `
    /p:CollectCoverage=true `
    /p:CoverletOutputFormat=opencover `
    /p:CoverletOutput=$output `
    /p:Include="[Abc.Maybe]*" `
    /p:Exclude=$exclude

  on-lastcmderr "Coverlet failed."
}

function run-rg([string] $reports, [string] $targetdir) {
  say-loud "Running ReportGenerator."

  & dotnet tool run reportgenerator `
    -verbosity:Warning `
    -reporttypes:"HtmlInline;Badges;TextSummary" `
    -reports:$reports `
    -targetdir:$targetdir

  on-lastcmderr "ReportGenerator failed."
}

################################################################################

if ($Help) {
  print-usage
  exit 0
}

try {
  pushd $ROOT_DIR

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
  }
  elseif ($OpenCover) {
    get-opencover (join-path $SRC_DIR "Abc.Tests\Abc.Tests.csproj") `
      | run-opencover -output $outxml
  }
  else {
    # For coverlet.msbuild the path must be absolute if we want the result to be
    # put within the directory for artifacts and not below the test project.
    run-coverlet $outxml
  }

  if ($NoReport) {
    carp "On your request, we do not run ReportGenerator."
  }
  else {
    run-rg $outxml $outdir

    try {
      pushd $outdir

      cp -Force -Path "badge_combined.svg" -Destination (join-path ".." "$tool.svg")
      cp -Force -Path "Summary.txt" -Destination (join-path ".." "$tool.txt")
    }
    finally {
      popd
    }
  }
}
catch {
  croak ("An unexpected error occured: {0}." -f $_.Exception.Message)
}
finally {
  popd
}

################################################################################

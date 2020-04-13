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

. (Join-Path $PSScriptRoot "abc.ps1")

New-Variable -Name "CONFIGURATION" -Value "Debug" -Scope Script -Option Constant

################################################################################

function Write-Usage {
    Say "`nRun the Code Coverage script and build human-readable reports.`n"
    Say "Usage: cover.ps1 [switches]"
    Say "  -x|-OpenCover    use OpenCover instead of Coverlet."
    Say "     -NoReport     do NOT run ReportGenerator."
    Say "     -ReportOnly   do NOT run any Code Coverage tool."
    Say "  -h|-Help         print this help and exit.`n"
}

function Find-OpenCover {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectPath
    )

    # Find the OpenCover version.
    $xml = [Xml] (Get-Content $ProjectPath)
    $xpath = "//Project/ItemGroup/PackageReference[@Include='OpenCover']"
    $version = Select-Xml -Xml $xml -XPath $xpath `
        | Select -ExpandProperty Node `
        | Select -First 1 -ExpandProperty Version

    $exe = Join-Path $env:USERPROFILE `
        ".nuget\packages\opencover\$version\tools\OpenCover.Console.exe"

    if (-not (Test-Path $exe)) {
        Croak "Couldn't find OpenCover v$version where I expected it to be."
    }

    $exe
}

function Invoke-OpenCover {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $exe,

        [string] $output
    )

    SAY-LOUD "Running OpenCover."

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

    Assert-CmdSuccess -ErrMessage "OpenCover failed."
}

function Invoke-Coverlet([string] $output) {
    SAY-LOUD "Running Coverlet."

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

    Assert-CmdSuccess -ErrMessage "Coverlet failed."
}

function Invoke-ReportGenerator([string] $reports, [string] $targetdir) {
    SAY-LOUD "Running ReportGenerator."

    & dotnet tool run reportgenerator `
        -verbosity:Warning `
        -reporttypes:"HtmlInline;Badges;TextSummary" `
        -reports:$reports `
        -targetdir:$targetdir

    Assert-CmdSuccess -ErrMessage "ReportGenerator failed."
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    $tool = if ($OpenCover) { "opencover" } else { "coverlet" }
    $outdir = Join-Path $ARTIFACTS_DIR $tool
    $outxml = Join-Path $outdir "$tool.xml"

    # Create the directory if it does not already exist.
    # Do not remove this, it must be done before calling OpenCover.
    if (-not (Test-Path $outdir)) {
        mkdir -Force -Path $outdir | Out-Null
    }

    if ($ReportOnly) {
        Carp "On your request, we do not run any Code Coverage tool."
    }
    elseif ($OpenCover) {
        Find-OpenCover (Join-Path $SRC_DIR "Abc.Tests\Abc.Tests.csproj") `
            | Invoke-OpenCover -output $outxml
    }
    else {
        # For coverlet.msbuild the path must be absolute if we want the result to be
        # put within the directory for artifacts and not below the test project.
        Invoke-Coverlet $outxml
    }

    if ($NoReport) {
        Carp "On your request, we do not run ReportGenerator."
    }
    else {
        Invoke-ReportGenerator $outxml $outdir

        try {
            pushd $outdir

            cp -Force -Path "badge_combined.svg" -Destination (Join-Path ".." "$tool.svg")
            cp -Force -Path "Summary.txt" -Destination (Join-Path ".." "$tool.txt")
        }
        finally {
            popd
        }
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

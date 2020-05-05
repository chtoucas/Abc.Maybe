#Requires -Version 4.0

################################################################################
#region Preamble.

<#
.SYNOPSIS
Run the Code Coverage script and build human-readable reports.

.DESCRIPTION
Run the Code Coverage script w/ either Coverlet (default) or OpenCover,
then optionally build human-readable reports and badges.

Prerequesites: NuGet packages and tools must have been restored before. If not
the script may fail with not even a single warning... (eg w/ Coverlet).

OpenCover is slow when compared to Coverlet, but we get risk hotspots
(NPath complexity, crap score) and a list of unvisited methods.
Furthermore, the results differ slightly (LINQ and async so far) which
makes the two tools complementary --- line counts may differ too but
that's just a detail.

.PARAMETER OpenCover
Use OpenCover instead of Coverlet.

.PARAMETER NoReport
Do NOT build HTML/text reports and badges w/ ReportGenerator.
This option and -ReportOnly are mutually exclusive.

.PARAMETER ReportOnly
Do NOT run any Code Coverage tool.
This option and -NoReport are mutually exclusive.

.PARAMETER Help
Print help.

.EXAMPLE
PS> cover.ps1
Run Coverlet then build the human-readable reports.

.EXAMPLE
PS> cover.ps1 -x
Run OpenCover then build the human-readable reports.

.EXAMPLE
PS> cover.ps1 -OpenCover -NoReport
Run OpenCover, do NOT build human-readable reports and badges.
#>
[CmdletBinding()]
param(
    [Alias("x")] [switch] $OpenCover,
                 [switch] $NoReport,
                 [switch] $ReportOnly,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

New-Variable -Name "CONFIGURATION" -Value "Debug" -Scope Script -Option Constant

(Join-Path $SRC_DIR "Abc.Tests\Abc.Tests.csproj" -Resolve)
    | New-Variable -Name "OPENCOVER_REF_PROJECT" -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers.

function Write-Usage {
    Say @"

Run the Code Coverage script and build human-readable reports.

Usage: cover.ps1 [switches]
  -x|-OpenCover    use OpenCover instead of Coverlet.
     -NoReport     do NOT run ReportGenerator.
     -ReportOnly   do NOT run any Code Coverage tool.
  -h|-Help         print this help and exit.

"@
}

# ------------------------------------------------------------------------------

function Find-OpenCover {
    [CmdletBinding()]
    param()

    Write-Verbose "Finding OpenCover.Console.exe."

    $version = Get-PackageReferenceVersion $OPENCOVER_REF_PROJECT "OpenCover"

    if ($version -eq $null) {
        Croak "OpenCover is not referenced in ""$OPENCOVER_REF_PROJECT""."
    }

    $path = Join-Path ${Env:USERPROFILE} `
        ".nuget\packages\opencover\$version\tools\OpenCover.Console.exe"

    if (-not (Test-Path $path)) {
        Croak "Couldn't find OpenCover v$version where I expected it to be."
    }

    Write-Verbose "OpenCover.Console.exe found here: ""$path""."

    $path
}

#endregion
################################################################################
#region Tasks.

function Invoke-OpenCover {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $openCover,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $output
    )

    SAY-LOUD "Running OpenCover."

    $filters = `
        "+[Abc.Maybe]*",
        "-[Abc.Sketches]*",
        "-[Abc.Test*]*",
        "-[Abc*]System.Diagnostics.CodeAnalysis.*",
        "-[Abc*]System.Runtime.CompilerServices.*",
        "-[Abc*]Microsoft.CodeAnalysis.*"
    $filter = "$filters"

    # See https://github.com/opencover/opencover/wiki/Usage
    & $openCover -oldStyle -register:user `
        -hideskipped:All `
        -showunvisited `
        -output:$output `
        -target:dotnet.exe `
        -targetargs:"test -v quiet -c $CONFIGURATION --no-restore /p:DebugType=Full" `
        -filter:$filter `
        -excludebyattribute:*.ExcludeFromCodeCoverageAttribute `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "OpenCover failed."
}

# ------------------------------------------------------------------------------

function Invoke-Coverlet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $output
    )

    SAY-LOUD "Running Coverlet."

    $excludes = `
        "[Abc*]System.Diagnostics.CodeAnalysis.*",
        "[Abc*]System.Runtime.CompilerServices.*",
        "[Abc*]Microsoft.CodeAnalysis.*"
    $exclude = '\"' + ($excludes -Join ",") + '\"'

    & dotnet test -c $CONFIGURATION --no-restore `
        /p:CollectCoverage=true `
        /p:CoverletOutputFormat=opencover `
        /p:CoverletOutput=$output `
        /p:Include="[Abc.Maybe]*" `
        /p:Exclude=$exclude `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Coverlet failed."
}

# ------------------------------------------------------------------------------

function Invoke-ReportGenerator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $reports,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $targetdir
    )

    SAY-LOUD "Running ReportGenerator."

    & dotnet tool run reportgenerator `
        -verbosity:Warning `
        -reporttypes:"HtmlInline;Badges;TextSummary" `
        -reports:$reports `
        -targetdir:$targetdir `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "ReportGenerator failed."
}

#endregion
################################################################################
#region Main.

if ($Help) {
    Write-Usage
    exit 0
}

try {
    pushd $ROOT_DIR

    if ($ReportOnly -and $NoReport) {
        Croak "You cannot set both options -ReportOnly and -NoReport at the same time."
    }

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
        Find-OpenCover | Invoke-OpenCover -output $outxml
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
    Write-Host "An unexpected error occured." -BackgroundColor Red -ForegroundColor Yellow
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
}
finally {
    popd
}

#endregion
################################################################################

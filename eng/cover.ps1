# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Run the Code Coverage script and build human-readable reports.

.DESCRIPTION
Run the Code Coverage script w/ either Coverlet (default) or OpenCover,
then optionally build human-readable reports and badges.

This script does NOT execute an implicit restore, therefore it may fail with not
even a single warning... eg w/ Coverlet. If needed, use the option -Restore
which instructs the script to explicitly restore the required dependencies.

OpenCover is slow when compared to Coverlet, but we get risk hotspots
(NPath complexity, crap score) and a list of unvisited methods.
Furthermore, the results differ slightly (LINQ and async so far) which
makes the two tools complementary --- line counts may differ too but
that's just a detail.

.PARAMETER OpenCover
Use OpenCover instead of Coverlet.
Ignored if -NoCoverage is also set and equals $true.

.PARAMETER NoCoverage
Do NOT run any Code Coverage tool.
This option and -NoReport are mutually exclusive.

.PARAMETER NoReport
Do NOT build HTML/text reports and badges w/ ReportGenerator.
This option and -NoCoverage are mutually exclusive.

.PARAMETER Restore
Restore NuGet packages and tools before anything else.

.PARAMETER Help
Print help.

.EXAMPLE
PS> cover.ps1
Run Coverlet then build reports and badges.

.EXAMPLE
PS> cover.ps1 -x
Run OpenCover then build reports and badges.

.EXAMPLE
PS> cover.ps1 -OpenCover -NoReport
Run OpenCover, do NOT build reports and badges.
#>
[CmdletBinding()]
param(
    [Alias("x")] [switch] $OpenCover,
                 [switch] $NoCoverage,
                 [switch] $NoReport,
                 [switch] $Restore,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

(Join-Path $SRC_DIR "Abc.Tests\Abc.Tests.csproj" -Resolve) `
    | New-Variable -Name "OPENCOVER_REF_PROJECT" -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers.

function Write-Usage {
    Say @"

Run the Code Coverage script and build human-readable reports.

Usage: cover.ps1 [arguments]
  -x|-OpenCover   use OpenCover instead of Coverlet.
     -NoCoverage  do NOT run any Code Coverage tool.
     -NoReport    do NOT run ReportGenerator.
     -Restore     restore NuGet packages and tools before anything else.
  -h|-Help        print this help and exit.

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

function Invoke-Restore {
    [CmdletBinding()]
    param()

    Say-LOUDLY "Restoring dependencies, please wait..." -Invert

    Write-Verbose "Restoring tools."
    & dotnet tool restore | Out-Host

    Write-Verbose "Restoring NuGet packages."
    & dotnet restore | Out-Host
}

# ------------------------------------------------------------------------------

function Invoke-OpenCover {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $openCover,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $output
    )

    Say-LOUDLY "Running OpenCover." -Invert

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
        -targetargs:"test -v quiet -c $configuration --no-restore /p:DebugType=Full" `
        -filter:$filter `
        -excludebyattribute:*.ExcludeFromCodeCoverageAttribute `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "OpenCover failed."
}

# ------------------------------------------------------------------------------

function Invoke-Coverlet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $output
    )

    Say-LOUDLY "Running Coverlet." -Invert

    $excludes = `
        "[Abc*]System.Diagnostics.CodeAnalysis.*",
        "[Abc*]System.Runtime.CompilerServices.*",
        "[Abc*]Microsoft.CodeAnalysis.*"
    $exclude = '\"' + ($excludes -Join ",") + '\"'

    & dotnet test -c $configuration --no-restore `
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

    Say-LOUDLY "Running ReportGenerator." -Invert

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

    New-Variable -Name "Configuration" -Value "Debug" -Option ReadOnly

    if ($NoCoverage -and $NoReport) {
        Croak "You cannot set both options -NoCoverage and -NoReport at the same time."
    }

    $tool = if ($OpenCover) { "opencover" } else { "coverlet" }
    $outdir = Join-Path $ARTIFACTS_DIR $tool
    $outxml = Join-Path $outdir "$tool.xml"

    # Create the directory if it does not already exist.
    # Do not remove this, it must be done before calling OpenCover.
    if (-not (Test-Path $outdir)) {
        mkdir -Force -Path $outdir | Out-Null
    }

    if ($Restore) { Invoke-Restore }
    exit

    if ($NoCoverage) {
        Carp "On your request, we do not run any Code Coverage tool."
    }
    else {
        if ($OpenCover) {
            Find-OpenCover | Invoke-OpenCover -Configuration $Configuration -Output $outxml
        }
        else {
            # For coverlet.msbuild the path must be absolute if we want the result to be
            # put within the directory for artifacts and not below the test project.
            Invoke-Coverlet -Configuration $Configuration -Output $outxml
        }
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
    Confess $_
}
finally {
    popd
}

#endregion
################################################################################

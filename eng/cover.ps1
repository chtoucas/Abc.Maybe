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

#endregion
################################################################################
#region Tasks.

function Invoke-Restore {
    [CmdletBinding()]
    param()

    Say-LOUDLY "`nRestoring dependencies, please wait..."

    Restore-NETFrameworkTools
    Restore-NETCoreTools
    Restore-Solution

    Say-Softly "Dependencies successfully restored."
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

    Say-LOUDLY "`nRunning OpenCover."

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
        -targetargs:"test -v quiet -c $configuration --nologo --no-restore /p:DebugType=Full" `
        -filter:$filter `
        -excludebyattribute:*.ExcludeFromCodeCoverageAttribute `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "OpenCover failed."

    Say-Softly "OpenCover completed successfully."
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

    Say-LOUDLY "`nRunning Coverlet."

    $excludes = `
        "[Abc*]System.Diagnostics.CodeAnalysis.*",
        "[Abc*]System.Runtime.CompilerServices.*",
        "[Abc*]Microsoft.CodeAnalysis.*"
    $exclude = '\"' + ($excludes -Join ",") + '\"'

    & dotnet test -c $configuration --nologo --no-restore `
        /p:CollectCoverage=true `
        /p:CoverletOutputFormat=opencover `
        /p:CoverletOutput=$output `
        /p:Include="[Abc.Maybe]*" `
        /p:Exclude=$exclude `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Coverlet failed."

    Say-Softly "Coverlet completed successfully."
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

    Say-LOUDLY "`nRunning ReportGenerator."

    & dotnet tool run reportgenerator `
        -verbosity:Warning `
        -reporttypes:"HtmlInline;Badges;TextSummary" `
        -reports:$reports `
        -targetdir:$targetdir `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "ReportGenerator failed."

    Say-Softly "ReportGenerator completed successfully."
}

#endregion
################################################################################
#region Main.

if ($Help) {
    Write-Usage
    exit 0
}

Say "This is the Code Coverage script."

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

    if ($NoCoverage) {
        Carp "`nOn your request, we do not run any Code Coverage tool."
    }
    else {
        if ($OpenCover) {
            Find-OpenCover -Fatal `
                | Invoke-OpenCover -Configuration $Configuration -Output $outxml
        }
        else {
            # For coverlet.msbuild the path must be absolute if we want the result to be
            # put within the directory for artifacts and not below the test project.
            Invoke-Coverlet -Configuration $Configuration -Output $outxml
        }
    }

    if ($NoReport) {
        Carp "`nOn your request, we do not run ReportGenerator."
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

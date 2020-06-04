# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Run the Code Coverage script and build human-readable reports.

.DESCRIPTION
Run the Code Coverage script w/ either Coverlet (default) or OpenCover,
then optionally build human-readable reports and badges.

This script does NOT execute an implicit restore. If needed, use the option
-Restore which instructs the script to explicitly restore the required
dependencies.

OpenCover is slow when compared to Coverlet, but we get risk hotspots
(NPath complexity, crap score) and a list of unvisited methods.
Furthermore, the results differ slightly (LINQ and async so far) which
makes the two tools complementary --- line counts may differ too but
that's just a detail.

.PARAMETER Configuration
The configuration to test the solution for. Default (explicit) = "Debug".

.PARAMETER OpenCover
Use OpenCover instead of Coverlet? *Only works on Windows*
Ignored if -NoCoverage is also set and equals $true.

.PARAMETER NoCoverage
Do NOT run any Code Coverage tool?
This option and -NoReport are mutually exclusive.

.PARAMETER NoReport
Do NOT build HTML/text reports and badges w/ ReportGenerator?
This option and -NoCoverage are mutually exclusive.

.PARAMETER NoRestore
Do not restore the solution?

.PARAMETER RestoreTools
Restore OpenCover and ReportGenerator before anything else?

.PARAMETER MyVerbose
Verbose mode? Print the settings in use before compiling each assembly.

.PARAMETER Help
Print help text then exit?
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration = "Debug",

                 [switch] $OpenCover,
                 [switch] $NoCoverage,
                 [switch] $NoReport,

                 [switch] $NoRestore,
                 [switch] $RestoreTools,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

#endregion
################################################################################
#region Helpers.

function Print-Help {
    say @"

Run the Code Coverage script and build human-readable reports.

Usage: cover.ps1 [arguments]
  -c|-Configuration  the configuration to test the solution for.

     -OpenCover      use OpenCover instead of Coverlet?
     -NoCoverage     do NOT run any Code Coverage tool?
     -NoReport       do NOT run ReportGenerator?

     -NoRestore      do not restore the solution?
     -RestoreTools   restore OpenCover and ReportGenerator before anything else?
  -h|-Help           print this help then exit?

Examples.
> cover.ps1                       # Run Coverlet then build reports and badges
> cover.ps1 -OpenCover            # Run OpenCover then build reports and badges
> cover.ps1 -OpenCover -NoReport  # Run OpenCover, do NOT build reports and badges

Looking for more help?
> Get-Help -Detailed cover.ps1

"@
}

#endregion
################################################################################
#region Tasks.

function Invoke-RestoreTools {
    [CmdletBinding()]
    param()

    SAY-LOUDLY "`nRestoring dependencies, please wait..."

    # OpenCover.
    Restore-NETFxTools
    # Report Generator.
    Restore-NETCoreTools

    say-softly "Dependencies successfully restored."
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
        [string] $output,

        [switch] $noRestore
    )

    SAY-LOUDLY "`nRunning Coverlet (MSBuild)."

    $args = "--nologo", "-c:$configuration", "/p:RunAnalyzers=false"
    if ($noRestore) { $args += "--no-restore" }

    # Namespaces to exclude, files "src\(Missing|Nullable)Atributes.cs":
    # - System
    # - System.Diagnostics.CodeAnalysis
    # - System.Diagnostics.Contracts
    # - System.Runtime.CompilerServices (no longer needed?)
    # - Microsoft.CodeAnalysis          (not needed w/ Coverlet)
    #   for "Microsoft.CodeAnalysis.EmbeddedAttribute"
    # Coverlet formats:
    # - /p:Exclude=\"XXX,YYY,ZZZ\"
    # - /p:Exclude="XXX%2cYYY%2cZZZ"
    # For instance,
    #   $excludes = `
    #       "[Abc*]System.Diagnostics.CodeAnalysis.*",
    #       "[Abc*]Microsoft.CodeAnalysis.*"
    #   $exclude = '\"' + ($excludes -join ",") + '\"'
    #   $exclude = '"' + ($excludes -join "%2c") + '"'

    & dotnet test $args `
        /p:CollectCoverage=true `
        /p:CoverletOutputFormat=opencover `
        /p:CoverletOutput=$output `
        /p:Include="[Abc.Maybe]*" `
        /p:Exclude="[Abc.Maybe]System.*"
        || die "Coverlet failed."

    say-softly "Coverlet completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-Coverlet2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [switch] $noRestore
    )

    SAY-LOUDLY "`nRunning Coverlet (Collector)."

    $args = "--nologo", "-c:$configuration", "/p:RunAnalyzers=false"
    if ($noRestore) { $args += "--no-restore" }

    & dotnet test $args `
        --collect:"XPlat Code Coverage" `
        --settings coverlet.runsettings `
        || die "Coverlet failed."

    say-softly "Coverlet completed successfully."
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
        [string] $output,

        [switch] $noRestore
    )

    SAY-LOUDLY "`nRunning OpenCover."

    if (-not $IsWindows) { die "OpenCover.exe only works on Windows." }

    # I prefer to restore the solution outside the OpenCover process.
    if (-not $noRestore) { Restore-Solution }

    # See comments in Invoke-Coverlet.
    $filters = `
        "+[Abc.Maybe]*",
        "-[Abc.Sketches]*",
        "-[Abc.Test*]*",
        "-[Abc*]System.*",
        "-[Abc*]Microsoft.*"
    $filter = "$filters"

    $dotnetargs = "-c $configuration /p:RunAnalyzers=false /p:DebugType=full"

    # See https://github.com/opencover/opencover/wiki/Usage
    & $openCover `
        -oldStyle `
        -register:user `
        -hideskipped:All `
        -showunvisited `
        -output:$output `
        -target:dotnet.exe `
        -targetargs:"test -v quiet --no-restore --nologo $dotnetargs" `
        -filter:$filter `
        -excludebyattribute:*.ExcludeFromCodeCoverageAttribute
        || die "OpenCover failed."

    say-softly "OpenCover completed successfully."
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

    SAY-LOUDLY "`nRunning ReportGenerator."

    & dotnet tool run reportgenerator `
        -verbosity:Warning `
        -reporttypes:"HtmlInline;Badges;TextSummary" `
        -reports:$reports `
        -targetdir:$targetdir
        || die "ReportGenerator failed."

    say-softly "ReportGenerator completed successfully."
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Hello "this is the Code Coverage script."

try {
    ___BEGIN___

    if ($NoCoverage -and $NoReport) {
        die "You cannot set both options -NoCoverage and -NoReport at the same time."
    }

    $tool   = $OpenCover ? "opencover" : "coverlet"
    $outDir = Join-Path $ARTIFACTS_DIR $tool
    $outXml = Join-Path $outDir "$tool.xml"

    # Create the directory if it does not already exist.
    # Do not remove this, it must be done before calling OpenCover.
    if (-not (Test-Path $outDir)) {
        mkdir -Force -Path $outDir | Out-Null
    }

    if ($RestoreTools) { Invoke-RestoreTools }

    if ($NoCoverage) {
        say "`nOn your request, we do not run any Code Coverage tool."
    }
    else {
        if ($OpenCover) {
            Find-OpenCover -ExitOnError `
                | Invoke-OpenCover `
                    -Configuration $Configuration `
                    -Output        $outXml `
                    -NoRestore:    $NoRestore
        }
        else {
            # For coverlet.msbuild the path must be absolute if we want the
            # result to be put within the directory for artifacts and not below
            # the test project.
            Invoke-Coverlet `
                -Configuration $Configuration `
                -Output        $outXml `
                -NoRestore:    $NoRestore
        }
    }

    if (-not $OpenCover) {
        $platform = (Get-MaxPlatform).ToLowerInvariant()

        $outXml = Join-Path $outDir "$tool.$platform.xml"
    }

    if ($NoReport) {
        say "`nOn your request, we do not run ReportGenerator."
    }
    else {
        Invoke-ReportGenerator $outXml $outDir

        try {
            pushd $outDir

            cp -Force "badge_combined.svg" (Join-Path ".." "$tool.svg")
            cp -Force "Summary.txt" (Join-Path ".." "$tool.txt")
        }
        finally {
            popd
        }
    }
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

#endregion
################################################################################

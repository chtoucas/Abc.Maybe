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

.PARAMETER Platform
The platform to test the solution for.

.PARAMETER Threshold
Threshold below which a build will fail.
Ignored if -XPlat is also set and equals $true (current limitation of Coverlet).

.PARAMETER XPlat
Use "coverlet.collector" instead of "coverlet.msbuild?
When this option is set and equals $true, we NEVER run ReportGenerator, we could
make it work but I don't think it's worth the trouble.

.PARAMETER OpenCover
Use OpenCover instead of Coverlet? *Only works on Windows*
Ignored if -NoCoverage is also set and equals $true.

.PARAMETER NoCoverage
Do NOT run any Code Coverage tool?
This option and -NoReport are mutually exclusive.

.PARAMETER NoReport
Do NOT build HTML/text reports and badges w/ ReportGenerator?
This option and -NoCoverage are mutually exclusive.

.PARAMETER Deterministic
Deterministic build?
Ignored if -OpenCover is also set and equals $true.

Being deterministic simply means setting ContinuousIntegrationBuild to true.
Obviously, on a CI server, a build is "always" deterministic.

.PARAMETER NoSourceLink
Disable Source Link?
Ignored if -Deterministic is NOT equals to $true.

.PARAMETER Reset
Delete previously created artifacts?

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

    [Parameter(Mandatory = $false, Position = 1)]
    [Alias("f")] [string] $Platform,

    [Parameter(Mandatory = $false, Position = 2)]
    [Alias("t")] [string] $Threshold,

    [Alias("x")] [switch] $XPlat,
                 [switch] $OpenCover,
                 [switch] $NoCoverage,
                 [switch] $NoReport,

                 [switch] $Deterministic,
                 [switch] $NoSourceLink,

                 [switch] $Reset,
                 [switch] $NoRestore,
                 [switch] $RestoreTools,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "lib\abc.ps1")

# ------------------------------------------------------------------------------

# Nota bene: using a project rather than a solution may speed up things a bit by
# ignoring unused platforms referenced by the other projects.
const TEST_PROJECT_NAME "Abc.Tests"
const TEST_PROJECT (Join-Path $SRC_DIR $TEST_PROJECT_NAME -Resolve)

#endregion
################################################################################
#region Helpers.

function Print-Help {
    say @"

Run the Code Coverage script and build human-readable reports.

Usage: cover.ps1 [arguments]
  -c|-Configuration  the configuration to test the solution for
  -f|-Platform       the platform to test the solution for.
  -t|-Threshold      threshold below which a build will fail.

  -x|-XPlat          use "coverlet.collector" instead of "coverlet.msbuild"?
     -OpenCover      use OpenCover instead of Coverlet?
     -NoCoverage     do NOT run any Code Coverage tool?
     -NoReport       do NOT run ReportGenerator?

     -Deterministic  deterministic build?
     -NoSourceLink   disable Source Link?

     -Reset          delete previously created artifacts?
     -NoRestore      do not restore the solution?
     -RestoreTools   restore OpenCover and ReportGenerator before anything else?
  -v|-MyVerbose      display settings used to compile each DLL?
  -h|-Help           print this help then exit?

Examples.
> cover.ps1                       # Run Coverlet then build reports and badges
> cover.ps1 -OpenCover            # Run OpenCover then build reports and badges
> cover.ps1 -OpenCover -NoReport  # Run OpenCover, do NOT build reports and badges

The Code Coverage command we use on Azure Pipelines is equivalent to:
> cover.ps1 -XPlat -Deterministic

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

function Invoke-CoverletMSBuild {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $platform,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $outXml,

        [Parameter(Mandatory = $false)]
        [string] $threshold,

        [switch] $deterministic,
        [switch] $noSourceLink,

        [switch] $noRestore,
        [switch] $myVerbose
    )

    SAY-LOUDLY "`nRunning Coverlet (MSBuild)."

    $args = "--nologo", "-c:$configuration", "/p:RunAnalyzers=false"
    if ($platform)  { $args += "/p:TargetFrameworks=$platform" }
    if ($threshold) { $args += "/p:Threshold=$threshold" }
    if ($noRestore) { $args += "--no-restore" }
    if ($myVerbose) { $args += "-v:minimal", "/p:PrintSettings=true" }

    if ($deterministic) {
        $args += "/p:ContinuousIntegrationBuild=true"

        if ($noSourceLink) {
            $args += "/p:EnableSourceLink=false"
        }
        else {
            # From "src\D.B.targets", ContinuousIntegrationBuild = true imply
            # EnableSourceLink = true.
            # For now, we must set "DeterministicSourcePaths" to false; see
            # https://github.com/coverlet-coverage/coverlet/issues/882
            $args += "/p:UseSourceLink=true", "/p:DeterministicSourcePaths=false"
        }
    }

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

    & dotnet test $TEST_PROJECT $args `
        /p:CollectCoverage=true `
        /p:CoverletOutputFormat=opencover `
        /p:CoverletOutput=$outXml `
        /p:Include="[Abc.Maybe]*" `
        /p:Exclude="[Abc.Maybe]System.*"
        || die "Coverlet failed."

    say-softly "Coverlet completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-CoverletXPlat {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $platform,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $outDir,

        [switch] $deterministic,
        [switch] $noSourceLink,

        [switch] $noRestore,
        [switch] $myVerbose
    )

    SAY-LOUDLY "`nRunning Coverlet (XPlat)."

    $args = "--nologo", "-c:$configuration", "/p:RunAnalyzers=false"
    if ($platform)  { $args += "/p:TargetFrameworks=$platform" }
    if ($noRestore) { $args += "--no-restore" }
    if ($myVerbose) { $args += "-v:minimal", "/p:PrintSettings=true" }

    $runsettings = @()
    if ($deterministic) {
        # See comments in Invoke-CoverletMSBuild.
        $args += "/p:ContinuousIntegrationBuild=true"

        if ($noSourceLink) {
            $args += "/p:EnableSourceLink=false"
            $runsettings += "DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.UseSourceLink=false"
        }
        else {
            $args += "/p:DeterministicSourcePaths=false"
        }
    }
    else {
        # Here, ContinuousIntegrationBuild = false, which disables Source Link.
        # We instruct Coverlet not to use Source Link, even if it is not strictly
        # necessary, Coverlet will ignore it anyway.
        $runsettings += "DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.UseSourceLink=false"
    }

    # "dotnet test" changes $outDir by appending a GUID whose value is not predictable.
    & dotnet test $TEST_PROJECT $args `
        --results-directory $outDir `
        --collect:"XPlat Code Coverage" `
        --settings ".config\coverlet.runsettings" `
        -- $runsettings
        || die "Coverlet failed."

    say-softly "Coverlet completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-OpenCover {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $openCover,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $platform,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $outXml,

        [switch] $noRestore,
        [switch] $myVerbose
    )

    SAY-LOUDLY "`nRunning OpenCover."

    if (-not $IsWindows) { die "OpenCover.exe only works on Windows." }

    # I prefer to restore the solution outside the OpenCover process.
    if (-not $noRestore) { Restore-Solution }

    # See comments in Invoke-CoverletMSBuild.
    $filters = `
        "+[Abc.Maybe]*",
        "-[Abc.Sketches]*",
        "-[Abc.Test*]*",
        "-[Abc*]System.*",
        "-[Abc*]Microsoft.*"
    $filter = "$filters"

    # With OpenCover, we only work with one platform at a time.
    # Remark: when $platform is empty, we use the default platform (SmokeBuild).
    $args = "-c:$configuration",
        "/p:DebugType=full",
        "/p:SmokeBuild=true",
        "/p:RunAnalyzers=false"
    if ($platform)  { $args += "/p:TargetFrameworks=$platform" }
    if ($myVerbose) { $args += "-v:minimal", "/p:PrintSettings=true" }
               else { $args += "-v:quiet" }

    $dotnetargs = "$args"

    # See https://github.com/opencover/opencover/wiki/Usage
    & $openCover `
        -oldStyle `
        -register:user `
        -hideskipped:All `
        -showunvisited `
        -output:$outXml `
        -target:dotnet.exe `
        -targetargs:"test $TEST_PROJECT --no-restore --nologo $dotnetargs" `
        -filter:$filter `
        -excludebyattribute:*.ExcludeFromCodeCoverageAttribute
        || die "OpenCover failed."

    say-softly "OpenCover completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-ReportGenerator {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $reports,

        [Parameter(Mandatory = $true)]
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

    if ($Reset -and (yesno "`nDelete artifacts for ""$tool""?")) {
        Remove-Dir $outDir
        say-softly "Directory ""$outDir"" was deleted."
    }

    # Create the directory if it does not already exist.
    # Do not remove this, it must be done before calling OpenCover.
    if (-not (Test-Path $outDir)) {
        mkdir -Force -Path $outDir | Out-Null
    }

    if ($RestoreTools) { Invoke-RestoreTools }

    if ($XPlat) {
        Invoke-CoverletXPlat `
            -Configuration $Configuration `
            -Platform      $platform `
            -OutDir        $outDir `
            -Deterministic:$Deterministic `
            -NoSourceLink: $NoSourceLink `
            -NoRestore:    $NoRestore `
            -MyVerbose:    $myVerbose

        # We stop here, see the comments within Invoke-CoverletXPlat.
        exit
    }

    if ($NoCoverage) {
        say "`nOn your request, we do not run any Code Coverage tool."
    }
    else {
        if ($OpenCover) {
            Find-OpenCover -ExitOnError `
                | Invoke-OpenCover `
                    -Configuration $Configuration `
                    -Platform      $platform `
                    -OutXml        $outXml `
                    -NoRestore:    $NoRestore `
                    -MyVerbose:    $myVerbose
        }
        else {
            # For coverlet.msbuild the path must be absolute if we want the
            # result to be put within the directory for artifacts and not below
            # the test project.
            Invoke-CoverletMSBuild `
                -Configuration $Configuration `
                -Platform      $platform `
                -Threshold     $Threshold `
                -OutXml        $outXml `
                -Deterministic:$Deterministic `
                -NoSourceLink: $NoSourceLink `
                -NoRestore:    $NoRestore `
                -MyVerbose:    $myVerbose
        }
    }

    if ($NoReport) {
        say "`nOn your request, we do not run ReportGenerator."
    }
    else {
        $skipBadges = $true

        if ($OpenCover) {
            $reports   = $outXml
            $targetDir = Join-Path $outDir "html"
        } else {
            if ($Platform) {
                $reports   = Join-Path $outDir "$tool.$Platform.xml"
                $targetDir = Join-Path $outDir "html-$Platform"
            } else {
                # Remark: here we grab any report within $outDir.
                # There is one case when we shouldn't do that: SMOKE_BUILD = true
                if ($Env:SMOKE_BUILD -eq "true") {
                    $files = Get-ChildItem $outDir -Filter "$tool.*.xml" -File
                    $count = ($files | Measure-Object).Count
                    if ($count -ne 1) { warn "SMOKE_BUILD = true. Maybe use -Reset?" }
                }
                else {
                    $skipBadges = $false
                }

                $reports   = Join-Path $outDir "$tool.*.xml"
                $targetDir = Join-Path $outDir "html"
            }
        }

        Invoke-ReportGenerator -Reports $reports -TargetDir $targetDir

        if ($skipBadges) {
            say-softly "Skipping badges."
        }
        else {
            say "Creating badges."
            try {
                pushd $targetDir

                cp -Force "badge_combined.svg" (Join-Path "..\.." "$tool.svg")
                cp -Force "Summary.txt" (Join-Path "..\.." "$tool.txt")
            }
            finally {
                popd
            }
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

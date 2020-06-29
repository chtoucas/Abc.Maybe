# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Create a NuGet package.

.DESCRIPTION
Create a NuGet package.
The default behaviour is to build a local package on a developer machine.

.PARAMETER Official
Create an official package as opposed to a local package?

.PARAMETER Freeze
Create a package ready to be published to NuGet.Org?

This is a meta-option. The resulting package is no different from the one you
would get using only -Official but, in addition, the script resets the
repository and stops when there are uncommited changes or if it cannot retrieve
the git metadata.

If this behaviour happens to be too strict and you are in a hurry, you can use:
PS> pack.ps1 -Official -Force -Yes
In that event, do not forget to reset the local NuGet feed/cache after you
publish the package to NuGet.Org.

.PARAMETER Reset
Hard clean (reset) the source directory before anything else?

.PARAMETER Force
Currently does only one thing, enable Source Link even if there are uncommited
changes.
Ignored if -Freeze is also set and equals $true.

.PARAMETER Yes
Do not ask for confirmation, mostly?
Only one exception: after having created a package w/ option -Freeze on, the
script will enter in an interactive mode.

.PARAMETER MyVerbose
Verbose mode? Print the settings in use before compiling each assembly.

.PARAMETER Help
Print help text then exit?
#>
[CmdletBinding()]
param(
                 [switch] $Official,
                 [switch] $Freeze,

                 [switch] $Reset,
                 [switch] $Force,
    [Alias("y")] [switch] $Yes,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "lib\abc.ps1")

#endregion
################################################################################
#region Helpers

function Print-Help {
    say @"

Create a NuGet package for Abc.Maybe.
The default behaviour is to build a local package on a developer machine.

Usage: pack.ps1 [arguments]
     -Official   create an official package as opposed to a local package?
     -Freeze     create a package ready to be published to NuGet.Org?

     -Reset      reset the solution before anything else?
     -Force      enable Source Link even if there are uncommited changes?
  -y|-Yes        do not ask for confirmation, mostly?
  -v|-MyVerbose  display settings used to compile each DLL?
  -h|-Help       print this help then exit?

Examples.
> pack.ps1                        # Create a local package
> pack.ps1 -Official -Yes -Force  # Create an official package, ignore uncommited changes
> pack.ps1 -Freeze                # Create a package ready to be published to NuGet.Org

Looking for more help?
> Get-Help -Detailed pack.ps1

"@
}

# ------------------------------------------------------------------------------

# Find commit hash and branch name.
function Get-GitMetadata {
    [CmdletBinding()]
    param(
        [switch] $yes,
        [switch] $exitOnError
    )

    say "Retrieving git metadata."

    $git = whereis "git.exe"

    if (-not $git) {
        if ($exitOnError) { die "Could not find git.exe." }
        elseif ($yes)     { warn "The package description won't include any git metadata." }
        else              { guard "Continue even without any git metadata?" }

        return @("", "", $false)
    }

    # Keep Approve-GitStatus before $yes: we always want to see a warning
    # when there are uncommited changes.
    $ok = Approve-GitStatus $git -ExitOnError:$exitOnError

    $branch = "" ; $commit = ""
    if ($ok -or $yes -or (yesno "There are uncommited changes, force retrieval of git metadata?")) {
        $branch = Get-GitBranch     $git -ExitOnError:$exitOnError
        $commit = Get-GitCommitHash $git -ExitOnError:$exitOnError
    }

    if ($branch -eq "") {
        warn "The branch name will be empty."
    }
    elseif ($branch -ne "master") {
        $onerr = $exitOnError ? "die" : "warn"
        . $onerr "You are not on the branch ""master""."
    }

    if ($commit -eq "") { warn "The commit hash will be empty." }

    return @($branch, $commit, $ok)
}

# ------------------------------------------------------------------------------

# In the past, we used to generate the id's within MSBuild but then it is nearly
# impossible to override the global properties PackageVersion and VersionSuffix.
# Besides that, generating the id's outside ensures that all assemblies inherit
# the same id's. This could have been done in pure PS...
Add-Type @'
using System;
using System.Management.Automation;

[Cmdlet(VerbsCommon.Get, "BuildNumbers")]
public class GetBuildNumbersCmdlet : Cmdlet
{
    protected override void BeginProcessing()
    {
        WriteVerbose("Getting the build numbers.");

        var orig = new DateTime(2020, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        var now  = DateTime.UtcNow;
        var am   = now.Hour < 12;

        var mon = new DateTime(now.Year, now.Month, now.Day, am ? 0 : 12, 0, 0, DateTimeKind.Utc);

        var halfdays = 2 * (now - orig).Days + (am ? 0 : 1);
        var seconds  = (now - mon).TotalSeconds;

        var buildnum  = (ushort)halfdays;
        var revnum    = (ushort)seconds;
        var timestamp = String.Format("{0:yyyyMMdd}T{0:HHmmss}", now);

        WriteDebug($"Build number: \"{buildnum}\".");
        WriteDebug($"Build revision: \"{revnum}\".");
        WriteDebug($"Build timestamp: \"{timestamp}\".");

        WriteObject(buildnum);
        WriteObject(revnum);
        WriteObject(timestamp);
    }
}
'@ -PassThru | % Assembly | Import-Module

# ------------------------------------------------------------------------------

function Get-PackageVersionSuffix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $timestamp,

        [switch] $local
    )

    say "Getting package suffix/version."

    # For a local package, we ensure that it is seen as a prerelease of what
    # could be the next version (it is always ahead the latest public version),
    # and that it has a unique version number so that it gets its own separate
    # entry in the cache. Examples:
    # - "1.2.3-beta4" < "1.2.3-beta5-20201231T235959"
    # - "1.2.3"       < "1.2.4-20201231T235959"
    # Notice that the transformation does respect the original ordering
    #   "1.2.3-beta5-20201231T235959" < "1.2.4-20201231T235959"
    # Local packages are ahead the current public release and stay behind
    # the next one:
    #   current "1.2.3-beta4" < local "1.2.3-beta5-20201231T235959" < next "1.2.3-beta5"  or "1.2.4"
    #   current "1.2.3"       < local "1.2.4-20201231T235959"       < next "1.2.4-alpha1" or "1.2.4"
    # Remark: these version numbers are timestamped, therefore the manip
    # should not be controlled via MSBuild, otherwise each target might get
    # a different timestamp during the same build.
    # By the way, assemblies have a steady version number,
    # AssemblyVersion = 1.2.0.0 (see "src\Retail.props").
    # Remark: on a CI server (AZP), we use a slightly different schema,
    # - "1.2.3-beta4" > "1.2.3-beta5-20201231.{rev}"
    # - "1.2.3"       > "1.2.4-20201231.{rev}"
    # where "rev" is a counter reset daily (formally we also append a few
    # metadata).
    # All together, current < ci, local (~ latest win) < next.

    $pkgsuffix = ""
    $pkgversion = Get-PackageVersion $projectName -vNext:$local -AsString

    if ($local) {
        if (-not $timestamp) {
            # BuildNumber and RevisionNumber won't match the timestamp.
            warn "The timestamp is empty, let's regenerate it."
            $timestamp = "{0:yyyyMMdd}T{0:HHmmss}" -f (Get-Date).ToUniversalTime()
        }

        $pkgsuffix  = $timestamp
        $pkgversion = "$pkgversion-$pkgsuffix"
    }

    ___debug "Package version: ""$pkgversion""."
    ___debug "Package suffix:  ""$pkgsuffix""."

     @($pkgversion, $pkgsuffix)
}

# ------------------------------------------------------------------------------

function Get-PackageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $packageVersion,

        [switch] $local,
        [switch] $yes
    )

    say "Getting package filepath."

    $path = Join-Path ($local ? $PKG_DEV_OUTDIR : $PKG_OUTDIR) "$projectName.$packageVersion.nupkg"

    ___debug "Package file: ""$path""."

    # Is there a dangling package file?
    # NB: not necessary for local packages, the filename is unique.
    if (-not $local -and (Test-Path $path)) {
        if (-not $yes) {
            warn "A package with the same version ($packageVersion) already exists."
            guard "Do you wish to proceed anyway?"
        }

        # Not necessary, dotnet will replace it, but to avoid any ambiguity
        # I prefer to remove it anyway.
        say "  The old package file will be removed now."
        rm $path
    }

    $path
}

#endregion
################################################################################
#region Tasks.

function Invoke-Pack {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageVersion,

        [Parameter(Mandatory = $false)]
        [string] $packageSuffix,

        [Parameter(Mandatory = $false)]
        [string] $repositoryBranch,

        [Parameter(Mandatory = $false)]
        [string] $repositoryCommit,

        [Parameter(Mandatory = $false)]
        [string] $buildNumber,

        [Parameter(Mandatory = $false)]
        [string] $revisionNumber,

        [switch] $enableSourceLink,
        [switch] $local,
        [switch] $myVerbose
    )

    "`nPacking v$packageVersion --- build {0}, rev. {1} on branch ""{2}"", commit ""{3}""." -f `
        ($buildNumber ? $buildNumber : "???"),
        ($revisionNumber ? $revisionNumber : "???"),
        ($repositoryBranch ? $repositoryBranch : "???"),
        ($repositoryCommit ? $repositoryCommit.Substring(0, 7) : "???") `
        | SAY-LOUDLY

    if (-not $enableSourceLink) {
        warn "Source Link won't be enabled. Maybe use -Force?"
    }

    $args = "-c:Release",
        "/p:ContinuousIntegrationBuild=true",
        ("/p:EnableSourceLink=" + ($enableSourceLink ? "true" : "false")),
        "/p:SmokeBuild=false",
        "/p:Retail=true",
        "/p:PackageSuffix=$packageSuffix",
        "/p:BuildNumber=$buildNumber",
        "/p:RevisionNumber=$revisionNumber",
        "/p:RepositoryCommit=$repositoryCommit",
        "/p:RepositoryBranch=$repositoryBranch"

    if ($local) { $args += "/p:vNext=true" }
    # Verbose mode?
    if ($myVerbose) { $args += "/p:PrintSettings=true" }

    $output  = $local ? $PKG_DEV_OUTDIR : $PKG_OUTDIR
    $project = Join-Path $SRC_DIR $projectName -Resolve

    & dotnet pack $project --nologo $args --output $output
        || die "Pack task failed."

    if ($local) {
        say-softly "Local package successfully created."
    }
    else {
        say-softly "Official package successfully created."
    }
}

# ------------------------------------------------------------------------------

function Invoke-PushLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $packageFile,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $packageVersion
    )

    SAY-LOUDLY "`nPushing the package to the local NuGet feed/cache."

    # Local "push" doesn't store packages in a hierarchical folder structure;
    # see https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-push
    # It means that we could have created the package directly in
    # $NUGET_LOCAL_FEED but it seems cleaner to keep creation and publication
    # separate. Also, if Microsoft ever decided to change the behaviour of
    # a local "push", we won't have to update this script (but maybe reset.ps1).

    & dotnet nuget push $packageFile -s $NUGET_LOCAL_FEED --force-english-output
        || die "Failed to publish package to local NuGet feed."

    # If the following task fails, we should remove the package from the feed,
    # otherwise, later on, the package will be restored to the global cache.
    # This is not such a big problem, but I prefer not to pollute it with
    # local packages (or versions we are going to publish).
    say "Updating the local NuGet cache."

    & dotnet restore $NUGET_CACHING_PROJECT /p:AbcPackageVersion=$packageVersion
        || die "Failed to update the local NuGet cache."

    say-softly "Package successfully installed."
}

# ------------------------------------------------------------------------------

function Invoke-Publish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageFile
    )

    SAY-LOUDLY "`nPublishing the package -or- Preparing the command to do so."

    $args = @("--force-english-output")

    #$source = Read-Host "Source [empty to push to the default source]"
    #if ($source) { $args += "-s $source" }

    #$apiKey = Read-Host "API key [empty for no key]"
    #if ($apiKey) { $args += "-k $apiKey" }

    if (yesno "Do you want me to publish the package for you?") {
        & dotnet nuget push $packageFile $args
            || die "Failed to publish the package."

        say-softly "Package successfully published."
    }
    else {
        SAY-LOUDLY "`n---`nTo publish the package:"
        SAY-LOUDLY "> dotnet nuget push $packageFile $args"
    }
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

if ($Freeze -or $Official) {
    Hello "this is the NuGet package creation script for Abc.Maybe."
}
else {
    Hello "this is the NuGet package creation script for Abc.Maybe (local mode)."
}

readonly ProjectName "Abc.Maybe"

try {
    ___BEGIN___

    $local = -not ($Freeze -or $Official)

    SAY-LOUDLY "`nInitialisation."

    # 1. Reset the source tree.
    if ($Freeze -or $Reset) { Reset-SourceTree -Yes:($Freeze -or $Yes) }
    # 2. Get the git metadata.
    $branch, $commit, $steady = Get-GitMetadata -Yes:$Yes -ExitOnError:$Freeze
    # 3. Generate build numbers.
    say "Generating build numbers."
    $buildNumber, $revisionNumber, $timestamp = Get-BuildNumbers
    # 4. Get package suffix/version.
    $pkgversion, $pkgsuffix = Get-PackageVersionSuffix $ProjectName $timestamp -Local:$local
    # 5. Get the package filepath.
    $pkgfile = Get-PackageFile $ProjectName $pkgversion -Yes:($Freeze -or $Yes) -Local:$local

    Invoke-Pack `
        -ProjectName      $ProjectName `
        -PackageVersion   $pkgversion `
        -PackageSuffix    $pkgsuffix `
        -RepositoryBranch $branch `
        -RepositoryCommit $commit `
        -BuildNumber      $buildNumber `
        -RevisionNumber   $revisionNumber `
        -EnableSourceLink:($Force -or $steady) `
        -Local:           $local `
        -MyVerbose:       $MyVerbose

    # Post-actions.
    if ($local) {
        Invoke-PushLocal $pkgfile $pkgversion
    }
    else {
        if ($Freeze) {
            # Now, all local packages should be obsoleted. Traces of them can be
            # found within the directories "test" and $PKG_DEV_OUTDIR, but
            # also in the local NuGet cache/feed.
            # We should also remove any reference to a released package with the
            # same version. Failing to do so would mean that, after publishing
            # the package to NuGet.Org, "test-package.ps1" could still test a
            # package from the local NuGet cache/feed not the one from NuGet.Org.
            Reset-TestTree            -Yes:$true
            Reset-LocalPackagesOutDir -Yes:$true
            Reset-LocalNuGet          -Yes:$true

            Invoke-Publish $pkgfile
        }
        else {
            # If we don't reset the local NuGet cache, Invoke-PushLocal won't
            # update it with a new version of the package (the feed part is fine,
            # but we always remove cache and feed entries together, see
            # Reset-LocalNuGet).
            Remove-PackageFromLocalNuGet $ProjectName $pkgversion

            if (-not $yes) {
                guard "Push the package to the local NuGet feed/cache?"
            }

            Invoke-PushLocal $pkgfile $pkgversion

            SAY-LOUDLY "`n---`nNow, you can test the package. For instance,"
            SAY-LOUDLY "> eng\test-package.ps1 -Official -a -y"
            SAY-LOUDLY "If you intend to publish the package, you should reset the local NuGet feed/cache afterwards."
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

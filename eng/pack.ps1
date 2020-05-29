# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Create a NuGet package.

.DESCRIPTION
Create a NuGet package.
The default behaviour is to build a CI package.

.PARAMETER NoCI
Create a non-CI package.

.PARAMETER Freeze
Create a package ready to be published to NuGet.Org.

This is a meta-option, it automatically sets -NoCI. The resulting package is no
different from the one you would get using only -NoCI, but, in addition, the
script resets the repository, and stops when there are uncommited changes or if
it cannot retrieve git metadata.

If this behaviour happens to be too strict and you are in a hurry, you can use:
PS> pack.ps1 -NoCI -Yes
In that event, do not forget to reset the repository thereafter.

.PARAMETER Reset
Hard clean (reset) the source directory before anything else.

.PARAMETER Yes
Do not ask for confirmation, mostly.
Only one exception: after having created a package w/ option -Freeze on, the
script will enter in an interactive mode.

.PARAMETER MyVerbose
Verbose mode. We print the settings in use before compiling each assembly.

.PARAMETER Help
Print help text then exit.
#>
[CmdletBinding()]
param(
                 [switch] $NoCI,
                 [switch] $Freeze,

                 [switch] $Reset,
    [Alias("y")] [switch] $Yes,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

#endregion
################################################################################
#region Helpers

function Print-Help {
    say @"

Create a NuGet package for Abc.Maybe.

Usage: pack.ps1 [arguments]
     -NoCI       create a non-CI package.
     -Freeze     create a package ready to be published to NuGet.Org.

     -Reset      reset the solution before anything else.
  -y|-Yes        do not ask for confirmation, mostly.
  -v|-MyVerbose  display settings used to compile each DLL.
  -h|-Help       print this help then exit.

Examples.
> pack.ps1                # Create a CI package
> pack.ps1 -NoCI -Yes     # Create a non-CI package, ignore uncommited changes
> pack.ps1 -Freeze        # Create a package ready to be published to NuGet.Org

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

        return @("", "")
    }

    # Keep Approve-GitStatus before $yes: we always want to see a warning
    # when there are uncommited changes.
    $ok = Approve-GitStatus $git -ExitOnError:$exitOnError

    $branch = "" ; $commit = ""
    if ($ok -or $yes -or (yesno "There are uncommited changes, force retrieval of git metadata?")) {
        $branch = Get-GitBranch     $git -ExitOnError:$exitOnError
        $commit = Get-GitCommitHash $git -ExitOnError:$exitOnError
    }

    if ($branch -eq "") { warn "The branch name will be empty." }
    if ($commit -eq "") { warn "The commit hash will be empty." }

    return @($branch, $commit, $ok)
}

# ------------------------------------------------------------------------------

# In the past, we used to generate the id's within MSBuild but then it is nearly
# impossible to override the global properties PackageVersion and VersionSuffix.
# Besides that, generating the id's outside ensures that all assemblies inherit
# the same id's.
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

function Get-ActualVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $timestamp,

        [switch] $ci
    )

    say "Getting package version."

    $major, $minor, $patch, $precy, $preno = Get-PackageVersion $projectName

    if ($ci) {
        if (-not $timestamp) {
            ___debug "The timestamp is empty, let's regenerate it."
            $timestamp = "{0:yyyyMMdd}T{0:HHmmss}" -f (Get-Date).ToUniversalTime()
        }

        # For CI packages, we use SemVer 2.0.0, and we ensure that the package
        # is seen as a prerelease of what could be the next version. Examples:
        # - "1.2.3"       -> "1.2.4-ci-20201231T121212".
        # - "1.2.3-beta4" -> "1.2.3-beta5-ci-20201231T121212".
        if ($precy) {
            # With a prerelease label, we increase the prerelease number.
            $preno  = 1 + [int]$preno
        }
        else {
            # Without a prerelease label, we increase the patch number.
            $patch  = 1 + [int]$patch
        }
    }

    $prefix = "$major.$minor.$patch"
    if ($ci) {
        $suffix = $precy ? "$precy$preno-ci" : "ci"
    }
    else {
        $suffix = $precy ? "$precy$preno" : ""
    }

    $pkgversion = $suffix ? "$prefix-$suffix" : $prefix
    if ($ci) { $pkgversion = "$pkgversion-$timestamp" }

    ___debug "Version prefix: ""$prefix""."
    ___debug "Version suffix: ""$suffix""."
    ___debug "Package version: ""$pkgversion""."

     @($pkgversion, $prefix, $suffix)
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

        [switch] $ci,
        [switch] $yes
    )

    say "Getting package filepath."

    $path = Join-Path ($ci ? $PKG_CI_OUTDIR : $PKG_OUTDIR) "$projectName.$packageVersion.nupkg"

    ___debug "Package file: ""$path""."

    # Is there a dangling package file?
    # NB: not necessary for CI packages, the filename is unique.
    if (-not $ci -and (Test-Path $path)) {
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $versionPrefix,

        [Parameter(Mandatory = $false)]
        [string] $versionSuffix,

        [Parameter(Mandatory = $false)]
        [string] $repositoryBranch,

        [Parameter(Mandatory = $false)]
        [string] $repositoryCommit,

        [Parameter(Mandatory = $false)]
        [string] $buildNumber,

        [Parameter(Mandatory = $false)]
        [string] $revisionNumber,

        [switch] $deterministic,
        [switch] $ci,
        [switch] $myVerbose
    )

    "`nPacking v$packageVersion --- build {0}, rev. {1} on branch ""{2}"", commit ""{3}""." -f `
        ($buildNumber ? $buildNumber : "???"),
        ($revisionNumber ? $revisionNumber : "???"),
        ($repositoryBranch ? $repositoryBranch : "???"),
        ($repositoryCommit ? $repositoryCommit.Substring(0, 7) : "???") `
        | SAY-LOUDLY

    # VersionSuffix is for Retail.props, but it is not enough, we MUST also
    # specify --version-suffix (not sure it is necessary any more, but I prefer
    # to play safe).
    # NB: this is not something that we have to do for non-CI packages, since
    # in that case we don't patch the suffix, but let's not bother.
    $args = `
        "/p:PackageVersion=$packageVersion",
        "/p:VersionPrefix=$versionPrefix",
        "/p:VersionSuffix=$versionSuffix",
        "--version-suffix:$versionSuffix"

    if ($myVerbose)     { $args += "/p:PrintSettings=true" }
    if ($deterministic) { $args += "/p:EnableSourceLink=true" }
                   else { $args += "/p:Deterministic=false" }

    if ($ci) {
        $output = $PKG_CI_OUTDIR
        # NU5105 = warning about SemVer 2.0.0.
        $args += `
            "/p:MyAssemblyTitle=""$projectName (CI)""",
            "/p:NoWarnX=NU5105"
    }
    else {
        $output = $PKG_OUTDIR
    }

    $project = Join-Path $SRC_DIR $projectName -Resolve
    $targetFrameworks = Get-PackPlatforms -AsString

    # Do NOT use --no-restore or --no-build (options -Reset/-Freeze erase bin/obj).
    # RepositoryCommit and RepositoryBranch are standard props, do not remove them.
    # I guess that we could remove them when "EnableSourceLink" is "true", but I
    # haven't check that.
    & dotnet pack $project -c Release --nologo $args --output $output `
        /p:TargetFrameworks=$targetFrameworks `
        /p:BuildNumber=$buildNumber `
        /p:RevisionNumber=$revisionNumber `
        /p:RepositoryCommit=$repositoryCommit `
        /p:RepositoryBranch=$repositoryBranch `
        /p:Retail=true
        || die "Pack task failed."

    if ($ci) {
        say-softly "CI package successfully created."
    }
    else {
        say-softly "Package successfully created."
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
    # separated. Also, if Microsoft ever decided to change the behaviour of
    # a local "push", we won't have to update this script (but maybe reset.ps1).

    & dotnet nuget push $packageFile -s $NUGET_LOCAL_FEED --force-english-output
        || die "Failed to publish package to local NuGet feed."

    # If the following task fails, we should remove the package from the feed,
    # otherwise, later on, the package will be restored to the global cache.
    # This is not such a big problem, but I prefer not to pollute it with
    # CI packages (or versions we are going to publish).
    say "Updating the local NuGet cache"
    $project = Join-Path $TEST_DIR "Blank" -Resolve

    & dotnet restore $project /p:AbcVersion=$packageVersion
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

    $source = Read-Host "Source [empty to push to the default source]"
    if ($source) { $args += "-s $source" }

    $apiKey = Read-Host "API key [empty for no key]"
    if ($apiKey) { $args += "-k $apiKey" }

    if (yesno "Do you want me to publish the package for you?") {
        warn "Not yet activated."
        #& dotnet nuget push $packageFile $args
    }

    SAY-LOUDLY "`n---`nTo publish the package:"
    SAY-LOUDLY "> dotnet nuget push $packageFile $args"
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

if ($Freeze -or $NoCI) {
    Hello "this is the NuGet package creation script for Abc.Maybe."
}
else {
    Hello "this is the NuGet package creation script for Abc.Maybe (CI mode)."
}

readonly ProjectName "Abc.Maybe"

try {
    ___BEGIN___

    $CI = -not ($Freeze -or $NoCI)

    SAY-LOUDLY "`nInitialisation."

    # 1. Reset the source tree.
    if ($Freeze -or $Reset) { Reset-SourceTree -Yes:($Freeze -or $Yes) }
    # 2. Get git metadata.
    $branch, $commit, $deterministic = Get-GitMetadata -Yes:$Yes -ExitOnError:$Freeze
    # 3. Generate build numbers.
    say "Generating build numbers."
    $buildNumber, $revisionNumber, $timestamp = Get-BuildNumbers
    # 4. Get package/asm version.
    $pkgversion, $prefix, $suffix = Get-ActualVersion $ProjectName $timestamp -CI:$CI
    # 5. Get package file.
    $pkgfile = Get-PackageFile $ProjectName $pkgversion -Yes:($Freeze -or $Yes) -CI:$CI

    Invoke-Pack `
        -ProjectName      $ProjectName `
        -PackageVersion   $pkgversion `
        -VersionPrefix    $prefix `
        -VersionSuffix    $suffix `
        -RepositoryBranch $branch `
        -RepositoryCommit $commit `
        -BuildNumber      $buildNumber `
        -RevisionNumber   $revisionNumber `
        -Deterministic:   $deterministic `
        -CI:              $CI `
        -MyVerbose:       $MyVerbose

    # Post-actions.
    if ($CI) {
        Invoke-PushLocal $pkgfile $pkgversion
    }
    else {
        if ($Freeze) {
            # Now, all CI packages should be obsoleted. Traces of them can be
            # found within the directories "test" and "__\packages-ci", but also
            # in the local NuGet cache/feed.
            # We should also remove any reference to a released package with the
            # same version. Failing to do so would mean that, after publishing
            # the package to NuGet.Org, "test-package.ps1" could still test a
            # package from the local NuGet cache/feed not the one from NuGet.Org.
            Reset-TestTree        -Yes:$true
            Reset-PackageCIOutDir -Yes:$true
            Reset-LocalNuGet      -Yes:$true

            Invoke-Publish $pkgfile
        }
        else {
            # If we don't reset the local NuGet cache, Invoke-PushLocal won't
            # update it with a new version of the package (the feed part is fine,
            # but we always remove cache and feed entry together, see
            # Reset-LocalNuGet).
            Remove-PackageFromLocalNuGet $ProjectName $pkgversion

            if (-not $yes) {
                guard "Push the package to the local NuGet feed/cache?"
            }

            Invoke-PushLocal $pkgfile $pkgversion

            SAY-LOUDLY "`n---`nNow, you can test the package. For instance,"
            SAY-LOUDLY "> eng\test-package.ps1 -NoCI -a -y"
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

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

.PARAMETER Release
Create a package ready to be published to NuGet.Org.
NB: Release has nothing to do with the MSBuild configuration property.

This is a meta-option, it automatically sets -NoCI. The resulting package is no
different from the one you would get using only -NoCI, but, in addition, the
script resets the repository, and stops when there are uncommited changes or if
it cannot retrieve git metadata.

If this behaviour happens to be too strict and you are in a hurry, you can use:
PS> pack.ps1 -NoCI -Force
In that event, do not forget to reset the repository thereafter.

.PARAMETER Force
Force retrieval of git metadata when there are uncommited changes.
Ignored if -Release is also set and equals $true.

.PARAMETER Reset
Hard clean (reset) the source directory before anything else.

.PARAMETER Yes
Do not ask for confirmation, mostly.
Only one exception: after having created a package w/ option -Release on, the
script will enter in an interactive mode.

.PARAMETER MyVerbose
Verbose mode. We display the settings used before compiling each assembly.

.PARAMETER Help
Print help.

.EXAMPLE
PS> pack.ps1
Create a CI package.

.EXAMPLE
PS> pack.ps1 -n -f
Create a non-CI package, ignore uncommited changes.

.EXAMPLE
PS> pack.ps1 -r
Create a package ready to be published to NuGet.Org.
#>
[CmdletBinding()]
param(
    [Alias("n")] [switch] $NoCI,
    [Alias("r")] [switch] $Release,
    [Alias("f")] [switch] $Force,
                 [switch] $Reset,
    [Alias("y")] [switch] $Yes,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

#endregion
################################################################################
#region Helpers

function Write-Usage {
    Say @"

Create a NuGet package for Abc.Maybe.

Usage: pack.ps1 [arguments]
  -n|-NoCI       create a non-CI package.
  -r|-Release    create a package ready to be published to NuGet.Org.
  -f|-Force      force retrieval of git metadata when there are uncommited changes.
     -Reset      reset the solution before anything else.
  -y|-Yes        do not ask for confirmation, mostly.
  -v|-MyVerbose  display settings used to compile each DLL.
  -h|-Help       print this help and exit.

"@
}

# ------------------------------------------------------------------------------

# Find commit hash and branch name.
function Get-GitMetadata {
    [CmdletBinding()]
    param(
        [switch] $fatal,
        [switch] $force,
        [switch] $yes
    )

    Say "Retrieving git metadata."

    $git = Find-Git

    $branch = ""
    $commit = ""

    if ($git -eq $null) {
        if ($yes) {
            Carp "The package description won't include any git metadata."
        }
        else {
            Confirm-Continue "Continue even without any git metadata?"
        }
    }
    else {
        $ok = Approve-GitStatus -Git $git -Fatal:$fatal

        # Keep Approve-GitStatus before $force: we always want to see a warning
        # when there are uncommited changes.
        if ($ok -or $force) {
            $branch = Get-GitBranch     -Git $git -Fatal:$fatal
            $commit = Get-GitCommitHash -Git $git -Fatal:$fatal
        }

        if ($branch -eq "") {
            Carp "The branch name will be empty. Maybe use -Force?"
        }
        if ($commit -eq "") {
            Carp "The commit hash will be empty. Maybe use -Force?"
        }
    }

    return @($branch, $commit)
}

# ------------------------------------------------------------------------------

# In the past, we used to generate the id's within MSBuild but then it is nearly
# impossible to override the global properties PackageVersion and VersionSuffix.
# Besides that, generating the id's outside ensures that all assemblies inherit
# the same id's.
function Generate-UIDs {
    [CmdletBinding()]
    param()

    Say "Generating build UIDs."

    $vswhere = Find-VsWhere
    $fsi = Find-Fsi $vswhere
    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

    $uids = & $fsi $fsx

    Write-Verbose "Build UIDs: ""$uids"""

    $uids.Split(";")
}

# ------------------------------------------------------------------------------

function Get-ActualVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $timestamp,

        [switch] $ci
    )

    Say "Getting package version."

    $major, $minor, $patch, $precy, $preno = Get-PackageVersion $projectName

    if ($ci) {
        # For CI packages, we use SemVer 2.0.0, and we ensure that the package
        # is seen as a prerelease of what could be the next version. Examples:
        # - "1.2.3"       -> "1.2.4-ci-20201231-T121212".
        # - "1.2.3-beta4" -> "1.2.3-beta5-ci-20201231-T121212".
        if ($precy -eq "") {
            # Without a prerelease label, we increase the patch number.
            $patch  = 1 + [int]$patch
            $suffix = "ci-$timestamp"
        }
        else {
            # With a prerelease label, we increase the prerelease number.
            $preno  = 1 + [int]$preno
            $suffix = "$precy$preno-ci-$timestamp"
        }
    }
    else {
        if ($precy -eq "") {
            $suffix = ""
        }
        else {
            $suffix = "$precy$preno"
        }
    }

    $prefix = "$major.$minor.$patch"

    Write-Verbose "Version suffix: ""$suffix"""
    Write-Verbose "Version prefix: ""$prefix"""

    if ($suffix -eq "") {
        return @($prefix, $prefix, "")
    }
    else {
        return @("$prefix-$suffix", $prefix, $suffix)
    }
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
        [string] $version,

        [switch] $ci,
        [switch] $yes
    )

    Say "Getting package file."

    if ($ci) {
        $path = Join-Path $PKG_CI_OUTDIR "$projectName.$version.nupkg"
    }
    else {
        $path = Join-Path $PKG_OUTDIR "$projectName.$version.nupkg"
    }

    Write-Verbose "Package file: ""$path"""

    # Is there a dangling package file?
    # NB: not necessary for CI packages, the filename is unique.
    if (-not $ci -and (Test-Path $path)) {
        if (-not $yes) {
            Carp "A package with the same version ($version) already exists."
            Confirm-Continue "Do you wish to proceed anyway?"
        }

        # Not necessary, dotnet will replace it, but to avoid any ambiguity
        # I prefer to remove it anyway.
        Say-Indent "The old package file will be removed now."
        Remove-Item $path
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
        [string] $buildNumber,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $revisionNumber,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $versionPrefix,

        [Parameter(Mandatory = $false)]
        [string] $versionSuffix = "",

        [Parameter(Mandatory = $false)]
        [string] $repositoryBranch = "",

        [Parameter(Mandatory = $false)]
        [string] $repositoryCommit = "",

        [switch] $ci,
        [switch] $myVerbose
    )

    Say-LOUDLY "`nPacking v$version --- build $buildNumber, rev. $revisionNumber" -NoNewline
    if ($repositoryBranch -and $repositoryCommit) {
        " on branch ""$repositoryBranch"", commit ""{0}""." -f $repositoryCommit.Substring(0, 7) `
            | Say-LOUDLY
    }
    else { Say-LOUDLY " on branch ""???"", commit ""???""." }

    # VersionSuffix is for Pack.props, but it is not enough, we MUST
    # also specify --version-suffix (not sure it is necessary any more, but
    # I prefer to play safe).
    # NB: this is not something that we have to do for non-CI packages, since
    # in that case we don't patch the suffix, but let's not bother.
    $args = `
        "/p:VersionPrefix=$versionPrefix",
        "/p:VersionSuffix=$versionSuffix",
        "--version-suffix:$versionSuffix"

    if ($myVerbose) {
        $args += "/p:DisplaySettings=true"
    }

    if ($ci) {
        $output = $PKG_CI_OUTDIR
        $args += `
            "/p:AssemblyTitle=""$projectName (CI)""",
            "/p:NoWarnX=NU5105"
    }
    else {
        $output = $PKG_OUTDIR
    }

    $project = Join-Path $SRC_DIR $projectName -Resolve

    # Do NOT use --no-restore or --no-build (options -Reset/-Release erase bin/obj).
    # RepositoryCommit and RepositoryBranch are standard props, do not remove them.
    & dotnet pack $project -c Release --nologo $args --output $output `
        /p:TargetFrameworks='\"netstandard2.1;netstandard2.0;netstandard1.0;net461\"' `
        /p:BuildNumber=$buildNumber `
        /p:RevisionNumber=$revisionNumber `
        /p:RepositoryCommit=$repositoryCommit `
        /p:RepositoryBranch=$repositoryBranch `
        /p:Pack=true `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Pack task failed."

    if ($ci) {
        Say-Softly "CI package successfully created."
    }
    else {
        Say-Softly "Package successfully created."
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
        [string] $version
    )

    Say-LOUDLY "`nPushing the package to the local NuGet feed/cache."

    # Local "push" doesn't store packages in a hierarchical folder structure;
    # see https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-push
    # It means that we could have created the package directly in
    # $NUGET_LOCAL_FEED but it seems cleaner to keep creation and publication
    # separated. Also, if Microsoft ever decided to change the behaviour of
    # a local "push", we won't have to update this script (but maybe reset.ps1).

    & dotnet nuget push $packageFile -s $NUGET_LOCAL_FEED --force-english-output | Out-Host
    Assert-CmdSuccess -ErrMessage "Failed to publish package to local NuGet feed."

    # If the following task fails, we should remove the package from the feed,
    # otherwise, later on, the package will be restored to the global cache.
    # This is not such a big problem, but I prefer not to pollute it with
    # CI packages (or versions we are going to publish).
    Say "Updating the local NuGet cache"
    $project = Join-Path $TEST_DIR "Blank" -Resolve
    & dotnet restore $project /p:AbcVersion=$version | Out-Host
    Assert-CmdSuccess -ErrMessage "Failed to update the local NuGet cache."

    Say-Softly "Package successfully installed."
}

# ------------------------------------------------------------------------------

function Invoke-Publish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageFile
    )

    Say-LOUDLY "`nPublishing the package -or- Preparing the command to do so."

    $args = @()

    $source = Read-Host "Source [empty to push to the default source]"
    if ($source -ne "") { $args += "-s $source" }

    # TODO: --interactive?
    $apiKey = Read-Host "API key [empty for no key]"
    if ($apiKey -ne "") { $args += "-k $apiKey" }

    if (Confirm-Yes "Do you want me to publish the package for you?") {
        Carp "Not yet activated."
        Say-LOUDLY "---`nTo publish the package:"
        Say-LOUDLY "> dotnet nuget push $packageFile $args"
        #& dotnet nuget push --force-english-output $packageFile $args | Out-Host
    }
    else {
        Say-LOUDLY "---`nTo publish the package:"
        Say-LOUDLY "> dotnet nuget push $packageFile $args"
    }
}

#endregion
################################################################################
#region Main.

if ($Help) {
    Write-Usage
    exit 0
}

if ($Release -or $NoCI) {
    Say "This is the NuGet package creation tool for Abc.Maybe.`n"
}
else {
    Say "This is the NuGet package creation tool for Abc.Maybe" -NoNewline
    Say-LOUDLY " (CI mode).`n"
}

try {
    pushd $ROOT_DIR

    New-Variable -Name "ProjectName" -Value "Abc.Maybe" -Option ReadOnly

    $CI = -not ($Release -or $NoCI)

    Say-LOUDLY "Intialization."

    # 1. Reset the source tree.
    if ($Release -or $Reset) { Reset-SourceTree -Yes:($Release -or $Yes) }
    # 2. Get git metadata.
    $branch, $commit = Get-GitMetadata -Fatal:$Release -Force:$Force -Yes:$Yes
    # 3. Generate build UIDs.
    $buildNumber, $revisionNumber, $timestamp = Generate-UIDs
    # 4. Get package version.
    $version, $prefix, $suffix = Get-ActualVersion $ProjectName $timestamp -CI:$CI
    # 5. Get package file.
    $packageFile = Get-PackageFile $ProjectName $version -Yes:($Release -or $Yes) -CI:$CI

    Invoke-Pack `
        -ProjectName      $ProjectName `
        -BuildNumber      $buildNumber `
        -RevisionNumber   $revisionNumber `
        -Version          $version `
        -VersionPrefix    $prefix `
        -VersionSuffix    $suffix `
        -RepositoryBranch $branch `
        -RepositoryCommit $commit `
        -CI:              $CI `
        -MyVerbose:       $MyVerbose

    # Post-actions.
    if ($CI) {
        Invoke-PushLocal $packageFile $version
    }
    else {
        if ($Release) {
            # Now, all CI packages should be obsoleted. Traces of them can be
            # found within the directories "test" and "__\packages-ci", but also
            # in the local NuGet cache/feed.
            # We should also remove any reference to a release package with the
            # same version. Failing to do so would mean that, after publishing
            # the package to NuGet.Org, "test-package.ps1" could still test a
            # package from the local NuGet cache/feed not the one from NuGet.Org.
            Reset-TestTree        -Yes:$true
            Reset-PackageCIOutDir -Yes:$true
            Reset-LocalNuGet      -Yes:$true

            Invoke-Publish $packageFile
        }
        else {
            # If we don't reset the local NuGet cache, Invoke-PushLocal won't
            # update it with a new version of the package (the feed part is fine,
            # but we always remove cache and feed entry together, see
            # Reset-LocalNuGet).
            Remove-PackageFromLocalNuGet $ProjectName $version

            if (-not $yes) {
                Confirm-Continue "Push the package to the local NuGet feed/cache?"
            }

            Invoke-PushLocal $packageFile $version

            Say-LOUDLY "---`nNow, you can test the package. For instance,"
            Say-LOUDLY "> eng\test-package.ps1 -a -y"
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

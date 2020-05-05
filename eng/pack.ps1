#Requires -Version 4.0

################################################################################
#region Preamble.

<#
.SYNOPSIS
Create a NuGet package, retail or CI (the default).

.PARAMETER Retail
Create a retail package, ready to be published to NuGet.Org.
The default behaviour is to build CI packages.

.PARAMETER Safe
Create a retail package, safe mode and ready to be published to NuGet.Org.
This is a meta-option, it automatically sets -Retail.
In addition, the script resets the repository, and stops when there are
uncommited changes or if it cannot retrieve git metadata.
The resulting package is not different from the one you would get using -Retail.
If this option is too strict and you are in a hurry, you can use:
PS> pack.ps1 -Retail -Force
In that event, do not forget to reset the repository after.

.PARAMETER Force
Force retrieval of git metadata when there are uncommited changes.
Ignored if -Safe is also set.

.PARAMETER Clean
Hard clean the source directory before anything else.

.PARAMETER Yes
Do not ask for confirmation (mostly).

.PARAMETER MyVerbose
Verbose mode. We display the settings used before compiling each assembly.

.PARAMETER Help
Print help.

.EXAMPLE
PS> pack.ps1
Create a CI package.

.EXAMPLE
PS> pack.ps1 -r -f
Fast packing, retail mode, maybe obsolete git metadata.

.EXAMPLE
PS> pack.ps1 -s
Create a retail package, safe mode and ready to be published to NuGet.Org.
#>
[CmdletBinding()]
param(
    [Alias("r")] [switch] $Retail,
    [Alias("s")] [switch] $Safe,
    [Alias("f")] [switch] $Force,
    [Alias("c")] [switch] $Clean,
    [Alias("y")] [switch] $Yes,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

New-Variable -Name "CONFIGURATION" -Value "Release" -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers

function Write-Usage {
    Say @"

Create a NuGet package for Abc.Maybe

Usage: pack.ps1 [switches]
  -r|-Retail      create a retail package, ready to be published to NuGet.Org.
  -s|-Safe        create a retail package, safe mode and ready to be published to NuGet.Org.
  -f|-Force       force retrieval of git metadata when there are uncommited changes.
  -c|-Clean       hard clean the solution before anything else.
  -v|-MyVerbose   display settings used to compile each DLL.
  -h|-Help        print this help and exit.

"@
}

# ------------------------------------------------------------------------------

# Reset the repository when -Safe is set.
function Reset-Repository {
    [CmdletBinding()]
    param()

    Say "Resetting the repository."

    # This one is for "safety".
    Reset-SourceTree -Yes:$true
    # This one is to ensure a clean test tree after publication.
    Reset-TestTree -Yes:$true

    # These two ensure that soon-to-be obsolete package files are removed.
    # One advantage is that Approve-PackageFile won't ask for any confirmation
    # since there is no dangling package file.
    Reset-PackageOutDir -Yes:$true
    Reset-CIPackageOutDir -Yes:$true

    # This is the only mandatory part.
    # We ensure that any temporary retail package is removed from the local
    # NuGet cache/feed. Failing to do so would mean that, after publishing the
    # package to NuGet.Org, test-package.ps1 could test a package from the local
    # NuGet cache/feed not the one from NuGet.Org.
    # Since we are at it, we go a bit further and remove any temporary package.
    # This is in line with our philosophy of keeping things clean.
    Reset-LocalNuGet -Yes:$true
}

# ------------------------------------------------------------------------------

# In the past, we used to generate the id's within MSBuild but then it is nearly
# impossible to override the global properties PackageVersion and VersionSuffix.
# Besides that, generating the id's outside ensures that all assemblies inherit
# the same id's.
function Generate-UIDs {
    [CmdletBinding()]
    param()

    Write-Verbose "Generating Build UIDs."

    $vswhere = Find-VsWhere
    $fsi = Find-Fsi $vswhere
    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

    $uids = & $fsi $fsx

    Write-Verbose "Build UIDs: ""$uids"""

    $uids.Split(";")
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

        [switch] $retail
    )

    Write-Verbose "Getting package file."

    if ($retail) {
        $path = Join-Path $PKG_OUTDIR "$projectName.$version.nupkg"
    }
    else {
        $path = Join-Path $PKG_CI_OUTDIR "$projectName.$version.nupkg"
    }

    Write-Verbose "Package file: ""$path"""

    $path
}

# ------------------------------------------------------------------------------

function Approve-PackageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $packageFile,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [switch] $yes
    )

    Write-Verbose "Approving package file."

    # Is there a dangling package file?
    # NB: only meaningful when in retail mode; otherwise the filename is unique.
    if (Test-Path $packageFile) {
        Carp "A package with the same version ($version) already exists."
        if (-not $yes) {
            Confirm-Continue "Do you wish to proceed anyway?"
        }

        # Not necessary, dotnet will replace it, but to avoid any ambiguity
        # I prefer to remove it anyway.
        Say-Indent "The old package file will be removed now."
        Remove-Item $packageFile
    }
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

        [switch] $retail
    )

    $major, $minor, $patch, $precy, $preno = Get-PackageVersion $projectName

    if ($retail) {
        if ($precy -eq "") {
            $suffix = ""
        }
        else {
            $suffix = "$precy$preno"
        }
    }
    else {
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

#endregion
################################################################################
#region Tasks.

# Find commit hash and branch.
function Invoke-Git {
    [CmdletBinding()]
    param(
        [switch] $force,
        [switch] $fatal,
        [switch] $yes
    )

    Say "Retrieving git metadata."

    $branch = ""
    $commit = ""

    $git = Find-Git -Fatal:$fatal.IsPresent

    if ($git -eq $null) {
        if ($yes) {
            Carp "The package description won't include any git metadata."
        }
        else {
            Confirm-Continue "Continue even without any git metadata?"
        }
    }
    else {
        $ok = Approve-GitStatus -Git $git -Fatal:$fatal.IsPresent

        # Keep Approve-GitStatus before $force: we always want to see a warning
        # when there are uncommited changes.
        if ($ok -or $force) {
            $branch = Get-GitBranch     -Git $git -Fatal:$fatal.IsPresent
            $commit = Get-GitCommitHash -Git $git -Fatal:$fatal.IsPresent
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

function Invoke-Pack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $buildNumber,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $revisionNumber,

        [Parameter(Mandatory = $true, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $true, Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string] $versionPrefix = "",

        [Parameter(Mandatory = $false, Position = 5)]
        [ValidateNotNull()]
        [string] $versionSuffix = "",

        [Parameter(Mandatory = $false, Position = 6)]
        [ValidateNotNull()]
        [string] $repositoryBranch = "",

        [Parameter(Mandatory = $false, Position = 7)]
        [ValidateNotNull()]
        [string] $repositoryCommit = "",

        [switch] $retail,
        [switch] $myVerbose
    )

    # VersionSuffix is for Retail.props, but it is not enough, we MUST
    # also specify --version-suffix (not sure it is necessary any more, but
    # I prefer to play safe).
    # NB: this is not something that we have to do for retail builds (see
    # above), since in that case we don't patch the suffix, but let's not bother.
    $args = `
        "/p:VersionPrefix=$versionPrefix",
        "/p:VersionSuffix=$versionSuffix",
        "--version-suffix:$versionSuffix"

    if ($myVerbose) {
        $args += "/p:DisplaySettings=true"
    }

    if ($retail) {
        $output = $PKG_OUTDIR
    }
    else {
        $output = $PKG_CI_OUTDIR
        $args += `
            "/p:AssemblyTitle=""$projectName (CI)""",
            "/p:NoWarnX=NU5105"
    }

    $project = Join-Path $SRC_DIR $projectName -Resolve

    Chirp "Packing v$version --- build $buildNumber, rev. $revisionNumber" -NoNewline
    if ($repositoryBranch -and $repositoryCommit) {
        $abbrv = $repositoryCommit.Substring(0, 7)
        Chirp " on branch ""$repositoryBranch"", commit ""$abbrv""."
    }
    else { Chirp " on branch ""???"", commit ""???""." }

    # Do NOT use --no-restore or --no-build (options -Clean/-Safe remove everything).
    # RepositoryCommit and RepositoryBranch are standard props, do not remove them.
    & dotnet pack $project -c $CONFIGURATION --nologo $args --output $output `
        /p:TargetFrameworks='\"netstandard2.1;netstandard2.0;netstandard1.0;net461\"' `
        /p:BuildNumber=$buildNumber `
        /p:RevisionNumber=$revisionNumber `
        /p:RepositoryCommit=$repositoryCommit `
        /p:RepositoryBranch=$repositoryBranch `
        /p:Retail=true `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Pack task failed."

    if ($retail) {
        Chirp "Package successfully created."
    }
    else {
        Chirp "CI package successfully created."
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
        [string] $version,

        [switch] $retail
    )

    Chirp "Pushing the package to the local NuGet feed/cache."

    # We could have created the package directly in $NUGET_LOCAL_FEED
    # but it seems cleaner to keep creation and publication separated.
    # Also, if Microsoft ever decided to change the behaviour of "push",
    # we won't have to update this script (but maybe reset.ps1).

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

    Chirp "Package successfully installed."
}

# ------------------------------------------------------------------------------

function Invoke-Publish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageFile
    )

    # TODO: publish, --interactive?
    if (Confirm-Yes "Do you want me to publish the package for you?") {
        Carp "Not yet implemented."
    }

    Chirp "---`nTo publish the package:"
    Chirp "> dotnet nuget push $packageFile -s https://www.nuget.org/ -k MYKEY"
}

#endregion
################################################################################
#region Main.

if ($Help) {
    Write-Usage
    exit 0
}

# TODO: do more w/ option Yes.

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Safe) {
        $isRetail = $true

        Reset-Repository
    }
    else {
        $isRetail = $Retail.IsPresent

        if ($Clean.IsPresent) { Reset-SourceTree -Yes:$Yes.IsPresent }
    }

    $projectName = "Abc.Maybe"

    # 1. Get git metadata.
    $branch, $commit = Invoke-Git -Force:$force.IsPresent -Fatal:$Safe.IsPresent -Yes:$Yes.IsPresent
    # 2. Get build numbers.
    $buildNumber, $revisionNumber, $timestamp = Generate-UIDs
    # 3. Get package version.
    $version, $prefix, $suffix = Get-ActualVersion $projectName $timestamp -Retail:$isRetail
    # 4. Get package file.
    $packageFile = Get-PackageFile $projectName $version -Retail:$isRetail
    # 5. Approve package file.
    if ($isRetail) {
        $forceRemoval = $Safe -or $Yes
        Approve-PackageFile $packageFile $version -Yes:$forceRemoval
    }

    Invoke-Pack $projectName `
        -BuildNumber:$buildNumber `
        -RevisionNumber:$revisionNumber `
        -Version:$version `
        -VersionPrefix:$prefix `
        -VersionSuffix:$suffix `
        -RepositoryBranch:$branch `
        -RepositoryCommit:$commit `
        -Retail:$isRetail `
        -MyVerbose:$MyVerbose.IsPresent

    if ($Safe) {
        # TODO: reset repository, again?
        Invoke-Publish $packageFile
    }
    else {
        if ($isRetail) {
            # If we don't reset the local NuGet cache, Invoke-PushLocal won't
            # update it with a new version of the package (the feed part is fine,
            # but we always remove cache and feed entry together, see
            # Reset-LocalNuGet).
            Remove-PackageFromLocalNuGet $projectName $version

            Confirm-Continue "Push the package to the local NuGet feed/cache?"
        }

        Invoke-PushLocal $packageFile $version

        if ($isRetail) {
            Chirp "---`nNow, you can test the package. For instance,"
            Chirp "> eng\test-package.ps1 -a -y"
        }
    }
}
catch {
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

#Requires -Version 4.0

<#
.SYNOPSIS
Create a NuGet package.

.PARAMETER Retail
Create a retail package.
The default behaviour is to build CI packages.

.PARAMETER Final
Create a retail package.
This is a meta-option, it automatically sets -Retail and -Clean too.
In addition, the script stops when there are uncommited changes or if it cannot
get git-related infos.
The resulting package is not different from the one you would get using -Retail,
so, if this option is too strict and you are in a hurry, you can use:
PS> pack.ps1 -Retail -Force

.PARAMETER Force
Force packing even when there are uncommited changes.
Ignored if -Final is also set.

.PARAMETER Clean
Hard clean the source directory before anything else.

.PARAMETER MyVerbose
Verbose mode. Display settings used while compiling each DLL.

.PARAMETER Help
Print help.

.EXAMPLE
PS> pack.ps1
Create a CI package. Append -f to discard warnings about obsolete git infos.

.EXAMPLE
PS> pack.ps1 -r -f
Fast packing, retail mode, maybe obsolete git infos.

.EXAMPLE
PS> pack.ps1 -Final
Create a package ready for publication.
#>
[CmdletBinding()]
param(
                 [switch] $Retail,
                 [switch] $Final,
    [Alias("f")] [switch] $Force,
    [Alias("c")] [switch] $Clean,
    [Alias("v")] [switch] $MyVerbose,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

New-Variable -Name "CONFIGURATION" -Value "Release" -Scope Script -Option Constant

################################################################################

function Write-Usage {
    Say @"

Create a NuGet package for Abc.Maybe

Usage: pack.ps1 [switches]
    |-Retail      build retail packages.
  -f|-Force       force packing even when there are uncommited changes.
  -c|-Clean       hard clean the solution before anything else.
  -v|-MyVerbose   display settings used to compile each DLL.
  -h|-Help        print this help and exit.

"@
}

# ------------------------------------------------------------------------------

# In the past, we used to generate the id's within MSBuild but then it is nearly
# impossible to override the global properties PackageVersion and VersionSuffix.
# Besides that, generating the id's outside ensures that all assemblies inherit
# the same id's.
function Generate-Uids {
    [CmdletBinding()]
    param()

    $vswhere = Find-VsWhere
    $fsi = Find-Fsi $vswhere
    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

    Write-Verbose "Executing genuids.fsx."

    $uids = & $fsi $fsx

    $uids.Split(";")
}

# Find commit hash and branch.
function Get-GitInfos {
    [CmdletBinding()]
    param(
        [switch] $force,
        [switch] $fatal
    )

    Write-Verbose "Getting git infos."

    $branch = ""
    $commit = ""

    $git = Find-Git -Fatal:$fatal.IsPresent
    if ($git -eq $null) {
        Confirm-Continue "Continue even without any git metadata?"
    }
    else {
        # Keep Approve-GitStatus before $force: we always want to see a warning
        # when there are uncommited changes.
        $ok = Approve-GitStatus -Git $git -Fatal:$fatal.IsPresent
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

    if ($retail) {
        return Join-Path $PKG_OUTDIR "$projectName.$version.nupkg"
    }
    else {
        return Join-Path $PKG_CI_OUTDIR "$projectName.$version.nupkg"
    }
}

function Approve-PackageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $package,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version
    )

    # Is there a dangling package file?
    # NB: only meaningful when in retail mode; otherwise the filename is unique.
    if (Test-Path $package) {
        Carp "A package with the same version ($version) already exists."
        Confirm-Continue "Do you wish to proceed anyway?"

        # Not necessary, dotnet will replace it, but to avoid any ambiguity
        # I prefer to remove it anyway.
        Say-Indent "The old package file will be removed now."
        Remove-Item $package
    }
}

# ------------------------------------------------------------------------------

function Invoke-Pack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [string] $branch = "",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string] $commit = "",

        [switch] $retail,
        [switch] $force,
        [switch] $myVerbose
    )

    SAY-LOUD "Packing."

       $major, $minor, $patch, $precy, $preno = Get-PackageVersion $projectName
    $buildNumber, $revisionNumber, $timestamp = Generate-Uids

    if ($retail) {
        if ($precy -eq "") {
            $suffix = ""
        }
        else {
            $suffix = "$precy$preno"
        }

        $output = $PKG_OUTDIR
        $args = @()
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

        $output = $PKG_CI_OUTDIR
        # VersionSuffix is for Retail.props, but it is not enough, we MUST
        # also specify --version-suffix (not sure it is necessary any more, but
        # I prefer to play safe).
        # NB: this is not something that we have to do for retail builds (see
        # above), since in that case we don't patch the suffix.
        $args = `
            "--version-suffix:$suffix",
            "/p:VersionSuffix=$suffix",
            "/p:AssemblyTitle=""$projectName (CI)""",
            "/p:NoWarnX=NU5105"
    }

    if ($myVerbose) {
        $args += "/p:DisplaySettings=true"
    }

    if ($suffix -eq "") {
        $version = "$major.$minor.$patch"
    }
    else {
        $version = "$major.$minor.$patch-$suffix"
    }

    $package = Get-PackageFile $projectName $version -Retail:$retail.IsPresent

    if ($retail) { Approve-PackageFile $package $version }

    $proj = Join-Path $SRC_DIR $projectName -Resolve

    Chirp "Packing version $version --- build $buildNumber, rev. $revisionNumber" -NoNewline
    if ($branch -and $commit) {
        $abbrv = $commit.Substring(0, 7)
        Chirp " on branch ""$branch"", commit $abbrv."
    }
    else { Chirp " on branch ""???"", commit ???." }

    # Do NOT use --no-restore or --no-build (option Clean removes everything).
    # RepositoryCommit and RepositoryBranch are standard props, do not remove them.
    & dotnet pack $proj -c $CONFIGURATION --nologo $args --output $output `
        /p:TargetFrameworks='\"netstandard2.1;netstandard2.0;netstandard1.0;net461\"' `
        /p:BuildNumber=$buildNumber `
        /p:RevisionNumber=$revisionNumber `
        /p:RepositoryCommit=$commit `
        /p:RepositoryBranch=$branch `
        /p:Retail=true `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Pack task failed."

    if ($retail) {
        Chirp "Package successfully created."
    }
    else {
        Chirp "CI package successfully created."
    }

    @($package, $version)
}

function Invoke-PushLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $package,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version
    )

    SAY-LOUD "Pushing the package to the local NuGet feed/cache."

    # We could have created the package directly in $NUGET_LOCAL_FEED
    # but it seems cleaner to keep creation and publication separated.
    # Also, if Microsoft ever decided to change the behaviour of "push",
    # we won't have to update this script (but maybe reset.ps1).

    Say "Pushing the package to the local NuGet feed"
    & dotnet nuget push $package -s $NUGET_LOCAL_FEED --force-english-output | Out-Host
    Assert-CmdSuccess -ErrMessage "Failed to publish package to local NuGet feed."

    # If the following task fails, we should remove the package from the feed,
    # otherwise, later on, the package will be restored to the global cache.
    # This is not such a big problem, but I prefer not to pollute it with
    # CI packages.
    Say "Updating the local NuGet cache"
    $proj = Join-Path $TEST_DIR "Blank" -Resolve
    & dotnet restore $proj /p:AbcVersion=$version | Out-Host
    Assert-CmdSuccess -ErrMessage "Failed to update the local NuGet cache."

    Chirp "CI package successfully installed."
}

function Invoke-Publish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $package
    )

    SAY-LOUD "Publishing the package to the official NuGet repository."

    # TODO: publish the package for us. --interactive?
    if (Confirm-Yes "Do you want me to publish the package for you?") {
        Carp "Not yet implemented."
    }

    Chirp "To publish the package:"
    Chirp "> dotnet nuget push $package -s https://www.nuget.org/ -k MYKEY"
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

try {
    Approve-RepositoryRoot

    pushd $ROOT_DIR

    if ($Final) {
        if ($Force) {
            Croak "You cannot set both options -Final and -Force at the same time."
        }

        $isRetail = $true
        $forceClean = $true
    }
    else {
        $isRetail = $Retail.IsPresent
        $forceClean = $false
    }

    if ($forceClean `
        -or ($Clean.IsPresent -and (Confirm-Yes "Hard clean the directory ""src""?"))) {
          Say-Indent "Deleting ""bin"" and ""obj"" directories within ""src""."
          Remove-BinAndObj $SRC_DIR
    }

    $branch, $commit = Get-GitInfos -Force:$force.IsPresent -Fatal:$final.IsPresent

    $package, $version = Invoke-Pack "Abc.Maybe" `
        -Branch:$branch `
        -Commit:$commit `
        -Retail:$isRetail `
        -Force:$Force.IsPresent `
        -MyVerbose:$MyVerbose.IsPresent

    if ($Final) {
        Invoke-Publish $package
    }
    else {
        if ($isRetail) {
            Confirm-Continue "Push the package to the local NuGet feed/cache.?"
        }
        Invoke-PushLocal $package $version
        if ($isRetail) {
            Chirp "Now, you can test the package:"
            Chirp "> eng\test-package.ps1 -a -y"
            Chirp "Do not forget to reset the local NuGet cache/feed after."
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

################################################################################

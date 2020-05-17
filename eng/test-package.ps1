# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Test the package Abc.Maybe.

.DESCRIPTION
Test the package Abc.Maybe for net4(5,6,7,8)x and netcoreapp(2,3).x.
Matching .NET Framework Developer Packs or Targeting Packs must be installed
locally, the later should suffice. The script will fail with error MSB3644 when
it is not the case.

.OUTPUTS
In case of a fatal error, the script exits with a code 1.
The script exits with a code 2 when -Platform is equal "net45" or "net451", and
it couldn't find the Xunit runner console.

.PARAMETER Platform
Specify the platform(s) for which to test the package.
Unless there is one trailing asterisk (*), this parameter expects a single
platform name. Otherwise, all platform whose name starts with the specified
value (without the asterisk) will be selected. For instance, "net46*" is
translated to "net46", "net461" and "net462". There limit case ("*") is a
synonym for "-AllKnown -NoClassic:$false -NoCore:$false".

.PARAMETER AllKnown
Test the package for ALL known platform versions (SLOW).
Ignored if -Platform is also set and equals $true.

.PARAMETER NoClassic
Exclude .NET Framework from the tests.
Ignored if -Platform is also set and equals $true.

.PARAMETER NoCore
Exclude .NET Core from the tests.
Ignored if -Platform is also set and equals $true.

.PARAMETER Version
Specify a version of the package Abc.Maybe.
When no version is specified, we use the last one from the local NuGet feed.
If the later is empty, we use the one found in Abc.Maybe.props.
If the matching package is not public and does NOT exist in the local NuGet
cache/feed, the script will fail.
Ignored if -NoCI is also set and equals $true.

.PARAMETER NoCI
Force using the package version found in Abc.Maybe.props.
If the matching package is not public and does NOT exist in the local NuGet
cache/feed, the script will fail.

.PARAMETER Runtime
The target runtime to test the package for.
If the runtime is not known, the script will fail silently, and if it is not
supported the script will abort.
Ignored by platforms "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER Reset
Hard clean (reset) the source and test directories before anything else.

.PARAMETER Optimise
Attempt to speed up things a bit when testing many platforms, one at a time.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Help
Print help text then exit.
#>
[CmdletBinding()]
param(
    # Platform selection.
    #
    [Parameter(Mandatory = $false, Position = 0)]
                 [string] $Platform,

    [Alias("a")] [switch] $AllKnown,
                 [switch] $NoClassic,
                 [switch] $NoCore,

    # Package version.
    #
    [Parameter(Mandatory = $false, Position = 1)]
                 [string] $Version,

                 [switch] $NoCI,

    # Runtime selection.
    #
    [Parameter(Mandatory = $false, Position = 2)]
                 [string] $Runtime,

    # Other parameters.
    #
                 [switch] $Reset,
    [Alias("o")] [switch] $Optimise,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

const NET_SDK_PROJECT (Join-Path $TEST_DIR "NETSdk" -Resolve)
const XUNIT_PLATFORM  "net452"

#endregion
################################################################################
#region Helpers.

function Print-Help {
    say @"

Test the package Abc.Maybe.

Usage: test-package.ps1 [arguments]
     -Platform   specify the platform(s) for which to test the package.
  -a|-AllKnown   test the package for ALL known platform versions (SLOW).
     -NoClassic  exclude .NET Framework from the tests.
     -NoCore     exclude .NET Core from the tests.

     -Version    specify a version of the package Abc.Maybe.
     -NoCI       force using the package version found in Abc.Maybe.props.

     -Runtime    specify a target runtime to test for.

     -Reset      reset the solution before anything else.
  -o|-Optimise   attempt to speed up things a bit when testing many platforms one at a time.
  -y|-Yes        do not ask for confirmation before running any test.
  -h|-Help       print this help then exit.

Examples.
> test-package.ps1                              # selected versions of .NET Core and .NET Framework
> test-package.ps1 -NoClassic                   # LTS versions of .NET Core
> test-package.ps1 -NoCore                      # last minor version of each major version of .NET Framework
> test-package.ps1 -AllKnown                    # ALL versions of .NET Core and .NET Framework
> test-package.ps1 -AllKnown -NoClassic         # ALL versions of .NET Core
> test-package.ps1 -AllKnown -NoCore            # ALL versions of .NET Framework
> test-package.ps1 net452 -Runtime win10-x64    # net452 and for the runtime "win10-x64"

"@
}

# ------------------------------------------------------------------------------

# NB: with PowerShell 6.1, there is something called dynamic validateSet, but
# I prefer to stick with v5.1.
function Approve-Platform {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $platform,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [string[]] $knownPlatforms
    )

    if ($platform -notin $knownPlatforms) {
        die "The specified platform is not supported: ""$platform""."
    }
}

# ------------------------------------------------------------------------------

# Validate the package version.
# Non-strict validation, and not following SemVer (eg no build metadata).
function Approve-Version {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version
    )

    $major = "(0|[1-9]\d*)"
    $minor = $major
    $patch = $major

    $x = "\w+[\.\w]*"
    $prere = "$x(\-$x)*"

    $ok = $version -match "^$major\.$minor\.$patch(\-$prere)?$"

    if (-not $ok) {
        die "The specified version number is not well-formed: ""$version""."
    }
}

# ------------------------------------------------------------------------------

$Script:___NoXunitConsole = $false

function Find-XunitRunnerOnce {
    [CmdletBinding()]
    param()

    ___confess "Finding xunit.console.exe."

    if ($___NoXunitConsole) { warn "No Xunit console runner." ; return }

    Restore-NETFrameworkTools

    $path = Find-XunitRunner -Platform $XUNIT_PLATFORM

    if (-not $path) { $Script:___NoXunitConsole = $true ; return }

    $path
}

# ------------------------------------------------------------------------------

# When there is a problem, we revert to -NoCI, nevertheless the process can
# still fail in the end when the package is a release one and has not yet been
# published to NuGet.Org.
function Find-LastLocalVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName
    )

    ___confess "Getting the last version from the local NuGet feed."

    # Don't remove the filter, the directory is never empty (file "_._").
    $last = Get-ChildItem (Join-Path $NUGET_LOCAL_FEED "*") -Include "*.nupkg" `
        | sort LastWriteTime | select -Last 1

    if (-not $last) {
        warn "The local NuGet feed is empty, reverting to -NoCI."
        return Get-PackageVersion $packageName -AsString
    }

    $name = [IO.Path]::GetFileNameWithoutExtension($last)

    # Substring is for the dot just before the version.
    $version = $name.Replace($packageName, "").Substring(1)

    $cachedVersion = Join-Path $NUGET_LOCAL_CACHE $packageName.ToLower() `
        | Join-Path -ChildPath $version

    if (-not (Test-Path $cachedVersion)) {
        # If the cache entry does not exist, we stop the script, otherwise it
        # will restore the CI package into the global, not what we want.
        # Solutions: delete the "broken" package, create a new CI package, etc.
        warn "Local NuGet feed and cache are out of sync, reverting to -NoCI."
        warn "The simplest solution to fix this is to recreate a package."
        return Get-PackageVersion $packageName -AsString
    }

    $version
}

# ------------------------------------------------------------------------------

function Get-RuntimeLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $runtime
    )

    $runtime ? "runtime ""$runtime""" : "default runtime"
}

#endregion
################################################################################
#region Tasks.

# NB: does not cover the solutions for "net45" and "net451".
function Invoke-Restore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $runtime,

        [switch] $allKnown
    )

    SAY-LOUDLY "`nRestoring dependencies for NETSdk, please wait..."

    $args = @("/p:AbcVersion=$version")
    if ($runtime)  { $args += "--runtime:$runtime" }
    if ($allKnown) { $args += "/p:AllKnown=true" }

    & dotnet restore $NET_SDK_PROJECT $args
        || die "Restore task failed."

    say-softly "Dependencies successfully restored."
}

# ------------------------------------------------------------------------------

# NB: does not cover the solutions for "net45" and "net451".
function Invoke-Build {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $runtime,

        [switch] $allKnown,
        [switch] $noRestore
    )

    SAY-LOUDLY "`nBuilding NETSdk, please wait..."

    $args = @("/p:AbcVersion=$version")
    if ($runtime)   { $args += "--runtime:$runtime" }
    if ($allKnown)  { $args += "/p:AllKnown=true" }
    if ($noRestore) { $args += "--no-restore" }

    & dotnet build $NET_SDK_PROJECT $args
        || die "Build task failed."

    say-softly "Project successfully built."
}

# ------------------------------------------------------------------------------

# .NET Framework 4.5/4.5.1 must be handled separately.
# Since it's no longer officialy supported by Microsoft, we can remove them
# if it ever becomes too much of a burden.
# __Only works on Windows__
function Invoke-TestOldStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("net45", "net451")]
        [string] $platform,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $runtime
    )

    "`nTesting the package for ""$platform"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    if (-not $IsWindows) { warn """$platform"" can only be tested on Windows." ; return }

    if ($runtime) {
        warn "Runtime parameter ""$runtime"" is ignored when targetting ""$platform""."
    }

    $xunit = Find-XunitRunnerOnce
    if (-not $xunit) { warn "Skipping." ; return }

    $msbuild = (whereis "MSBuild.exe") ?? (Find-VsWhere -ExitOnError | Find-MSBuild -ExitOnError)

    $projectName = $platform.ToUpper()
    $project = Join-Path $TEST_DIR $projectName -Resolve

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild $project -nologo -v:minimal /p:AbcVersion=$version /t:"Restore;Build"
        || die "Build failed when targeting ""$platform""."

    # NB: Release, not Debug, this is hard-coded within the project file.
    $asm = Join-Path $TEST_DIR "$projectName\bin\Release\$projectName.dll" -Resolve

    & $xunit $asm
        || die "Test task failed when targeting ""$platform""."

    say-softly "Test completed successfully."
}

# ------------------------------------------------------------------------------

# Option -NoRestore is ignored when -Platform is "net45" or "net451".
function Invoke-TestSingle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $platform,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $runtime,

        [switch] $noRestore,
        [switch] $noBuild
    )

    if ($platform -in "net45", "net451") {
        # "net45" and "net451" must be handled separately.
        Invoke-TestOldStyle -Platform $platform -Version $version -Runtime $runtime
        return
    }

    "`nTesting the package for ""$platform"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    $args = "/p:AbcVersion=$version", "/p:AllKnown=true", "-f:$platform"
    if ($runtime)       { $args += "--runtime:$runtime" }
    if ($noBuild)       { $args += "--no-build" }   # NB: no-build => no-restore
    elseif ($noRestore) { $args += "--no-restore" }

    & dotnet test $NET_SDK_PROJECT --nologo $args
        || die "Test task failed when targeting ""$platform""."

    say-softly "Test completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-TestManyInteractive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [string[]] $platformList,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $runtime,

        [switch] $noRestore,
        [switch] $noBuild
    )

    foreach ($platform in $platformList) {
        if (yesno "`nTest the package for ""$platform""?") {
            Invoke-TestSingle `
                -Platform   $platform `
                -Version    $version `
                -Runtime    $runtime `
                -NoRestore: $noRestore `
                -NoBuild:   $noBuild
        }
    }
}

# ------------------------------------------------------------------------------

function Invoke-TestMany {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [string[]] $platformList,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $filter,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 3)]
        [string] $runtime
    )

    "`nTesting the package for ""$filter"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    $pattern = $filter.Substring(0, $filter.Length - 1)
    $platforms = $platformList | where { $_.StartsWith($pattern) }

    $count = $platforms.Length
    if ($count -eq 0) {
        die "After filtering the list of known platforms w/ $filter, there is nothing left to be done."
    }

    # Fast track.
    if ($count -eq 1) {
        $platform = $platforms[0]

        say "Only ""$platform"" was left after filtering the list of known platforms."

        Invoke-TestSingle -Platform $platform -Version  $version -Runtime  $runtime
        return
    }

    "Remaining platorms after filtering: ""{0}""." -f ($platforms -join '", "') `
        | SAY-LOUDLY

    # "net45" and "net451" must be handled separately.
    $targetFrameworks = ($platforms | where { $_ -notin "net45", "net451" }) -join ";"

    $args = "/p:AbcVersion=$version", "/p:AllKnown=true",
        ("/p:TargetFrameworks=" + '\"' + $targetFrameworks + '\"')
    if ($runtime) { $args += "--runtime:$runtime" }

    & dotnet test $NET_SDK_PROJECT --nologo $args
        || die "Test task failed."

    say-softly "Test completed successfully."

    if ("net45" -in $platforms) {
        Invoke-TestOldStyle -Platform "net45" -Version $version -Runtime $runtime
    }
    if ("net451" -in $platforms) {
        Invoke-TestOldStyle -Platform "net451" -Version $version -Runtime $runtime
    }
}

# ------------------------------------------------------------------------------

function Invoke-TestAll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $runtime,

        [switch] $allKnown,
        [switch] $noClassic,
        [switch] $noCore
    )

    # Platform set.
    $platformSet = $noClassic ? ".NET Core"
        : $noCore ? ".NET Framework"
        : ".NET Framework and .NET Core"
    # Platform versions.
    $platformVer = $allKnown ? "ALL versions"
        : $noClassic ? "LTS versions"
        : $noCore ? "last minor version of each major version"
        : "selected versions"

    "`nBatch testing the package for $platformSet, $platformVer, and {0}." `
        -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    $args = @("/p:AbcVersion=$version")
    if ($allKnown)  { $args += "/p:AllKnown=true" }
    if ($noClassic) { $args += "/p:NoClassic=true" }
    if ($noCore)    { $args += "/p:NoCore=true" }
    if ($runtime)   { $args += "--runtime:$runtime" }

    & dotnet test $NET_SDK_PROJECT --nologo $args
        || die "Test task failed."

    say-softly "Test completed successfully."

    if ($allKnown -and (-not $noClassic)) {
        # "net45" and "net451" must be handled separately.
        Invoke-TestOldStyle -Platform "net45" -Version $version -Runtime $runtime
        Invoke-TestOldStyle -Platform "net451" -Version $version -Runtime $runtime
    }
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Hello "this is the script to test the package Abc.Maybe."

readonly PackageName "Abc.Maybe"

# ------------------------------------------------------------------------------

try {
    ___BEGIN___

    pushd $TEST_DIR

    $minClassic, $maxClassic, $minCore, $maxCore  = Get-SupportedPlatforms

    if ($Reset) {
        SAY-LOUDLY "`nResetting repository."

        # Cleaning the "src" directory is only necessary when there are "dangling"
        # cs files in "src" that were created during a previous build. Now, it's
        # no longer a problem (we explicitely exclude "bin" and "obj" in
        # "test\Directory.Build.targets"), but we never know.
        Reset-SourceTree -Yes:$Yes
        Reset-TestTree   -Yes:$Yes
    }

    if ($NoCI) {
        # There were two options, use an explicit version or let the target
        # project decides for us. Both give the __same__ value, but I opted for
        # an explicit version, since I need its value for logging but also
        # because it is safer to do so (see the dicussion on "restore/build traps"
        # in "test\README").
        $Version = Get-PackageVersion $PackageName -AsString
    }
    elseif (-not $Version) {
        $Version = Find-LastLocalVersion $PackageName
    }
    else {
        Approve-Version $Version
    }

    SAY-LOUDLY "`nThe selected package version is ""$Version""."

    if ($Platform -in "", "*") {
        if ($Platform -eq "*") {
            # "*" really means ALL platforms.
            $AllKnown = $true ; $NoClassic = $false ; $NoCore = $false
        }
        elseif ($NoClassic -and $NoCore) {
            die "You set both -NoClassic and -NoCore... There is nothing left to be done."
        }

        if ($Yes -or (yesno "`nTest the package for all selected platforms at once (SLOW)?")) {
            Invoke-TestAll `
                -Version    $Version `
                -Runtime    $Runtime `
                -AllKnown:  $AllKnown `
                -NoClassic: $NoClassic `
                -NoCore:    $NoCore
        }
        else {
            # Building or restoring the solution only once should speed up things a bit.
            if ($Optimise) {
                Invoke-Build -Version $Version -Runtime $Runtime -AllKnown:$AllKnown
            }
            else {
                Invoke-Restore -Version $Version -Runtime $Runtime -AllKnown:$AllKnown
            }

            SAY-LOUDLY "`nNow, you will have the opportunity to choose which platform to test the package for."

            $platformList  = $NoClassic ? @() : $AllKnown ? $maxClassic : $minClassic
            $platformList += $NoCore    ? @() : $AllKnown ? $maxCore    : $minCore

            Invoke-TestManyInteractive `
                -PlatformList   $platformList `
                -Version        $Version `
                -Runtime        $Runtime `
                -NoBuild:       $Optimise `
                -NoRestore:     $true
        }
    }
    else {
        $knownPlatforms = $maxClassic + $maxCore

        if ($Platform.EndsWith("*")) {
            Invoke-TestMany `
                -PlatformList $knownPlatforms `
                -Filter       $Platform `
                -Version      $Version `
                -Runtime      $Runtime
        }
        else {
            # Validating the platform name is not mandatory but, if we don't,
            # the script fails silently when the platform is not supported here.
            Approve-Platform -Platform $Platform -KnownPlatforms $knownPlatforms

            Invoke-TestSingle -Platform $Platform -Version $Version -Runtime $Runtime
        }
    }
}
catch {
    ___CATCH___
}
finally {
    popd

    ___END___
}

#endregion
################################################################################
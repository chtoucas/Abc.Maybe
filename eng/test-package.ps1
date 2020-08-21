# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2019 Narvalo.Org. All rights reserved.

#Requires -Version 7

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

.PARAMETER Framework
Specify the framework(s) for which to test the package.
Unless there is one trailing asterisk (*), this parameter expects a single
framework name. Otherwise, all framework whose name starts with the specified
value (without the asterisk) will be selected. For instance, "net46*" is
translated to ""net461" and "net462". The limit case "*" is a synonym for
"-AllKnown -NoClassic:$false -NoCore:$false".

.PARAMETER AllKnown
Test the package for ALL known framework versions (SLOW)?
Ignored if -Framework is also set and equals $true.

.PARAMETER ListFrameworks
Print the list of supported frameworks, then exit?

.PARAMETER NoClassic
Exclude .NET Framework from the tests?
Ignored if -Framework is also set and equals $true.

.PARAMETER NoCore
Exclude .NET Core from the tests?
Ignored if -Framework is also set and equals $true.

.PARAMETER Configuration
Specify the configuration to test for. Default (explicit) = "Release".

.PARAMETER Version
Pick a specific version of the package Abc.Maybe.
When no version is specified, we use the last one from the local NuGet feed.
If the later is empty, we use the one found in Abc.Maybe.props.
Beware, if the matching package does NOT exist in the local NuGet cache/feed,
the script will fail in the following cases:
- the package has not yet been published to NuGet.Org.
- the package has been published but there has been breaking changes in between.
Ignored if -Official is also set and equals $true.

.PARAMETER Official
Force using the (official) package version found in Abc.Maybe.props?
See warnings in -Version.

.PARAMETER Runtime
The target runtime to test the package for.
If the runtime is not known, the script will fail silently, and if it is not
supported the script will abort.

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER Reset
Hard clean (reset) the source and test directories before anything else?

.PARAMETER Optimise
Attempt to speed up things a bit when testing many frameworks, one at a time?

.PARAMETER Yes
Do not ask for confirmation?

.PARAMETER Help
Print help text then exit?
#>
[CmdletBinding()]
param(
    # Framework selection.
    #
    [Parameter(Mandatory = $false, Position = 0)]
                 [string] $Framework,
    [Alias("a")] [switch] $AllKnown,
    [Alias("l")] [switch] $ListFrameworks,
                 [switch] $NoClassic,
                 [switch] $NoCore,

    # Configuration.
    #
    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration = "Release",

    # Package version.
    #
    [Parameter(Mandatory = $false, Position = 2)]
                 [string] $Version,
                 [switch] $Official,

    # Runtime selection.
    #
    [Parameter(Mandatory = $false, Position = 3)]
                 [string] $Runtime,

    # Other parameters.
    #
                 [switch] $Reset,
    [Alias("o")] [switch] $Optimise,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "lib\abc.ps1")

# ------------------------------------------------------------------------------

const TEST_PROJECT_NAME "Abc.PackageTests"
const TEST_PROJECT (Join-Path $TEST_DIR "Package" -Resolve)

const OLDSTYLE_XUNIT_FRAMEWORKS @("net451", "net45")
const OLDSTYLE_XUNIT_RUNNER_FRAMEWORK "net452"

#endregion
################################################################################
#region Helpers.

function Print-Help {
    say @"

Test the package Abc.Maybe.

Usage: test-package.ps1 [arguments]
     -Framework      specify the framework(s) for which to test the package.
  -a|-AllKnown       test the package for ALL known framework versions (SLOW)?
  -l|-ListFrameworks  print the list of supported frameworks, then exit?
     -NoClassic      exclude .NET Framework from the tests?
     -NoCore         exclude .NET Core from the tests?

  -c|-Configuration  specify the configuration to test for.

     -Version        pick a specific version of the package Abc.Maybe.
     -Official       force using the package version found in Abc.Maybe.props?

     -Runtime        specify a target runtime to test for.

     -Reset          reset the solution before anything else?
  -o|-Optimise       attempt to speed up things a bit when testing many frameworks one at a time?
  -y|-Yes            do not ask for confirmation before running any test?
  -h|-Help           print this help then exit?

Examples.
> test-package.ps1                              # selected versions of .NET Core and .NET Framework
> test-package.ps1 -NoClassic                   # LTS versions of .NET Core
> test-package.ps1 -NoCore                      # last minor version of each major version of .NET Framework
> test-package.ps1 -AllKnown                    # ALL versions of .NET Core and .NET Framework
> test-package.ps1 -AllKnown -NoClassic         # ALL versions of .NET Core
> test-package.ps1 -AllKnown -NoCore            # ALL versions of .NET Framework
> test-package.ps1 net461 -Runtime win10-x64    # net461 and for the runtime "win10-x64"

Looking for more help?
> Get-Help -Detailed test-package.ps1

"@
}

# ------------------------------------------------------------------------------

function Approve-Framework {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $framework,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [string[]] $knownFrameworks
    )

    if ($framework -notin $knownFrameworks) {
        die "The specified framework is not supported: ""$framework""."
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

    Restore-NETFxTools | Out-Host

    $path = Find-XunitRunner -Framework $OLDSTYLE_XUNIT_RUNNER_FRAMEWORK

    if (-not $path) { $Script:___NoXunitConsole = $true ; return }

    $path
}

# ------------------------------------------------------------------------------

# When there is a problem, we revert to -Official, which could be problematic
# (see warnings in -Version).
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
        warn "The local NuGet feed is empty, reverting to -Official."
        return Get-PackageVersion $packageName -AsString
    }

    $name = [IO.Path]::GetFileNameWithoutExtension($last)

    # Substring is used to remove the dot just before the version.
    $version = $name.Replace($packageName, "").Substring(1)

    $cachedPackage = Join-Path $NUGET_LOCAL_CACHE $packageName.ToLower() `
        | Join-Path -ChildPath $version

    if (-not (Test-Path $cachedPackage)) {
        warn "Local NuGet feed and cache are out of sync."

        if (yesno "Add ${name} to the local NuGet cache?") {
            & dotnet restore $NUGET_CACHING_PROJECT /p:AbcPackageVersion=$version | Out-Host
                || die "Failed to update the local NuGet cache."
        }
        else {
            # If the cache entry does not exist, we stop the script, otherwise it
            # will restore the local package into the global cache, not what we
            # want. Solutions: delete the "broken" package, create a new local
            # package, etc.
            warn "Reverting to -Official."
            warn "Next time, the simplest solution to fix this is to recreate a package."
            return Get-PackageVersion $packageName -AsString
        }
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

# ------------------------------------------------------------------------------

function Get-TargetFrameworks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList
    )

    '\"' + ($frameworkList -join ";") + '\"'
}

#endregion
################################################################################
#region Tasks.

function Invoke-Restore {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime
    )

    SAY-LOUDLY "`nRestoring dependencies for $TEST_PROJECT_NAME, please wait..."

    $targetFrameworks = Get-TargetFrameworks $frameworkList

    $args =  "/p:AbcPackageVersion=$version", "/p:TargetFrameworks=$targetFrameworks"
    if ($runtime)  { $args += "--runtime:$runtime" }

    & dotnet restore $TEST_PROJECT $args
        || die "Restore task failed."

    say-softly "Dependencies successfully restored."
}

# ------------------------------------------------------------------------------

function Invoke-Build {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime
    )

    SAY-LOUDLY "`nBuilding $TEST_PROJECT_NAME, please wait..."

    $targetFrameworks = Get-TargetFrameworks $frameworkList

    $args = `
        "-c:$configuration",
        "/p:AbcPackageVersion=$version",
        "/p:TargetFrameworks=$targetFrameworks"
    if ($runtime) { $args += "--runtime:$runtime" }

    & dotnet build $TEST_PROJECT $args
        || die "Build task failed."

    say-softly "Project successfully built."
}

# ------------------------------------------------------------------------------

# .NET Framework 4.5/4.5.1 must be handled separately.
# Since it's no longer officialy supported by Microsoft, we can remove them
# if it ever becomes too much of a burden.
# __Only works on Windows__
# TODO: I wonder if it does really make sense at all since we actually use
# .NET 4.5.2.
function Invoke-TestOldStyle {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -in $OLDSTYLE_XUNIT_FRAMEWORKS })]
        [string] $framework,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime,

        [switch] $noRestore,
        [switch] $noBuild
    )

    "`nTesting the package for ""$framework"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    if (-not $IsWindows) { warn """$framework"" can only be tested on Windows." ; return }

    if ($runtime) {
        warn "Runtime parameter ""$runtime"" is ignored when targeting ""$framework""."
    }

    $xunit = Find-XunitRunnerOnce
    if (-not $xunit) { warn "Skipping." ; return }

    if (-not $noBuild) {
        $args = `
            "-c:$configuration",
            "-f:$framework",
            "/p:AbcPackageVersion=$version",
            "/p:AllKnown=true",
            "/p:NotSupported=true"
        if ($runtime)   { $args += "--runtime:$runtime" }
        if ($noRestore) { $args += "--no-restore" }

        & dotnet build $TEST_PROJECT --nologo $args
            || die "Build failed when targeting ""$framework""."
    }

    $asm = Join-Path $TEST_PROJECT "bin\$configuration\$framework\$TEST_PROJECT_NAME.dll" -Resolve

    & $xunit $asm
        || die "Test task failed when targeting ""$framework""."

    say-softly "Test completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-TestSingle {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $framework,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime,

        [switch] $noRestore,
        [switch] $noBuild
    )

    if ($framework -in $OLDSTYLE_XUNIT_FRAMEWORKS) {
        Invoke-TestOldStyle `
            -Framework     $framework `
            -Configuration $configuration `
            -Version       $version `
            -Runtime       $runtime `
            -NoRestore:    $noRestore `
            -NoBuild:      $noBuild
        return
    }

    "`nTesting the package for ""$framework"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    $args = `
        "-c:$configuration",
        "-f:$framework",
        "/p:AbcPackageVersion=$version",
        "/p:AllKnown=true",
        "/p:NotSupported=true"
    if ($runtime)       { $args += "--runtime:$runtime" }
    if ($noBuild)       { $args += "--no-build" }   # NB: no-build => no-restore
    elseif ($noRestore) { $args += "--no-restore" }

    & dotnet test $TEST_PROJECT --nologo $args
        || die "Test task failed when targeting ""$framework""."

    say-softly "Test completed successfully."
}

# ------------------------------------------------------------------------------

function Invoke-TestManyInteractive {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime,

        [switch] $noRestore,
        [switch] $noBuild
    )

    foreach ($framework in $frameworkList) {
        if (yesno "`nTest the package for ""$framework""?") {
            Invoke-TestSingle `
                -Framework     $framework `
                -Configuration $configuration `
                -Version       $version `
                -Runtime       $runtime `
                -NoRestore:    $noRestore `
                -NoBuild:      $noBuild
        }
    }
}

# ------------------------------------------------------------------------------

function Invoke-TestAny {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime
    )

    $frameworks = $frameworkList | where { $_ -notin $OLDSTYLE_XUNIT_FRAMEWORKS }
    $targetFrameworks = Get-TargetFrameworks $frameworks

    $args = `
        "-c:$configuration",
        "/p:AbcPackageVersion=$version",
        "/p:TargetFrameworks=$targetFrameworks"
    if ($runtime) { $args += "--runtime:$runtime" }

    & dotnet test $TEST_PROJECT --nologo $args
        || die "Test task failed."

    say-softly "Test completed successfully."

    say "`nContinuing with ""old-style"" frameworks if any."
    foreach ($framework in $OLDSTYLE_XUNIT_FRAMEWORKS) {
        if ($framework -in $frameworkList) {
            Invoke-TestOldStyle `
                -Framework     $framework `
                -Configuration $configuration `
                -Version       $version `
                -Runtime       $runtime
        }
    }
}

# ------------------------------------------------------------------------------

function Invoke-TestMany {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime
    )

    "`nTesting the package for ""$filter"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    $pattern = $filter.Substring(0, $filter.Length - 1)
    $filteredFrameworks = $frameworkList | where { $_.StartsWith($pattern, "InvariantCultureIgnoreCase") }

    $count = $filteredFrameworks.Length
    if ($count -eq 0) {
        die "After filtering the list of known frameworks w/ $filter, there is nothing left to be done."
    }

    # Fast track.
    if ($count -eq 1) {
        $framework = $filteredFrameworks[0]

        say "Only ""$framework"" was left after filtering the list of known frameworks."

        Invoke-TestSingle `
            -Framework     $framework `
            -Configuration $configuration `
            -Version       $version `
            -Runtime       $runtime
        return
    }

    $frameworkSet = ($filteredFrameworks -join '", "')
    say "Remaining platorms after filtering: ""$frameworkSet""."

    SAY-LOUDLY "`nBatch testing the package."

    Invoke-TestAny `
        -FrameworkList $filteredFrameworks `
        -Configuration $configuration `
        -Version       $version `
        -Runtime       $runtime
}

# ------------------------------------------------------------------------------

function Invoke-TestAll {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $frameworkList,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $configuration,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [string] $runtime,

        [switch] $allKnown,
        [switch] $noClassic,
        [switch] $noCore
    )

    # Framework set.
    $frameworkSet = $noClassic ? ".NET Core"
        : $noCore ? ".NET Framework"
        : ".NET Framework and .NET Core"
    # Framework versions.
    $frameworkVer = $allKnown ? "ALL versions"
        : $noClassic ? "LTS versions"
        : $noCore ? "last minor version of each major version"
        : "default versions"

    "`nBatch testing the package for $frameworkSet, $frameworkVer, and {0}." `
        -f (Get-RuntimeLabel $runtime) `
        | SAY-LOUDLY

    Invoke-TestAny `
        -FrameworkList $frameworkList `
        -Configuration $configuration `
        -Version       $version `
        -Runtime       $runtime
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

    $minClassic, $maxClassic, $minCore, $maxCore = Get-SupportedFrameworks -NotSupported

    if ($ListFrameworks) {
        say (@"

Supported .NET Frameworks (maximal and minimal sets):
- "{0}"
- "{1}"

Supported .NET Core (maximal and minimal sets):
- "{2}"
- "{3}"
"@ -f ($maxClassic -join '", "'),
    ($minClassic -join '", "'),
    ($maxCore -join '", "'),
    ($minCore -join '", "'))

        exit
    }

    if ($Reset) {
        SAY-LOUDLY "`nResetting repository."

        # Cleaning the "src" directory is only necessary when there are "dangling"
        # cs files in "src" that were created during a previous build. Now, it's
        # no longer a problem (we explicitely exclude "bin" and "obj" in
        # "test\Directory.Build.targets"), but we never know.
        Reset-SourceTree -Yes:$Yes
        Reset-TestTree   -Yes:$Yes
    }

    if ($Official) {
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

    if ($Framework -in "", "*") {
        if ($Framework -eq "*") {
            # "*" really means ALL frameworks.
            $AllKnown = $true ; $NoClassic = $false ; $NoCore = $false
        }
        elseif ($NoClassic -and $NoCore) {
            die "You set both -NoClassic and -NoCore... There is nothing left to be done."
        }

        $frameworkList  = $NoCore    ? @() : $AllKnown ? $maxCore    : $minCore
        $frameworkList += $NoClassic ? @() : $AllKnown ? $maxClassic : $minClassic

        if ($Yes -or (yesno "`nTest the package for all selected frameworks at once (SLOW)?")) {
            Invoke-TestAll `
                -FrameworkList $frameworkList `
                -Configuration $Configuration `
                -Version       $Version `
                -Runtime       $Runtime `
                -AllKnown:     $AllKnown `
                -NoClassic:    $NoClassic `
                -NoCore:       $NoCore
        }
        else {
            # Building or restoring the solution only once should speed up things a bit.
            if ($Optimise) {
                Invoke-Build `
                    -FrameworkList $frameworkList `
                    -Configuration $Configuration `
                    -Version       $Version `
                    -Runtime       $Runtime
            }
            else {
                Invoke-Restore `
                    -FrameworkList $frameworkList `
                    -Configuration $Configuration `
                    -Version       $Version `
                    -Runtime       $Runtime
            }

            SAY-LOUDLY "`nNow, you will have the opportunity to choose which framework to test the package for."

            Invoke-TestManyInteractive `
                -FrameworkList $frameworkList `
                -Configuration $Configuration `
                -Version       $Version `
                -Runtime       $Runtime `
                -NoBuild:      $Optimise `
                -NoRestore:    $true
        }
    }
    else {
        $knownFrameworks = $maxCore + $maxClassic

        if ($Framework.EndsWith("*")) {
            Invoke-TestMany `
                -FrameworkList $knownFrameworks `
                -Filter        $Framework `
                -Configuration $Configuration `
                -Version       $Version `
                -Runtime       $Runtime
        }
        else {
            # Validating the framework name is not mandatory but, if we don't,
            # the script fails silently when the framework is not supported here.
            Approve-Framework -Framework $Framework -KnownFrameworks $knownFrameworks

            Invoke-TestSingle `
                -Framework     $Framework `
                -Configuration $Configuration `
                -Version       $Version `
                -Runtime       $Runtime
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
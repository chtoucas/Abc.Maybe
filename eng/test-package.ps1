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
Ignored if -Current is also set and equals $true.

.PARAMETER Current
Use the package version found in Abc.Maybe.props.

.PARAMETER Runtime
The target runtime to test the package for.
If the runtime is not known, the script will fail silently, and if it is not
supported the script will abort.
Ignored by platforms "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER Optimise
Attempt to speed up things a bit when testing many platforms, one at a time.

.PARAMETER Reset
Hard clean (reset) the source and test directories before anything else.

.PARAMETER Yes
Do not ask for confirmation.

.EXAMPLE
PS> test-package.ps1
Test the package for selected versions of .NET Core and .NET Framework

.EXAMPLE
PS> test-package.ps1 -NoClassic
Test the package for the LTS versions of .NET Core.

.EXAMPLE
PS> test-package.ps1 -NoCore
Test the package for the last minor version of each major version of .NET Framework.

.EXAMPLE
PS> test-package.ps1 -AllKnown
Test the package for ALL versions of .NET Core and .NET Framework.

.EXAMPLE
PS> test-package.ps1 -AllKnown -NoClassic
Test the package for ALL versions of .NET Core.

.EXAMPLE
PS> test-package.ps1 -AllKnown -NoCore
Test the package for ALL versions of .NET Framework.

.EXAMPLE
PS> test-package.ps1 net452 -Runtime win10-x64
Test the package for a specific platform and for the runtime "win10-x64".
#>
[CmdletBinding()]
param(
    # Platform selection.
    #
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias("p")] [string] $Platform = "",

    [Alias("a")] [switch] $AllKnown,
                 [switch] $NoClassic,
                 [switch] $NoCore,

    # Package version.
    #
    [Parameter(Mandatory = $false, Position = 1)]
    [Alias("v")] [string] $Version = "",

    [Alias("c")] [switch] $Current,

    # Runtime selection.
    #
    [Parameter(Mandatory = $false, Position = 2)]
    [Alias("r")] [string] $Runtime = "",

    # Other parameters.
    #
    [Alias("o")] [switch] $Optimise,
                 [switch] $Reset,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

(Join-Path $TEST_DIR "NETSdk" -Resolve) `
    | New-Variable -Name "NET_SDK_PROJECT" -Scope Script -Option Constant

New-Variable -Name "XUNIT_PLATFORM" -Value "net452" -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers.

function Write-Usage {
    Say @"

Test the package Abc.Maybe.

Usage: test-package.ps1 [arguments]
  -p|-Platform   specify the platform(s) for which to test the package.
  -a|-AllKnown   test the package for ALL known platform versions (SLOW).
     -NoClassic  exclude .NET Framework from the tests.
     -NoCore     exclude .NET Core from the tests.

  -v|-Version    specify a version of the package Abc.Maybe.
  -c|-Current    use the package version found in Abc.Maybe.props.

  -r|-Runtime    specify a target runtime to test for.

  -o|-Optimise   attempt to speed up things a bit when testing many platforms one at a time.
     -Reset      reset the solution before anything else.
  -y|-Yes        do not ask for confirmation before running any test.
  -h|-Help       print this help and exit.

"@
}

# ------------------------------------------------------------------------------

# NB: with PowerShell 6.1, there is something called dynamic validateSet, but
# I prefer to stick with v5.1.
function Validate-Platform {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $platform,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [string[]] $knownPlatforms
    )

    foreach ($p in $knownPlatforms) { if ($platform -eq $p) { return } }

    Croak "The specified platform is not supported: ""$platform""."
}

# ------------------------------------------------------------------------------

# Validate the package version.
# Non-strict validation, and not following SemVer (eg no build metadata).
function Validate-Version {
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
        Croak "The specified version number is not well-formed: ""$version""."
    }
}

# ------------------------------------------------------------------------------

function Find-XunitRunnerOnce {
    [CmdletBinding()]
    param()

    Write-Verbose "Finding xunit.console.exe."

    if ($NoXunitConsole) { Carp "No Xunit console runner." ; return $null }

    Restore-NETFrameworkTools

    $path = Find-XunitRunner -Platform $XUNIT_PLATFORM

    if ($path -eq $null) { $Script:NoXunitConsole = $true ; return $null }

    $path
}

# ------------------------------------------------------------------------------

# When there is a problem, we revert to -Current, nevertheless the process can
# still fail in the end when the package is a release one and has not yet been
# published to NuGet.Org.
function Find-LastLocalVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName
    )

    Write-Verbose "Getting the last version from the local NuGet feed."

    # Don't remove the filter, the directory is never empty (file "_._").
    $last = Get-ChildItem (Join-Path $NUGET_LOCAL_FEED "*") -Include "*.nupkg" `
        | sort LastWriteTime | select -Last 1

    if ($last -eq $null) {
        Carp "The local NuGet feed is empty, reverting to -Current."
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
        Carp "Local NuGet feed and cache are out of sync, reverting to -Current."
        Carp "For the next time, the simplest solution is to recreate a package."
        return Get-PackageVersion $packageName -AsString
    }

    $version
}

# ------------------------------------------------------------------------------

function Get-RuntimeLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $runtime = ""
    )

    if ($runtime -eq "") { return "default runtime" } else { return "runtime ""$runtime""" }
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
        [string] $runtime = "",

        [switch] $allKnown
    )

    Say-LOUDLY "`nRestoring dependencies for NETSdk, please wait..."

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }
    if ($allKnown) { $args += "/p:AllKnown=true" }

    & dotnet restore $NET_SDK_PROJECT $args /p:AbcVersion=$version | Out-Host

    Assert-CmdSuccess -Error "Restore task failed." `
        -Success "Dependencies successfully restored."
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
        [string] $runtime = "",

        [switch] $allKnown,
        [switch] $noRestore
    )

    Say-LOUDLY "`nBuilding NETSdk, please wait..."

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }
    if ($allKnown)  { $args += "/p:AllKnown=true" }
    if ($noRestore) { $args += "--no-restore" }

    & dotnet build $NET_SDK_PROJECT $args /p:AbcVersion=$version | Out-Host

    Assert-CmdSuccess -Error "Build task failed." -Success "Project successfully built."
}

# ------------------------------------------------------------------------------

# .NET Framework 4.5/4.5.1 must be handled separately.
# Since it's no longer officialy supported by Microsoft, we can remove them
# if it ever becomes too much of a burden.
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
        [string] $runtime = ""
    )

    "`nTesting the package v$version for ""$platform"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | Say-LOUDLY

    if ($runtime -ne "") {
        Carp "Runtime parameter ""$runtime"" is ignored when targetting ""$platform""."
    }

    $xunit = Find-XunitRunnerOnce
    if ($xunit -eq $null) { Say "Skipping." ; return }

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere

    $projectName = $platform.ToUpper()
    $project = Join-Path $TEST_DIR $projectName -Resolve

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild $project -nologo -v:minimal /p:AbcVersion=$version /t:"Restore;Build" | Out-Host

    Assert-CmdSuccess -Error "Build failed when targeting ""$platform""."

    # NB: Release, not Debug, this is hard-coded within the project file.
    $asm = Join-Path $TEST_DIR "$projectName\bin\Release\$projectName.dll" -Resolve

    & $xunit $asm | Out-Host

    Assert-CmdSuccess -Error "Test task failed when targeting ""$platform""." `
        -Success "Test completed successfully."
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
        [string] $runtime = "",

        [switch] $noRestore,
        [switch] $noBuild
    )

    if (($platform -eq "net45") -or ($platform -eq "net451")) {
        # "net45" and "net451" must be handled separately.
        Invoke-TestOldStyle -Platform $platform -Version $version -Runtime $runtime
        return
    }

    "`nTesting the package v$version for ""$platform"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | Say-LOUDLY

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }
    if ($noBuild)       { $args += "--no-build" }   # NB: no-build => no-restore
    elseif ($noRestore) { $args += "--no-restore" }

    & dotnet test $NET_SDK_PROJECT --nologo -f $platform $args `
        /p:AbcVersion=$version /p:AllKnown=true `
        | Out-Host

    Assert-CmdSuccess -Error "Test task failed when targeting ""$platform""." `
        -Success "Test completed successfully."
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
        [string] $runtime = "",

        [switch] $noRestore,
        [switch] $noBuild
    )

    foreach ($platform in $platformList) {
        if (Confirm-Yes "`nTest the package for ""$platform""?") {
            Invoke-TestSingle `
                -Platform $platform `
                -Version  $version `
                -Runtime  $runtime `
                -NoRestore:$noRestore `
                -NoBuild:$noBuild
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
        [string] $runtime = ""
    )

    "`nTesting the package v$version for ""$filter"" and {0}." -f (Get-RuntimeLabel $runtime) `
        | Say-LOUDLY

    $pattern = $filter.Substring(0, $filter.Length - 1)
    $filteredList = $platformList | where { $_.StartsWith($pattern) }

    $count = $filteredList.Length
    if ($count -eq 0) {
        Croak "After filtering the list of known platforms w/ $filter, there is nothing left to be done."
    }

    # Fast track.
    if ($count -eq 1) {
        $platform = $filteredList[0]

        Say "Only ""$platform"" was left after filtering the list of known platforms."

        Invoke-TestSingle -Platform $platform -Version  $version -Runtime  $runtime
        return
    }

    "Remaining platorms after filtering: ""{0}""." -f ($filteredList -join '", "') `
        | Say-LOUDLY

    # "net45" and "net451" must be handled separately.
    $net45 = $false
    $net451 = $false
    $targetList = @()
    foreach ($item in $filteredList) {
        switch -Exact ($item) {
            "net45"  { $net45  = $true }
            "net451" { $net451 = $true }
            Default  { $targetList += $item }
        }
    }

    $args = @("/p:TargetFrameworks=" + '\"' + ($targetList -join ";") + '\"')
    if ($runtime -ne "") { $args += "--runtime:$runtime" }

    & dotnet test $NET_SDK_PROJECT --nologo $args `
        /p:AllKnown=true `
        /p:AbcVersion=$version `
        | Out-Host

    Assert-CmdSuccess -Error "Test task failed." -Success "Test completed successfully."

    if ($net45) {
        Invoke-TestOldStyle -Platform "net45" -Version $version -Runtime $runtime
    }
    if ($net451) {
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
        [string] $runtime = "",

        [switch] $allKnown,
        [switch] $noClassic,
        [switch] $noCore
    )

    # Platform set.
    if ($noClassic)     { $platformSet = ".NET Core" }
    elseif ($noCore)    { $platformSet = ".NET Framework" }
    else                { $platformSet = ".NET Framework and .NET Core" }
    # Platform versions.
    if ($allKnown)      { $platformVer = "ALL versions" }
    elseif ($noClassic) { $platformVer = "LTS versions" }
    elseif ($noCore)    { $platformVer = "last minor version of each major version" }
    else                { $platformVer = "selected versions" }

    "`nBatch testing the package v$version for $platformSet, $platformVer, and {0}." `
        -f (Get-RuntimeLabel $runtime) `
        | Say-LOUDLY

    $args = @()

    if ($allKnown)       { $args += "/p:AllKnown=true" }
    if ($noClassic)      { $args += "/p:NoClassic=true" }
    if ($noCore)         { $args += "/p:NoCore=true" }
    if ($runtime -ne "") { $args += "--runtime:$runtime" }

    & dotnet test $NET_SDK_PROJECT --nologo $args /p:AbcVersion=$version | Out-Host

    Assert-CmdSuccess -Error "Test task failed." -Success "Test completed successfully."

    if ($allKnown -and (-not $noClassic)) {
        # "net45" and "net451" must be handled separately.
        Invoke-TestOldStyle -Platform "net45" -Version $version -Runtime $runtime
        Invoke-TestOldStyle -Platform "net451" -Version $version -Runtime $runtime
    }
}

#endregion
################################################################################
#region Main.

if ($Help) {
    Write-Usage
    exit 0
}

Say "This is the test script for the package Abc.Maybe."

# ------------------------------------------------------------------------------

$NoXunitConsole = $false

# Keep in sync w/ test\NETSdk\NETSdk.csproj.

$LastClassic = `
    "net452",
    "net462",
    "net472",
    "net48"
$AllClassic = `
    "net45",
    "net451",
    "net452",
    "net46",
    "net461",
    "net462",
    "net47",
    "net471",
    "net472",
    "net48"

$LTSCore = `
    "netcoreapp2.1",
    "netcoreapp3.1"
$AllCore = `
    "netcoreapp2.0",
    "netcoreapp2.1",
    "netcoreapp2.2",
    "netcoreapp3.0",
    "netcoreapp3.1"

# ------------------------------------------------------------------------------

try {
    pushd $TEST_DIR

    New-Variable -Name "PackageName" -Value "Abc.Maybe" -Option ReadOnly

    if ($Reset) {
        Say-LOUDLY "`nResetting repository."

        # Cleaning the "src" directory is only necessary when there are "dangling"
        # cs files in "src" that were created during a previous build. Now, it's
        # no longer a problem (we explicitely exclude "bin" and "obj" in
        # "test\Directory.Build.targets"), but we never know.
        Reset-SourceTree -Yes:$Yes
        Reset-TestTree   -Yes:$Yes
    }

    if ($Current) {
        # There were two options, use an explicit version or let the target
        # project decides for us. Both give the __same__ value, but I opted for
        # an explicit version, since I need its value for logging but also
        # because it is safer to do so (see the dicussion on "restore/build traps"
        # in "test\README").
        $Version = Get-PackageVersion $PackageName -AsString
    }
    elseif ($Version -eq "") {
        $Version = Find-LastLocalVersion $PackageName
    }
    else {
        Validate-Version $Version
    }

    if (($Platform -eq "") -or ($Platform -eq "*")) {
        if ($Platform -eq "*") {
            # "*" really means ALL platforms.
            $AllKnown = $true ; $NoClassic = $false ; $NoCore = $false
        }
        elseif ($NoClassic -and $NoCore) {
            Croak "You set both -NoClassic and -NoCore... There is nothing left to be done."
        }

        if ($Yes -or (Confirm-Yes "`nTest the package for all selected platforms at once (SLOW)?")) {
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
                $noBuild = $true

                Invoke-Build -Version $Version -Runtime $Runtime -AllKnown:$AllKnown
            }
            else {
                $noBuild = $false

                Invoke-Restore -Version $Version -Runtime $Runtime -AllKnown:$AllKnown
            }

            Say-LOUDLY "`nNow, you will have the opportunity to choose which platform to test the package for."

            $platformList = @()

            if ($NoClassic)    { $platformList = @() }
            elseif ($AllKnown) { $platformList = $AllClassic }
            else               { $platformList = $LastClassic }

            if (-not $NoCore) {
                if ($AllKnown) { $platformList += $AllCore }
                else { $platformList += $LTSCore }
            }

            Invoke-TestManyInteractive `
                -PlatformList   $platformList `
                -Version        $Version `
                -Runtime        $Runtime `
                -NoBuild:       $noBuild `
                -NoRestore:     $true
        }
    }
    else {
        $knownPlatforms = $AllClassic + $AllCore

        if ($Platform.EndsWith("*")) {
            Invoke-TestMany `
                -PlatformList $knownPlatforms -Filter $Platform `
                -Version $Version `
                -Runtime $Runtime
        }
        else {
            # Validating the platform name is not mandatory but, if we don't,
            # the script fails silently when the platform is not supported here.
            Validate-Platform -Platform $Platform -KnownPlatforms $knownPlatforms

            Invoke-TestSingle -Platform $Platform -Version $Version -Runtime $Runtime
        }
    }
}
catch {
    Confess $_
}
finally {
    popd

    if ($NoXunitConsole) {
        Carp "Tests for .NET Framework 4.5 / 4.5.1 were skipped."
        exit 2
    }
    else {
        exit 0
    }
}

#endregion
################################################################################
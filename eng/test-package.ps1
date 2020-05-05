#Requires -Version 4.0

################################################################################
#region Preamble.

<#
.SYNOPSIS
Test the package Abc.Maybe for net(4,5,6,7,8)x and netcoreapp(2,3).x.
Matching .NET Framework Developer Packs or Targeting Packs must be installed
locally, the later should suffice. The script will fail with error MSB3644 when
it is not the case.

.PARAMETER Platform
Specify a single platform for which to test the package.
If the platform is not known, the script will fail silently.

.PARAMETER Version
Specify a version of the package Abc.Maybe.
When no version is specified, we use the one found in Abc.Maybe.props.

.PARAMETER Runtime
The target runtime to test the package for.
If the runtime is not known, the script will fail silently, and if it is not
supported the script will abort.
Ignored by platforms "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER AllKnown
Test the package for ALL known platform versions (SLOW).
Ignored if -Platform is also set.

.PARAMETER NoClassic
Exclude .NET Framework from the tests.
Ignored if -Platform is also set.

.PARAMETER NoCore
Exclude .NET Core from the tests.
Ignored if -Platform is also set.

.PARAMETER NoSpeedUp
Do not attempt to speed up things when testing many platforms one at a time.

.PARAMETER Clean
Hard clean the source and test directories before anything else.

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
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias("p")] [string] $Platform = "",

    [Parameter(Mandatory = $false, Position = 1)]
    [Alias("v")] [string] $Version = "",

    [Parameter(Mandatory = $false, Position = 2)]
    [Alias("r")] [string] $Runtime = "",

    [Alias("a")] [switch] $AllKnown,
                 [switch] $NoClassic,
                 [switch] $NoCore,
                 [switch] $NoSpeedUp,
    [Alias("c")] [switch] $Clean,
    [Alias("y")] [switch] $Yes,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

(Join-Path $TEST_DIR "NETSdk" -Resolve) `
    | New-Variable -Name "NET_SDK_PROJECT" -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers.

function Write-Usage {
    Say @"

Test package Abc.Maybe

Usage: pack.ps1 [switches].
  -p|-Platform    specify a single platform for which to test the package.
  -v|-Version     specify a version of the package Abc.Maybe.
  -r|-Runtime     specify a target runtime to test for.
  -a|-AllKnown    test the package for ALL known platform versions (SLOW).
    |-NoClassic   exclude .NET Framework from the tests.
    |-NoCore      exclude .NET Core from the tests.
    |-NoSpeedUp   do not attempt to speed up things when testing many platforms one at a time.
  -c|-Clean       hard clean the solution before anything else.
  -y|-Yes         do not ask for confirmation before running any test.
  -h|-Help        print this help and exit.

"@
}

# ------------------------------------------------------------------------------

# .NET Framework 4.5/4.5.1 must be handled separately.
# Since it's no longer officialy supported by Microsoft, we can remove them
# if it ever becomes too much of a burden.

function Find-XunitRunner {
    [CmdletBinding()]
    param()

    Write-Verbose "Finding xunit.console.exe."

    $version = "2.4.1"
    $platform = "net452"

    $path = Join-Path ${ENV:USERPROFILE} `
        ".nuget\packages\xunit.runner.console\$version\tools\$platform\xunit.console.exe"

    if (-not (Test-Path $path)) {
        Carp "Couldn't find Xunit Console Runner v$version where I expected it to be."
        return $null
    }

    Write-Verbose "xunit.console.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

function Get-RuntimeString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    if ($runtime -eq "") { $runtime = "default" }
    "(runtime = ""$runtime"")"
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
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $allKnown
    )

    Chirp "Restoring dependencies for NETSdk, please wait..."

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }
    if ($allKnown) { $args += "/p:AllKnown=true" }

    & dotnet restore $NET_SDK_PROJECT $args /p:AbcVersion=$version | Out-Host
    Assert-CmdSuccess -ErrMessage "Restore task failed."
}

# ------------------------------------------------------------------------------

# NB: does not cover the solutions for "net45" and "net451".
function Invoke-Build {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $allKnown,
        [switch] $noRestore
    )

    Chirp "Building NETSdk, please wait..."

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }
    if ($allKnown)  { $args += "/p:AllKnown=true" }
    if ($noRestore) { $args += "--no-restore" }

    & dotnet build $NET_SDK_PROJECT $args /p:AbcVersion=$version | Out-Host
    Assert-CmdSuccess -ErrMessage "Restore task failed."
}

# ------------------------------------------------------------------------------

function Invoke-TestOldStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $platform,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    $runtimeStr = Get-RuntimeString $runtime
    Chirp "Testing the package v$version for ""$platform"" $runtimeStr."

    if ($runtime -ne "") { Carp "Runtime parameter ""$runtime"" is ignored by ""$platform""." }

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere
    $xunit   = Find-XunitRunner

    if ($xunit -eq $null) {
        return
    }

    $projectName = $platform.ToUpper()
    $project = Join-Path $TEST_DIR $projectName -Resolve

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild $project -v:minimal /p:AbcVersion=$version /t:"Restore;Build" | Out-Host
    Assert-CmdSuccess -ErrMessage "Build task failed when targeting ""$platform""."

    # NB: Release, not Debug, this is hard-coded within the project file.
    $asm = Join-Path $TEST_DIR "$projectName\bin\Release\$projectName.dll" -Resolve

    & $xunit $asm | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting ""$platform""."
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
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $noRestore,
        [switch] $noBuild
    )

    if (($platform -eq "net45") -or ($platform -eq "net451")) {
        # "net45" and "net451" must be handled separately.
        Invoke-TestOldStyle -Platform $platform -Version $version -Runtime $runtime
        return
    }

    $runtimeStr = Get-RuntimeString $runtime
    Chirp "Testing the package v$version for ""$platform"" $runtimeStr."

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }
    if ($noBuild)       { $args += "--no-build" }   # NB: no-build => no-restore
    elseif ($noRestore) { $args += "--no-restore" }

    & dotnet test $NET_SDK_PROJECT -f $platform $args `
        /p:AbcVersion=$version /p:AllKnown=true --nologo `
        | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting ""$platform""."
}

# ------------------------------------------------------------------------------

# Interactive mode.
function Invoke-TestMany {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]] $platformList,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $noRestore,
        [switch] $noBuild
    )

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }

    foreach ($platform in $platformList) {
        if (Confirm-Yes "Test the package for ""$platform""?") {
            Invoke-TestSingle `
                -Platform $platform `
                -Version $version `
                -Runtime $runtime `
                -NoRestore:$noRestore.IsPresent `
                -NoBuild:$noBuild.IsPresent
        }
    }
}

# ------------------------------------------------------------------------------

function Invoke-TestAll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $allKnown,
        [switch] $noClassic,
        [switch] $noCore
    )

    $runtimeStr = Get-RuntimeString $runtime
    Chirp "Batch testing the package v$version for" -NoNewline
    # Platform set.
    if ($noClassic)  { Chirp " .NET Core"  -NoNewline }
    elseif ($noCore) { Chirp " .NET Framework"  -NoNewline }
    else             { Chirp " .NET Framework and .NET Core"  -NoNewline }
    # Versions.
    if ($allKnown)      { Chirp ", ALL versions"  -NoNewline }
    elseif ($noClassic) { Chirp ", LTS versions"  -NoNewline }
    elseif ($noCore)    { Chirp ", last minor version of each major version"  -NoNewline }
    else                { Chirp ", selected versions"  -NoNewline }
    # Runtime.
    Chirp " $runtimeStr."

    $args = @()

    if ($allKnown)       { $args += "/p:AllKnown=true" }
    if ($noClassic)      { $args += "/p:NoClassic=true" }
    if ($noCore)         { $args += "/p:NoCore=true" }
    if ($runtime -ne "") { $args += "--runtime:$runtime" }

    & dotnet test $NET_SDK_PROJECT --nologo $args /p:AbcVersion=$version | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed."

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

# ------------------------------------------------------------------------------

# Last minor version of each major version or all versions.
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
    Approve-RepositoryRoot

    pushd $TEST_DIR

    if ($Clean) {
        # Cleaning the "src" directory is only necessary when there are "dangling"
        # cs files in "src" that were created during a previous build. Now, it's
        # no longer a problem (we explicitely exclude "bin" and "obj" in
        # "test\Directory.Build.targets"), but we never know.
        Reset-SourceTree -Yes:$Yes.IsPresent
        Reset-TestTree   -Yes:$Yes.IsPresent
    }

    if ($Version -eq "") {
        # There were two options, use an explicit version or let the target
        # project decides for us. Both give the __same__ value, but I opted for
        # an explicit version, since I need its value for logging but also
        # because it is safer to do so (see the dicussion on "restore/build traps"
        # in "test\README").
        $Version = Get-PackageVersion "Abc.Maybe" -AsString
    }

    if ($Platform -eq "") {
        if ($NoClassic -and $NoCore) {
            Croak "You set both -NoClassic and -NoCore... There is nothing left to be done."
        }

        if ($Yes -or (Confirm-Yes "Test the package for all selected platforms at once (SLOW)?")) {
            Invoke-TestAll `
                -Version $Version `
                -Runtime $Runtime `
                -AllKnown:$AllKnown.IsPresent `
                -NoClassic:$NoClassic.IsPresent `
                -NoCore:$NoCore.IsPresent
        }
        else {
            # Building or restoring the solution only once should speed up things a bit.
            if ($NoSpeedUp) {
                $noBuild   = $true
                $noRestore = $false

                Invoke-Restore -Version $Version -Runtime $Runtime -AllKnown:$AllKnown.IsPresent
            }
            else {
                $noBuild   = $false
                $noRestore = $true

                Invoke-Build -Version $Version -Runtime $Runtime -AllKnown:$AllKnown.IsPresent
            }

            Chirp "Now, you will have the opportunity to choose which platform to test the package for."

            if (-not $NoClassic) {
                if ($AllKnown) { $platformList = $AllClassic }
                else { $platformList = $LastClassic }

                Invoke-TestMany -PlatformList $platformList `
                    -Version $Version -Runtime $Runtime `
                    -NoBuild:$noBuild -NoRestore:$noRestore
            }

            if (-not $NoCore) {
                if ($AllKnown) { $platformList = $AllCore }
                else { $platformList = $LTSCore }

                Invoke-TestMany -PlatformList $platformList `
                    -Version $Version -Runtime $Runtime `
                    -NoBuild:$noBuild -NoRestore:$noRestore
            }
        }
    }
    else {
        Invoke-TestSingle -Platform $Platform -Version $Version -Runtime $Runtime
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
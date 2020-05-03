#Requires -Version 4.0

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
When no version is specified, we use the one from the last public release.

.PARAMETER Runtime
The target runtime to test the package for.
If the runtime is not known, the script will fail silently, and if it is not
supported the script will abort.
Ignored by platforms "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER AllKnown
Test the package for ALL known platform versions (SLOW).
Ignored if -Platform is also specified.

.PARAMETER NoClassic
Exclude .NET Framework from the tests.
Ignored if -Platform is also specified.

.PARAMETER NoCore
Exclude .NET Core from the tests.
Ignored if -Platform is also specified.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Clean
Hard clean the solution before creating the package by removing the "bin" and
"obj" directories within "src".
It's necessary when there are "dangling" cs files created during a previous
build. Now, it's no longer a problem (we explicitely exclude "bin" and "obj" in
Directory.Build.targets), but we never know.

.EXAMPLE
PS>test-package.ps1
Test the package for selected versions of .NET Core and .NET Framework

.EXAMPLE
PS>test-package.ps1 -NoClassic
Test the package for the LTS versions of .NET Core.

.EXAMPLE
PS>test-package.ps1 -NoCore
Test the package for the last minor version of each major version of .NET Framework.

.EXAMPLE
PS>test-package.ps1 -AllKnown
Test the package for ALL versions of .NET Core and .NET Framework.

.EXAMPLE
PS>test-package.ps1 -AllKnown -NoClassic
Test the package for ALL versions of .NET Core.

.EXAMPLE
PS>test-package.ps1 -AllKnown -NoCore
Test the package for ALL versions of .NET Framework.

.EXAMPLE
PS>test-package.ps1 net452 -Runtime win10-x64
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
    [Alias("y")] [switch] $Yes,
    [Alias("c")] [switch] $Clean,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

################################################################################

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
  -y|-Yes         do not ask for confirmation before running any test.
  -c|-Clean       hard clean the solution before anything else.
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
        Croak "Couldn't find Xunit Console Runner v$version where I expected it to be."
    }

    $path
}

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

    $proj = $platform.ToUpper()

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild $proj -v:minimal /p:AbcVersion=$version /t:"Restore;Build" | Out-Host
    Assert-CmdSuccess -ErrMessage "Build task failed when targeting ""$platform""."

    & $xunit .\$proj\bin\Release\$proj.dll | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting ""$platform""."
}

function Invoke-TestSingle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $platform,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $noRestore
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
    if ($noRestore) { $args += "--no-restore" }

    & dotnet test NETSdk -f $platform $args `
        /p:AbcVersion=$version /p:AllKnown=true --nologo `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed when targeting ""$platform""."
}

# Interactive mode.
function Invoke-TestMany {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]] $platforms,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version = "",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    if ($runtime -eq "") {
        $args = @()
    }
    else {
        $args = @("--runtime:$runtime")
    }

    Say "Restoring dependencies, please wait..."
    & dotnet restore NETSdk $args /p:AbcVersion=$version /p:AllKnown=true | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed when trying to restore the dependencies."

    foreach ($item in $platforms) {
        if (Confirm-Yes "Test the package for ""$item""?") {
            Invoke-TestSingle -Platform $item -Version $version -Runtime $runtime -NoRestore
        }
    }
}

function Invoke-TestAll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
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
    if ($noCore)         { $args += "/p:NoCore=true" }
    if ($noClassic)      { $args += "/p:NoClassic=true" }
    if ($runtime -ne "") { $args += "--runtime:$runtime" }

    & dotnet test NETSdk --nologo $args /p:AbcVersion=$version | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed."

    if ($allKnown -and (-not $noClassic)) {
        # "net45" and "net451" must be handled separately.
        Invoke-TestOldStyle -Platform "net45" -Version $version -Runtime $runtime
        Invoke-TestOldStyle -Platform "net451" -Version $version -Runtime $runtime
    }
}

################################################################################

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

$LTSCore =`
    "netcoreapp2.1",
    "netcoreapp3.1"
$AllCore =`
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
        if (Confirm-Yes "Hard clean the directories ""src""?") {
            Say-Indent "Deleting ""bin"" and ""obj"" directories within ""src""."

            Remove-BinAndObj $SRC_DIR
        }
    }

    if ($Version -eq "") {
        $Version = Get-PackageVersion "Abc.Maybe" -AsString
    }

    if ($Platform -eq "") {
        if ($noClassic -and $noCore) {
            Carp "You specified both -NoClassic and -NoCore... There is nothing left to be done."
            exit 0
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
            Chirp "Now you will have the opportunity to choose which platform to test the package for."

            if (-not $NoClassic) {
                if ($AllKnown) { $platforms = $AllClassic }
                else { $platforms = $LastClassic }

                Invoke-TestMany -Platforms $platforms -Version $Version -Runtime $runtime
            }

            if (-not $NoCore) {
                if ($AllKnown) { $platforms = $AllCore }
                else { $platforms = $LTSCore }

                Invoke-TestMany -Platforms $platforms -Version $Version -Runtime $runtime
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

################################################################################
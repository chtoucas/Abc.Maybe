#Requires -Version 4.0

<#
.SYNOPSIS
Test harness for net(4,5,6,7,8)x and netcoreapp(2,3).x.
Matching .NET Framework Developer Packs or Targeting Packs must be installed locally.

.PARAMETER Framework
Specify a single framework to be tested.

.PARAMETER Runtime
The target runtime to test for.
Ignored by targets "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER Max
Test ALL frameworks (SLOW), not just the last major versions.
Ignored if -Framework is also specified.
Ignored if you answer "no" when asked to confirm to test all platforms.

.PARAMETER ClassicOnly
When Max is also specified, only test for .NET Framework.
Ignored if -Framework is also specified.

.PARAMETER CoreOnly
When Max is also specified, only test for .NET Core.
Ignored if -Framework is also specified.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Safe
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories.
It's necessary when there are "dangling" cs files created during a previous
build. Now, it's no longer a problem (we explicitely exclude 'bin' and 'obj' in
Directory.Build.targets), but we never know.

.EXAMPLE
PS>post-check.ps1 -Framework netcoreapp2.2
Test harness for a specific version.

.EXAMPLE
PS>post-check.ps1 net452
Test harness for a specific version (-Framework is not mandatory).

.EXAMPLE
PS>post-check.ps1 -y
Test harness for ALL major versions; do NOT ask for confirmation.

.EXAMPLE
PS>post-check.ps1 -Max
Test harness for ALL versions, minor ones too.

.EXAMPLE
PS>post-check.ps1 -Max -ClassicOnly
Test harness for ALL .NET Framework versions, minor ones too.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string] $Framework = "*",

    [Parameter(Mandatory = $false, Position = 1)]
    [string] $Runtime = "",

                 [switch] $Max,
                 [switch] $ClassicOnly,
                 [switch] $CoreOnly,
    [Alias("y")] [switch] $Yes,
    [Alias("c")] [switch] $Safe,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

################################################################################

function Write-Usage {
    Say @"

Test harness for Abc.Maybe

Usage: pack.ps1 [switches].
    |-Framework     specify a single framework to be tested.
    |-Runtime       specifiy a target runtime to test for.
    |-Max           test ALL frameworks (SLOW), not just the last major versions.
    |-ClassicOnly   when Max is also specified, only test for .NET Framework.
    |-CoreOnly      when Max is also specified, only test for .NET Core.
  -y|-Yes           do not ask for confirmation before running any test harness.
  -s|-Safe          hard clean the solution before anything else.
  -h|-Help          print this help and exit.

"@
}

################################################################################

# .NET Framework 4.5/4.5.1 must be handled separately.
# Since it's no longer officialy supported by Microsoft, we can remove them
# if it ever becomes too much of a burden.

# & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -?
# https://aka.ms/vs/workloads for a list of workload (-requires)
function Find-VsWhere {
    Write-Verbose "Finding the vswhere command."

    $vswhere = Get-Command "vswhere.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($vswhere -ne $null) {
        return $vswhere.Path
    }

    $path = "${ENV:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $path) {
        return $path
    }
    else {
        Croak "Could not find vswhere."
    }
}

function Find-MSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $vswhere
    )

    $exe = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1

    if (-not $exe) {
        Croak "Could not find MSBuild."
    }

    $exe
}

function Find-XunitRunner {
    $version = "2.4.1"
    $framework = "net452"

    $exe = Join-Path $env:USERPROFILE `
        ".nuget\packages\xunit.runner.console\$version\tools\$framework\xunit.console.exe"

    if (-not (Test-Path $exe)) {
        Croak "Couldn't find Xunit Console Runner v$version where I expected it to be."
    }

    $exe
}

################################################################################

function Invoke-TestOldStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $framework
    )

    SAY-LOUD "Testing ($framework)."

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere
    $xunit   = Find-XunitRunner

    $proj = $framework.ToUpper()

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild .\$proj\$proj.csproj -v:minimal /t:"Restore;Build"
    Assert-CmdSuccess -ErrMessage "Build task failed when targeting $framework."

    & $xunit .\$proj\bin\Release\$proj.dll
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting $framework."
}

function Invoke-Test {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $framework,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $runtime
    )

    SAY-LOUD "Testing ($framework)."

    if ($runtime) {
        $arg = "--runtime:$runtime"
    }
    else {
        $arg = ""
    }

    & dotnet test .\NETSdk\NETSdk.csproj -f $framework $arg /p:__Max=true
    #& dotnet test .\NETSdk\NETSdk.csproj $arg /p:TargetFramework=$framework /p:__Max=true

    Assert-CmdSuccess -ErrMessage "Test task failed when targeting $framework."
}

# Interactive mode, last major versions only.
function Invoke-TestMajor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $runtime,

        [switch] $ClassicOnly,
        [switch] $CoreOnly
    )

    if ($runtime) {
        $arg = "--runtime:$runtime"
    }
    else {
        $arg = ""
    }

    if (-not $CoreOnly) {
        foreach ($fmk in $MajorClassic) {
            if ($Yes -or (Confirm-Yes "Test harness for ${fmk}?")) {
                Invoke-Test $fmk -Runtime $runtime
            }
        }
    }
    if (-not $ClassicOnly) {
        foreach ($fmk in $MajorCore) {
            if ($Yes -or (Confirm-Yes "Test harness for ${fmk}?")) {
                Invoke-Test $fmk -Runtime $runtime
            }
        }
    }
}

function Invoke-TestAll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $runtime,

        [switch] $Max,
        [switch] $ClassicOnly,
        [switch] $CoreOnly
    )

    SAY-LOUD "Testing for all platforms."

    if ($runtime) {
        $arg = "--runtime:$runtime"
    }
    else {
        $arg = ""
    }

    if ($Max) { $__max = "true" } else { $__max = "false" }
    if ($ClassicOnly) { $__classicOnly = "true" } else { $__classicOnly = "false" }
    if ($CoreOnly) { $__coreOnly = "true" } else { $__coreOnly = "false" }

    & dotnet test .\NETSdk\NETSdk.csproj $arg `
        /p:__Max=$__max `
        /p:__ClassicOnly=$__classicOnly `
        /p:__CoreOnly=$__coreOnly

    Assert-CmdSuccess -ErrMessage "Test ALL task failed."

    if ($Max -and (-not $CoreOnly)) {
        Invoke-TestOldStyle "net45"
        Invoke-TestOldStyle "net451"
    }
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

# Last major versions only
$MajorClassic = `
    "net452",
    "net462",
    "net472",
    "net48"
$MajorCore = `
    "netcoreapp2.2",
    "netcoreapp3.1"

try {
    Approve-RepositoryRoot

    $testdir = Join-Path $ROOT_DIR "test" -Resolve

    pushd $testdir

    if ($Safe) {
        if (Confirm-Yes "Hard clean?") {
            Say "  Deleting 'bin' and 'obj' directories."

            Remove-BinAndObj $testdir
        }
    }

    Carp "Will fail (MSB3644) if a required .NET SDK Kit is not installed locally."

    if ($Framework -eq "*") {
        if ($Yes -or (Confirm-Yes "Test all platforms at once (SLOW)?")) {
            Invoke-TestAll `
                -Runtime $Runtime `
                -Max:$Max.IsPresent `
                -CoreOnly:$CoreOnly.IsPresent `
                -ClassicOnly:$ClassicOnly.IsPresent
        }
        else {
            Invoke-TestMajor `
                -Runtime $Runtime `
                -CoreOnly:$CoreOnly.IsPresent `
                -ClassicOnly:$ClassicOnly.IsPresent
        }
    }
    else {
        if ($Framework -eq "net45") {
            Invoke-TestOldStyle "net45"
        }
        elseif ($Framework -eq "net451") {
            Invoke-TestOldStyle "net451"
        }
        else {
            Invoke-Test $Framework -Runtime $Runtime
        }
    }
}
catch {
    Croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
        -StackTrace $_.ScriptStackTrace
}
finally {
    popd
}

################################################################################
#Requires -Version 4.0

<#
.SYNOPSIS
Test harness for net(4,5,6,7,8)x and netcoreapp(2,3).x.
WARNING: the matching SDK must be installed locally.

.PARAMETER Target
Specify a single platform to be tested.

.PARAMETER Deep
Test ALL frameworks (SLOW), not just the last major versions.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Safe
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories.
It's necessary when there are "dangling" cs files created during a previous
build. Now, it's no longer a problem (we explicitely exclude 'bin' and 'obj' in
Directory.Build.targets), but we never know.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string] $Target = "*",

    [Alias("d")] [switch] $Deep,
    [Alias("y")] [switch] $Yes,
    [Alias("c")] [switch] $Safe,
    [Alias("h")] [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "abc.ps1")

New-Variable -Name "CONFIGURATION" -Value "Release" -Scope Script -Option Constant

################################################################################

function Write-Usage {
    Say @"

Test harness for Abc.Maybe

Usage: pack.ps1 [switches].
  -t|-Target   specify a single platform to be tested.
  -d|-Deep     test ALL frameworks (SLOW), not just the last major versions.
  -y|-Yes      do not ask for confirmation before running any test harness.
  -s|-Safe     hard clean the solution before anything else.
  -h|-Help     print this help and exit.

"@
}

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

# .NET Framework 4.5 must handled separately.
# Since it's no longer officialy supported by Microsoft, we can remove it
# if it ever becomes too much of a burden.
function Invoke-TestNET45 {
    SAY-LOUD "Testing (net45)."

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere
    $xunit   = Find-XunitRunner

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild .\NET45\NET45.csproj -v:minimal /t:"Restore;Build" -property:Configuration=$CONFIGURATION
    Assert-CmdSuccess -ErrMessage "Build task failed when targeting net45."

    & $xunit .\NET45\bin\$CONFIGURATION\NET45.dll
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting net45."
}

function Invoke-Test {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $framework
    )

    SAY-LOUD "Testing ($framework)."

    & dotnet test .\NETSdk\NETSdk.csproj -c $CONFIGURATION -f $framework /p:__Deep=true
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting $framework."
}

function Invoke-TestAll {
    [CmdletBinding()]
    param(
        [switch] $Deep
    )

    SAY-LOUD "Testing for all platforms."

    if ($Deep) {
        & dotnet test .\NETSdk\NETSdk.csproj -c $CONFIGURATION /p:__Deep=true
    }
    else {
        & dotnet test .\NETSdk\NETSdk.csproj -c $CONFIGURATION
    }

    Assert-CmdSuccess -ErrMessage "Test task failed."
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

try {
    Approve-RepositoryRoot

    pushd (Join-Path $ROOT_DIR "src\integration")

    if ($Safe) {
        if (Confirm-Yes "Hard clean?") {
            Say "  Deleting 'bin' and 'obj' directories."

            Remove-BinAndObj $SRC_DIR
        }
    }

    if ($Target -eq "*") {
        if ($Yes -or (Confirm-Yes "Test all platforms at once (SLOW)?")) {
            Carp "May fail if the matching SDK is not installed locally."
            if ($Deep) {
                Carp "Targets currently disabled (because I don't have them): net47, net471 and net48."
            }
            Invoke-TestAll -Deep:$Deep.IsPresent
            if ($Deep) {
                Invoke-TestNET45
            }
        }
        else {
            # Last major versions only.
            $frameworks = `
                "net452",
                "net462",
                "net472",
                "netcoreapp2.2",
                "netcoreapp3.1"

            foreach ($framework in $frameworks) {
                if ($Yes -or (Confirm-Yes "Test harness for ${framework}?")) {
                    Invoke-Test $framework
                }
            }
        }
    }
    else {
        if ($Target -eq "net45") {
            Invoke-TestNET45
        }
        else {
            Invoke-Test $Target
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
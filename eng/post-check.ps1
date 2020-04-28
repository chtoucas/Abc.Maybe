#Requires -Version 4.0

<#
.SYNOPSIS
Test harness for net45, netcoreapp2.x and netcoreapp3.0.

.PARAMETER Force
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
    [Alias("f")] [switch] $Force,
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
  -f|-Force    do not ask for confirmation before running any test harness.
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

function Test-NetCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $version
    )

    $proj = $version.Replace(".", "_").ToUpper()

    SAY-LOUD "Testing ($version)."

    & dotnet test .\$proj\ -c $CONFIGURATION
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting netcoreapp2.0."
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

try {
    Approve-RepositoryRoot

    pushd (Join-Path $ROOT_DIR "src\integration")

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere
    $xunit   = Find-XunitRunner

    if ($Safe) {
        if (Confirm-Yes "Hard clean?") {
            Say "  Deleting 'bin' and 'obj' directories."

            Remove-BinAndObj $SRC_DIR
        }
    }

    if ($Force -or (Confirm-Yes "Test harness for net45?")) {
        SAY-LOUD "Testing (net45)."

        # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
        & $msbuild .\NET45\NET45.csproj -v:minimal /t:"Restore;Build" -property:Configuration=$CONFIGURATION
        Assert-CmdSuccess -ErrMessage "Build task failed when targeting net45."

        & $xunit .\NET45\bin\$CONFIGURATION\NET45.dll
        Assert-CmdSuccess -ErrMessage "Test task failed when targeting net45."
    }

    if ($Force -or (Confirm-Yes "Test harness for netcoreapp2.0?")) {
        Test-NetCore "netcoreapp2.0"
    }

    if ($Force -or (Confirm-Yes "Test harness for netcoreapp2.1?")) {
        Test-NetCore "netcoreapp2.1"
    }

    if ($Force -or (Confirm-Yes "Test harness for netcoreapp2.2?")) {
        Test-NetCore "netcoreapp2.2"
    }

    if ($Force -or (Confirm-Yes "Test harness for netcoreapp3.0?")) {
        Test-NetCore "netcoreapp3.0"
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
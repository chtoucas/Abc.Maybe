#Requires -Version 4.0

<#
.SYNOPSIS
Test harness for net(4,5,6,7,8)x and netcoreapp(2,3).x.
WARNING: the matching SDK must be installed locally.

.PARAMETER Target
Specify a single platform to be tested.

.PARAMETER Max
Test ALL frameworks (SLOW), not just the last major versions.
Ignored if -Target is also specified.
Ignored if you answer "no" when asked to confirm.

.PARAMETER ClassicOnly
When Max is also specified, only test for .NET Framework.
Ignored if -Target is also specified.
Ignored if you answer "no" when asked to confirm.

.PARAMETER CoreOnly
When Max is also specified, only test for .NET Core.
Ignored if -Target is also specified.
Ignored if you answer "no" when asked to confirm.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Safe
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories.
It's necessary when there are "dangling" cs files created during a previous
build. Now, it's no longer a problem (we explicitely exclude 'bin' and 'obj' in
Directory.Build.targets), but we never know.

.EXAMPLE
PS>post-check.ps1 -t netcoreapp2.2
Test harness for a specific version.

.EXAMPLE
PS>post-check.ps1 net452
Test harness for a specific version (-t is not mandatory).

.EXAMPLE
PS>post-check.ps1
Test harness for ALL major versions.

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
    [string] $Target = "*",

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
  -t|-Target        specify a single target to be tested.
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

# Minimum version.
# .NET Framework 4.5 	  378389
# .NET Framework 4.5.1 	378675
# .NET Framework 4.5.2 	379893
# .NET Framework 4.6 	  393295
# .NET Framework 4.6.1 	394254
# .NET Framework 4.6.2 	394802
# .NET Framework 4.7 	  460798
# .NET Framework 4.7.1 	461308
# .NET Framework 4.7.2 	461808
# .NET Framework 4.8 	  528040
# (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 394802
# https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
function Find-LatestVisualStudio {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string] $vswhere
    )

    $path = & $vswhere -latest -property installationPath

    if (-not $path) {
        Croak "Could not find Visual Studio."
    }

    $path
}

################################################################################

function Invoke-TestLegacy {
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
        [string] $framework
    )

    SAY-LOUD "Testing ($framework)."

    & dotnet test .\NETSdk\NETSdk.csproj -f $framework /p:__Max=true
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting $framework."
}

function Invoke-TestAll {
    [CmdletBinding()]
    param(
        [switch] $Max,
        [switch] $ClassicOnly,
        [switch] $CoreOnly
    )

    SAY-LOUD "Testing for all platforms."

    if ($Max) { $__max = "true" } else { $__max = "false" }
    if ($ClassicOnly) { $__classicOnly = "true" } else { $__classicOnly = "false" }
    if ($CoreOnly) { $__coreOnly = "true" } else { $__coreOnly = "false" }

    & dotnet test .\NETSdk\NETSdk.csproj `
        /p:__Max=$__max `
        /p:__ClassicOnly=$__classicOnly `
        /p:__CoreOnly=$__coreOnly

    Assert-CmdSuccess -ErrMessage "Test task failed."
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

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

    if ($Target -eq "*") {
        if ($Yes -or (Confirm-Yes "Test all platforms at once (SLOW)?")) {
            Carp "Will fail (MSB3644) if a required .NET SDK Kit is not installed locally."

            if ($Max -and (-not $CoreOnly)) {
                Carp "Targets currently disabled (I didn't install them): net47, net471 and net48."
            }

            Invoke-TestAll `
                -Max:$Max.IsPresent `
                -CoreOnly:$CoreOnly.IsPresent `
                -ClassicOnly:$ClassicOnly.IsPresent

            if ($Max -and (-not $CoreOnly)) {
                Invoke-TestLegacy "net45"
                Invoke-TestLegacy "net451"
            }
        }
        else {
            Carp "Will fail silently if a required .NET SDK is not installed locally."

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
        Carp "Will fail silently if a required .NET SDK is not installed locally."

        if ($Target -eq "net45") {
            Invoke-TestLegacy "net45"
        }
        elseif ($Target -eq "net451") {
            Invoke-TestLegacy "net451"
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
#Requires -Version 4.0

<#
.SYNOPSIS
Test harness for net(4,5,6,7,8)x and netcoreapp(2,3).x.
Matching .NET Framework Developer Packs or Targeting Packs must be installed
locally. The script will fail with error MSB3644 if it is not the case.

.PARAMETER Framework
Specify a single framework to be tested.

.PARAMETER Runtime
The target runtime to test for.
Ignored by targets "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER AllVersions
Test with ALL frameworks (SLOW), not just the last minor version of each major version.
Ignored if -Framework is also specified.
Ignored if you answer "no" when asked to confirm to test all platforms.

.PARAMETER Classic
Test with .NET Framework, all or just the last minor version of each major version.
What it does really mean is "I don't want include .NET Core this time".
When specified, .NET Core targets are ignored unless -Core is also specified.
Ignored if -Framework is also specified.

.PARAMETER Core
Test with .NET Core, all or just the last minor version of each major version.
What it does really mean is "I don't want to include .NET Framework this time".
When specified, .NET Framework targets are ignored unless -Classic is also specified.
Ignored if -Framework is also specified.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Clean
Hard clean the solution before creating the package by removing the 'bin' and
'obj' directories.
It's necessary when there are "dangling" cs files created during a previous
build. Now, it's no longer a problem (we explicitely exclude 'bin' and 'obj' in
Directory.Build.targets), but we never know.

.EXAMPLE
PS>test-package.ps1 -Framework netcoreapp2.2
Test harness for a specific version.

.EXAMPLE
PS>test-package.ps1 net452
Test harness for a specific version (-Framework is not mandatory).

.EXAMPLE
PS>test-package.ps1 -y
Test harness for ALL major versions; do NOT ask for confirmation.

.EXAMPLE
PS>test-package.ps1 -AllVersions
Test harness for ALL versions, minor ones too.

.EXAMPLE
PS>test-package.ps1 -AllVersions -Classic
Test harness for ALL .NET Framework versions, minor ones too.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias("f")] [string] $Framework = "*",

    [Parameter(Mandatory = $false, Position = 1)]
    [Alias("r")] [string] $Runtime = "",

    [Parameter(Mandatory = $false, Position = 2)]
    [string] $Version = "",

    [Alias("a")] [switch] $AllVersions,
                 [switch] $Classic,
                 [switch] $Core,
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

Test harness for Abc.Maybe

Usage: pack.ps1 [switches].
  -f|-Framework     specify a single framework to be tested.
  -r|-Runtime       specifiy a target runtime to test for.
  -a|-AllVersions   test with ALL framework versions (SLOW), not just the last minor version of each major version.
    |-Classic       test with .NET Framework, all -or- just the minor version of each major version.
    |-Core          test with .NET Core, all -or- just the minor version of each major version.
  -y|-Yes           do not ask for confirmation before running any test harness.
  -c|-Clean         hard clean the solution before anything else.
  -h|-Help          print this help and exit.

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
    $framework = "net452"

    $path = Join-Path ${ENV:USERPROFILE} `
        ".nuget\packages\xunit.runner.console\$version\tools\$framework\xunit.console.exe"

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

    if ($runtime -eq "") { return "default" }
    $runtime
}

# ------------------------------------------------------------------------------

function Invoke-TestOldStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $framework
    )

    SAY-LOUD "Testing" -NoNewline
    Say " ($framework, runtime=default)."

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere
    $xunit   = Find-XunitRunner

    $proj = $framework.ToUpper()

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild .\$proj\$proj.csproj -v:minimal /t:"Restore;Build" | Out-Host
    Assert-CmdSuccess -ErrMessage "Build task failed when targeting '$framework'."

    & $xunit .\$proj\bin\Release\$proj.dll | Out-Host
    Assert-CmdSuccess -ErrMessage "Test task failed when targeting '$framework'."
}

function Invoke-TestSingle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $framework,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    SAY-LOUD "Testing" -NoNewline
    $runtimeStr = Get-RuntimeString $runtime
    Say " ($framework, runtime=$runtimeStr)."

    if ($runtime -ne "") {
        $args = @("--runtime:$runtime")
    }
    else {
        $args = @()
    }

    & dotnet test .\NETSdk\NETSdk.csproj -f $framework $args `
        /p:AllVersions=true --nologo -v q `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed when targeting '$framework'."
}

# Interactive mode.
function Invoke-TestMany {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $frameworks,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    foreach ($fmk in $frameworks) {
        if (Confirm-Yes "Test harness for '${fmk}'?") {
            Invoke-TestSingle $fmk -Runtime $runtime
        }
    }
}

function Invoke-TestBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $runtime = "",

        [switch] $allVersions,
        [switch] $classic,
        [switch] $core,
        [switch] $both
    )

    SAY-LOUD "Batch testing" -NoNewline
    Say " (" -NoNewline
    if ($both)        { Say "Classic+Core frameworks, "  -NoNewline }
    elseif ($classic) { Say "Classic frameworks, "  -NoNewline }
    else              { Say "Core frameworks, "  -NoNewline }
    if ($allVersions) { Say "all versions, "  -NoNewline }
    $runtimeStr = Get-RuntimeString $runtime
    Say "runtime=$runtimeStr)."

    $allVersions_ = "$allVersions".ToLower()
    $classicSet   = "$classic".ToLower()
    $coreSet      = "$core".ToLower()

    if ($runtime -ne "") {
        $args = @("--runtime:$runtime")
    }
    else {
        $args = @()
    }

    & dotnet test .\NETSdk\NETSdk.csproj --nologo -v q $args `
        /p:AllVersions=$allVersions_ `
        /p:ClassicSet=$classicSet `
        /p:CoreSet=$coreSet `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed."

    if ($allVersions -and (-not $coreOnly)) {
        Invoke-TestOldStyle "net45"
        Invoke-TestOldStyle "net451"
    }
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

# ------------------------------------------------------------------------------

# Last minor version of each major version.
$MajorClassics = `
    "net452",
    "net462",
    "net472",
    "net48"

$MajorCores =`
    "netcoreapp2.2",
    "netcoreapp3.1"

# ------------------------------------------------------------------------------

try {
    Approve-RepositoryRoot

    pushd $TEST_DIR

    if ($Clean) {
        if (Confirm-Yes "Hard clean the directory 'test'?") {
            Say-Indent "Deleting 'bin' and 'obj' directories within 'test'."

            Remove-BinAndObj $TEST_DIR
        }
    }

    if ($Framework -eq "*") {
        if (-not $Classic -and -not $Core) {
            $both = $true
            $Classic = $true
            $Core = $true
        }
        else {
            $both = $false
        }

        if ($Yes -or (Confirm-Yes "Test all platforms at once (SLOW)?")) {
            Invoke-TestBatch `
                -Runtime $Runtime `
                -AllVersions:$AllVersions.IsPresent `
                -Core:$Core.IsPresent `
                -Classic:$Classic.IsPresent `
                -Both:$both
        }
        else {
            Chirp "Now you will have the opportunity to test the last minor version of each major platform version."

            if ($both -or $Classic) {
                Invoke-TestMany $MajorClassics -Runtime $runtime
            }
            if ($both -or $Core) {
                Invoke-TestMany $MajorCores -Runtime $runtime
            }
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
            Invoke-TestSingle $Framework -Runtime $Runtime
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
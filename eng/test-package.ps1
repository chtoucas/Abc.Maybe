#Requires -Version 4.0

<#
.SYNOPSIS
Test the package for net(4,5,6,7,8)x and netcoreapp(2,3).x.
Matching .NET Framework Developer Packs or Targeting Packs must be installed
locally, the later should suffice. The script will fail with error MSB3644 when
it is not the case.

.PARAMETER Platform
Specify a single platform for which to test the package.

.PARAMETER Runtime
The target runtime to test the package for.
Ignored by targets "net45" or "net451".

For instance, runtime can be "win10-x64" or "win10-x86".
See https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

.PARAMETER AllVersions
Test the package for ALL platform versions (SLOW), not just the last minor
version of each major version.
Ignored if -Platform is also specified.
Ignored if you answer "no" when asked to confirm to test all selected platforms.

.PARAMETER Classic
Only test the package for .NET Framework.
Ignored if -Platform is also specified.

.PARAMETER Core
Only test the package for .NET Core.
Ignored if -Platform is also specified.

.PARAMETER Yes
Do not ask for confirmation.

.PARAMETER Clean
Hard clean the solution before creating the package by removing the "bin" and
"obj" directories.
It's necessary when there are "dangling" cs files created during a previous
build. Now, it's no longer a problem (we explicitely exclude "bin" and "obj" in
Directory.Build.targets), but we never know.

.EXAMPLE
PS>test-package.ps1
Test the package for the last minor version of each major version of .NET Core
and .NET Framework.

.EXAMPLE
PS>test-package.ps1 -AllVersions
Test the package for ALL versions of .NET Core and .NET Framework, minor ones too.

.EXAMPLE
PS>test-package.ps1 -AllVersions -Classic
Test the package for ALL versions of .NET Framework, minor ones too.

.EXAMPLE
PS>test-package.ps1 net452 -Runtime win10-x64
Test the package for a specific platform and for the runtime "win10-x64".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias("p")] [string] $Platform = "",

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

Test package Abc.Maybe

Usage: pack.ps1 [switches].
  -p|-Platform      specify a single platform for which to test the package.
  -r|-Runtime       specify a target runtime to test for.
  -a|-AllVersions   test the package for ALL platform versions (SLOW), not just the last minor version of each major version.
    |-Classic       only test the package for .NET Framework.
    |-Core          only test the package for .NET Core.
  -y|-Yes           do not ask for confirmation before running any test.
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

    if ($runtime -eq "") { return "default" }
    $runtime
}

# ------------------------------------------------------------------------------

function Invoke-TestOldStyle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $platform
    )

    Chirp "Testing the package for" -NoNewline
    Chirp " ""$platform"" (runtime = ""default"")."

    $vswhere = Find-VsWhere
    $msbuild = Find-MSBuild $vswhere
    $xunit   = Find-XunitRunner

    $proj = $platform.ToUpper()

    # https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019
    & $msbuild .\$proj\$proj.csproj -v:minimal /t:"Restore;Build" | Out-Host
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
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    Chirp "Testing the package for" -NoNewline
    $runtimeStr = Get-RuntimeString $runtime
    Chirp " ""$platform"" (runtime = ""$runtimeStr"")."

    if ($runtime -ne "") {
        $args = @("--runtime:$runtime")
    }
    else {
        $args = @()
    }

    & dotnet test .\NETSdk\NETSdk.csproj -f $platform $args `
        /p:AllVersions=true --nologo -v q `
        | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed when targeting ""$platform""."
}

# Interactive mode.
function Invoke-TestMany {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $platforms,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string] $runtime = ""
    )

    foreach ($item in $platforms) {
        if (Confirm-Yes "Test the package for ""$item""?") {
            Invoke-TestSingle -Platform $item -Runtime $runtime
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
        [switch] $core
    )

    Chirp "Batch testing the package for" -NoNewline
    if ($classic)  { Chirp " the .NET Framework"  -NoNewline }
    elseif ($core) { Chirp " the .NET Core"  -NoNewline }
    else           { Chirp " ALL platforms"  -NoNewline }
    if ($allVersions) { Chirp ", all versions"  -NoNewline }
    $runtimeStr = Get-RuntimeString $runtime
    Chirp " (runtime = ""$runtimeStr"")."

    $args = @()
    if ($allVersions)    { $args += "/p:AllVersions=true" }
    if ($core)           { $args += "/p:ClassicSet=false" }
    if ($classic)        { $args += "/p:CoreSet=false" }
    if ($runtime -ne "") { $args += "--runtime:$runtime" }

    & dotnet test .\NETSdk\NETSdk.csproj --nologo -v q $args | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed."

    if ($allVersions -and (-not $core)) {
        Invoke-TestOldStyle -Platform "net45"
        Invoke-TestOldStyle -Platform "net451"
    }
}

################################################################################

if ($Help) {
    Write-Usage
    exit 0
}

# ------------------------------------------------------------------------------

# Last minor version of each major version.
$LastMajorClassics = `
    "net452",
    "net462",
    "net472",
    "net48"

$LastMajorCores =`
    "netcoreapp2.2",
    "netcoreapp3.1"

# ------------------------------------------------------------------------------

try {
    Approve-RepositoryRoot

    pushd $TEST_DIR

    if ($Clean) {
        if (Confirm-Yes "Hard clean the directory ""test""?") {
            Say-Indent "Deleting ""bin"" and ""obj"" directories within ""test""."

            Remove-BinAndObj $TEST_DIR
        }
    }

    if ($Platform -eq "") {
        if ($Yes -or (Confirm-Yes "Test the package for all selected platforms at once (SLOW)?")) {
            Invoke-TestBatch `
                -Runtime $Runtime `
                -AllVersions:$AllVersions.IsPresent `
                -Core:$Core.IsPresent `
                -Classic:$Classic.IsPresent
        }
        else {
            Chirp "Now you will have the opportunity to choose which platform to test the package for."
            Chirp "NB: we only propose the last minor version of each major version."

            if (-not $Core) {
                Invoke-TestMany -Platforms $LastMajorClassics -Runtime $runtime
            }
            if (-not $Classic) {
                Invoke-TestMany -Platforms $LastMajorCores -Runtime $runtime
            }
        }
    }
    else {
        if ($Platform -eq "net45") {
            Invoke-TestOldStyle -Platform "net45"
        }
        elseif ($Platform -eq "net451") {
            Invoke-TestOldStyle -Platform "net451"
        }
        else {
            Invoke-TestSingle -Platform $Platform -Runtime $Runtime
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
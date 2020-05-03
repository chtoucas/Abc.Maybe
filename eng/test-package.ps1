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
Test the package for ALL platform versions (SLOW).
Ignored if -Platform is also specified.
See also -Classic and -Core.

.PARAMETER Classic
Only test the package for .NET Framework.
If -AllVersions is not specified too, only includes the last minor version of
each major version.
Ignored if -Platform is also specified.

.PARAMETER Core
Only test the package for .NET Core.
If -AllVersions is not specified too, only includes the LTS versions.
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
Test the package for selected versions of .NET Core and .NET Framework.

.EXAMPLE
PS>test-package.ps1 -Core
Test the package for the LTS versions of .NET Core.

.EXAMPLE
PS>test-package.ps1 -AllVersions
Test the package for ALL versions of .NET Core and .NET Framework.

.EXAMPLE
PS>test-package.ps1 -AllVersions -Classic
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
    [Alias("r")] [string] $Runtime = "",

    [Parameter(Mandatory = $false, Position = 2)]
    [Alias("v")] [string] $PackageVersion = "",

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
  -a|-AllVersions   test the package for ALL platform versions (SLOW).
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
    else           { Chirp " .NET Framework and .NET Core"  -NoNewline }
    if ($allVersions) { Chirp ", ALL versions"  -NoNewline }
    $runtimeStr = Get-RuntimeString $runtime
    Chirp " (runtime = ""$runtimeStr"")."

    $args = @()
    if ($allVersions)    { $args += "/p:AllVersions=true" }
    if ($core)           { $args += "/p:ClassicSet=false" }
    if ($classic)        { $args += "/p:CoreSet=false" }
    if ($runtime -ne "") { $args += "--runtime:$runtime" }

    & dotnet test .\NETSdk\NETSdk.csproj --nologo -v q $args | Out-Host

    Assert-CmdSuccess -ErrMessage "Test task failed."
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
# NB: "net45" and "net451" are handled separately.
$AllClassic = `
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

    if ($Platform -eq "") {
        if ($Yes -or (Confirm-Yes "Test the package for all selected platforms at once (SLOW)?")) {
            Invoke-TestBatch `
                -Runtime $Runtime `
                -AllVersions:$AllVersions.IsPresent `
                -Core:$Core.IsPresent `
                -Classic:$Classic.IsPresent

            $yestonet45x = $true
        }
        else {
            Chirp "Now you will have the opportunity to choose which platform to test the package for."

            if (-not $Core) {
                if ($AllVersions) { $platforms = $AllClassic }
                else { $platforms = $LastClassic }

                Invoke-TestMany -Platforms $platforms -Runtime $runtime
            }

            if (-not $Classic) {
                if ($AllVersions) { $platforms = $AllCore }
                else { $platforms = $LTSCore }

                Invoke-TestMany -Platforms $platforms -Runtime $runtime
            }

            $yestonet45x = $false
        }

        if ($AllVersions -and (-not $Core)) {
            if ($yestonet45x -or (Confirm-Yes "Test the package for ""net45""?")) {
                Invoke-TestOldStyle -Platform "net45"
            }
            if ($yestonet45x -or (Confirm-Yes "Test the package for ""net451""?")) {
                Invoke-TestOldStyle -Platform "net451"
            }
        }
    }
    else {
        if (($Platform -eq "net45") -or ($Platform -eq "net451")) {
            Invoke-TestOldStyle -Platform $Platform
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
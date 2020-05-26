# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Run the test suite for all supported platforms.

.PARAMETER Configuration
The configuration to test the project/solution for. Default = "Debug".

.PARAMETER Runtime
The runtime to test the project/solution for.

.PARAMETER Platform
The single platform to test the project/solution for.

.PARAMETER ListPlatforms
Print the list of supported platforms, then exit.

.PARAMETER NoRestore
Do not restore the project/solution.

#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration,

    [Parameter(Mandatory = $false)]
                 [string] $Runtime,

    [Parameter(Mandatory = $false)]
    [Alias("f")] [string] $Platform,
                 [switch] $ListPlatforms,

                 [switch] $NoRestore,
    [Alias("h")] [switch] $Help,

    [Parameter(Mandatory=$false, ValueFromRemainingArguments = $true)]
                 [string[]] $Properties
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

const TEST_PROJECT_NAME "Abc.Tests"
const TEST_PROJECT (Join-Path $SRC_DIR $TEST_PROJECT_NAME -Resolve)

#endregion
################################################################################
#region Helpers

function Print-Help {
    say @"

Run the test suite for all supported platforms.

Usage: reset.ps1 [arguments]
  -c|-Configuration     the configuration to test the project/solution for.
     -Runtime           the runtime to test the project/solution for.

  -f|-Platform          the platform to test the project/solution for.
     -ListPlatforms     print the list of supported platforms, then exit.

     -NoRestore         do not restore the project/solution.
  -h|-Help              print this help and exit.

Arguments starting with '/p:' are passed through to dotnet.exe.

"@
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Hello "this is the test script.`n"

try {
    ___BEGIN___

    $platforms = Get-TestPlatforms
    $minClassic, $maxClassic, $minCore, $maxCore  = Get-SupportedPlatforms
    $allPlatforms = $maxCore + $maxClassic

    if ($ListPlatforms) {
        say ("Default platform set:`n- {0}" -f ($platforms -join "`n- "))
        say ("`nSupported platforms (option -Platform):`n- {0}" -f ($allPlatforms -join "`n- "))
        exit
    }

    $args = @()
    if ($Configuration) { $args += "-c:$Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($NoRestore)     { $args += "--no-restore" }

    if ($Platform)  {
        if ($Platform -notin $allPlatforms) {
            die "The specified platform is not supported: ""$Platform""."
        }
        if ($Platform -eq "netcoreapp2.0") {
            # TODO: fails but works fine with test-package.ps1???
            #   "Unable to find "bin\Debug\netcoreapp2.0\testhost.dll".
            # Property IsTestProject? Microsoft.TestPlatform.TestHost?
            die """dotnet test"" refuses to run when targetting ""netcoreapp2.0"", don't know why."
        }

        $args += "/p:TargetFrameworks=$Platform", "/p:TargetFramework=$Platform"
        #$args += "-f:$Platform"
    }
    else {
        $args += '/p:TargetFrameworks=\"' + ($platforms -join ";") + '\"'
    }

    foreach ($arg in $Properties) {
        if ($arg.StartsWith("/p:", "InvariantCultureIgnoreCase")) {
            $args += $arg
        }
    }

    & dotnet test $TEST_PROJECT $args
        || die "Test task failed."
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

#endregion
################################################################################

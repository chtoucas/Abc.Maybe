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

.PARAMETER NoCheck
Do not check whether the specified platform is supported or not.

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
    [Alias("l")] [switch] $ListPlatforms,

                 [switch] $NoCheck,
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
  -l|-ListPlatforms     print the list of supported platforms, then exit.

     -NoCheck           do not check whether the specified platform is supported or not.
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
    $allPlatforms = ($maxCore + $maxClassic) | where { $_ -notin $OLDSTYLE_XUNIT_PLATFORMS }

    if ($ListPlatforms) {
        say ("Default platform set:`n- {0}" -f ($platforms -join "`n- "))
        say ("`nSupported platforms (option -Platform):`n- {0}" -f ($allPlatforms -join "`n- "))
        exit
    }

    $args = @()
    if ($Configuration) { $args += "-c:$Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($NoRestore)     { $args += "--no-restore" }

    # NB: may fail if the project references "Microsoft.NET.Test.Sdk".
    # Now, it should be OK as we only include it when running VS.
    #
    # We still cannot target UAP while multi-targeting at the same time.
    # It seems that it should be doable with .NET 5.
    # - https://github.com/novotnyllc/MSBuildSdkExtras
    # - https://github.com/dotnet/sdk/issues/491
    # - https://github.com/dotnet/sdk/issues/1408
    # - https://github.com/OPCFoundation/UA-.NETStandard/blob/c2ae8aac70b952d31bc5adaa5c4423ff63ebede6/SampleApplications/SDK/Opc.Ua.Server/Opc.Ua.Server.csproj
    if ($Platform)  {
        if (-not $NoCheck -and $Platform -notin $allPlatforms) {
            die "The specified platform is not supported: ""$Platform""."
        }

        $args += "/p:TargetFrameworks=$Platform"
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

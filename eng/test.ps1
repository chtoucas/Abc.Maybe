# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Run the test suite for all supported platforms.

.PARAMETER Configuration
The configuration to test the project/solution for. Default (implicit) = "Debug".

.PARAMETER Runtime
The runtime to test the project/solution for.

.PARAMETER Platform
The single platform to test the project/solution for.

.PARAMETER ListPlatforms
Print the list of supported platforms, then exit?

.PARAMETER NoAnalyzers
Turn off source code analysis?

.PARAMETER NoCheck
Do not check whether the specified platform is supported or not?

.PARAMETER NoRestore
Do not restore the project/solution?

.PARAMETER MyVerbose
Verbose mode? Print the settings in use before compiling each assembly.

.PARAMETER Help
Print help text then exit?
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

                 [switch] $NoAnalyzers,
                 [switch] $NoCheck,
                 [switch] $NoRestore,
    [Alias("v")] [switch] $MyVerbose,
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
  -c|-Configuration  the configuration to test the project/solution for.
     -Runtime        the runtime to test the project/solution for.

  -f|-Platform       the platform to test the project/solution for.
  -l|-ListPlatforms  print the list of supported platforms, then exit?

     -NoAnalyzers    turn off source code analysis?
     -NoCheck        do not check whether the specified platform is supported or not?
     -NoRestore      do not restore the project/solution?
  -v|-MyVerbose      display settings used to compile each DLL?
  -h|-Help           print this help and exit?

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
    if ($NoAnalyzers)   { $args += "/p:RunAnalyzers=false" }
    if ($MyVerbose)     { $args += "-v:minimal", "/p:PrintSettings=true" }

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

# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

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
#region Main.

try {
    ___BEGIN___

    $minClassic, $maxClassic, $minCore, $maxCore = Get-SupportedPlatforms
    $allPlatforms = $maxCore + $maxClassic

    if ($ListPlatforms) {
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

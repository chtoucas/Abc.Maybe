# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Wrapper for dotnet.exe.

.DESCRIPTION
Build the solution for all supported platforms.
To build a single project, specify its path via -ProjectPath.
NB: the list of supported platforms can NOT be overriden.

The default behaviour is to build libraries for all supported platforms, and to
build exe projects only for "DefaultPlatform".

To target a single platform, use -Platform (no "s").

Targetting a single platform or all supported platforms may "transform" an exe
project into a library.

.PARAMETER Task
The .NET command. Default = "build".

.PARAMETER ProjectPath
The project to build. Default = solution.

.PARAMETER Configuration
The configuration to build the project/solution for. Default (implicit) = "Debug".

.PARAMETER Runtime
The runtime to build the project/solution for.

.PARAMETER Platform
The single platform to build the project/solution for.

.PARAMETER ListPlatforms
Print the list of supported platforms, then exit?

.PARAMETER Force
Forces all dependencies to be resolved even if the last restore was successful?

.PARAMETER NoAnalyzers
Turn off source code analysis?

.PARAMETER NoCheck
Do not check whether the specified platform is supported or not?
Useful to test the solution for platforms listed in "NotSupportedTestPlatforms"
from D.B.props. Of course, as the name suggests, a succesful outcome is not
guaranteed, to say the least, it might not even run.

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
    [ValidateSet("build", "test")]
    [Alias("t")] [string] $Task = "build",

    [Parameter(Mandatory = $false)]
    [Alias("p")] [string] $ProjectPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration,

    [Parameter(Mandatory = $false)]
                 [string] $Runtime,

    [Parameter(Mandatory = $false)]
    [Alias("f")] [string] $Platform,
    [Alias("l")] [switch] $ListPlatforms,

                 [switch] $Force,
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

Build the solution for all supported platforms.

Usage: reset.ps1 [arguments]
  -t|-Task
  -p|-ProjectPath    the project to build.
  -c|-Configuration  the configuration to build the project/solution for.
     -Runtime        the runtime to build the project/solution for.

  -f|-Platform       the platform to build the project/solution for.
  -l|-ListPlatforms  print the list of supported platforms, then exit?

     -Force          forces all dependencies to be resolved even if the last restore was successful?
     -NoAnalyzers    turn off source code analysis?
     -NoCheck        do not check whether the specified platform is supported or not?
     -NoRestore      do not restore the project/solution?
  -v|-MyVerbose      display settings used to compile each DLL?
  -h|-Help           print this help and exit?

Arguments starting with '/p:' are passed through to dotnet.exe.
> make.ps1 /p:Retail=true
> make.ps1 /p:HideInternals=true
> make.ps1 /p:PatchEquality=true

Examples.
> make.ps1                                 #
> make.ps1 /p:Retail=true                  #
> make.ps1 -p src\Abc.Maybe -c Release     # "Release" build of Abc.Maybe

Looking for more help?
> Get-Help -Detailed make.ps1

"@
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Hello "this is the make script.`n"

try {
    ___BEGIN___

    $minClassic, $maxClassic, $minCore, $maxCore = Get-SupportedPlatforms
    $allPlatforms = $maxCore + $maxClassic

    if ($ListPlatforms) {
        say ("Supported platforms (option -Platform):`n- {0}" -f ($allPlatforms -join "`n- "))
        exit
    }

    if ($ProjectPath) {
        if (-not (Test-Path $ProjectPath)) {
            die "The specified project path doe not exist: ""$ProjectPath""."
        }
    }
    else {
        $ProjectPath = Join-Path $ROOT_DIR "Maybe.sln" -Resolve
    }

    # Common args available to all commands.
    $args = @()
    if ($Configuration) { $args += "-c:$Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($NoRestore)     { $args += "--no-restore" }
    if ($NoAnalyzers)   { $args += "/p:RunAnalyzers=false" }

    if ($Task -eq "build") {
        if ($MyVerbose) { $args += "/p:PrintSettings=true" }
        if ($Force)     { $args += "--force" }
    }
    elseif ($Task -eq "test") {
        if ($MyVerbose) { $args += "-v:minimal", "/p:PrintSettings=true" }
    }

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

    & dotnet $Task $ProjectPath $args
        || die "Task ""$Task"" failed."
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

#endregion
################################################################################

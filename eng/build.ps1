# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Build the solution for all supported platforms.

.DESCRIPTION
Build the solution for all supported platforms.
To build a single project, specify its path via -ProjectPath.
NB: the list of supported platforms can NOT be overriden.

The default behaviour is to build libraries for all supported platforms, and to
build exe projects only for "MaxPlatform".

To target a single platform, use -Platform (no "s").

Targetting a single platform or all supported platforms may "transform" an exe
project into a library.

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
Useful to build the project/solution for platforms listed in
"NotSupportedTestPlatforms" from D.B.props.

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

#endregion
################################################################################
#region Helpers

function Print-Help {
    say @"

Build the solution for all supported platforms.

Usage: reset.ps1 [arguments]
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
> build.ps1 /p:Retail=true
> build.ps1 /p:HideInternals=true
> build.ps1 /p:PatchEquality=true

Examples.
> build.ps1                                 #
> build.ps1 -a /p:Retail=true               #
> build.ps1 -p src\Abc.Maybe -c Release     # "Release" build of Abc.Maybe

Looking for more help?
> Get-Help -Detailed build.ps1

"@
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Hello "this is the build script.`n"

try {
    ___BEGIN___

    $platforms = Get-BuildPlatforms
    $minClassic, $maxClassic, $minCore, $maxCore = Get-SupportedPlatforms
    $allPlatforms = $maxCore + $maxClassic

    if ($ListPlatforms) {
        say ("Default platform set:`n- {0}" -f ($platforms -join "`n- "))
        say ("`nSupported platforms (option -Platform):`n- {0}" -f ($allPlatforms -join "`n- "))
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

    $args = @()
    if ($Configuration) { $args += "-c:$Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($Force)         { $args += "--force" }
    if ($NoRestore)     { $args += "--no-restore" }
    if ($NoAnalyzers)   { $args += "/p:RunAnalyzers=false" }
    if ($MyVerbose)     { $args += "/p:PrintSettings=true" }

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

    # Do not invoke "dotnet restore" before, it will fail w/ -Platform.
    & dotnet build $ProjectPath $args
        || die "Build task failed."
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

#endregion
################################################################################

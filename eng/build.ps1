# See LICENSE in the project root for license information.

################################################################################
#region Preamble.

<#
.SYNOPSIS
Build the solution for all supported platforms.

.DESCRIPTION
Build the solution for all supported platforms.
To build a single project, specify its path via -ProjectPath.

The default behaviour is to build libraries for all supported platforms, and to
build exe projects only for "MaxApiPlatform".

To build ALL projects (exe projects included) for ALL supported platforms,
use -AllPlatforms. NB: the list of supported platforms can NOT be overriden.

To target a single platform, use -TargetPlatform (no "s").

Targetting a single platform or all supported platforms maye "transform" an exe
project into a library.

.PARAMETER ProjectPath
The project to build. Default = solution.

.PARAMETER Configuration
The configuration to build the project/solution for. Default = "Debug".

.PARAMETER Runtime
The runtime to build the project/solution for.

.PARAMETER TargetPlatform
The platform to build the project/solution for.
Ignored if -AllPlatforms is also set and equals $true.

.PARAMETER AllPlatforms
Build the project/solution (exe projects included) for ALL supported platforms.

.PARAMETER ListPlatforms
Display the list of all supported platforms, then exit.

.PARAMETER NoRestore
Do not restore the project/solution.

#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $false)]
    [Alias("p")] [string] $ProjectPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration,

    [Parameter(Mandatory = $false)]
    [Alias("r")] [string] $Runtime,

    [Parameter(Mandatory = $false)]
    [Alias("f")] [string] $TargetPlatform,
    [Alias("a")] [switch] $AllPlatforms,
    [Alias("l")] [switch] $ListPlatforms,

                 [switch] $NoRestore,
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
  -p|-ProjectPath       the project to build.
  -c|-Configuration     the configuration to build the project/solution for.
  -r|-Runtime           the runtime to build the project/solution for.

  -f|-TargetPlatform    the platform to build the project/solution for.
  -a|-AllPlatforms      build the project/solution for ALL supported platforms.
  -l|-ListPlatforms     print the list of supported platforms, then exit.

     -NoRestore         do not restore the project/solution.
  -h|-Help              print this help and exit.

Arguments starting with '/p:' are passed through to dotnet.exe.
> build.ps1 /p:Retail=true
> build.ps1 /p:PatchEquality=true
> build.ps1 /p:PrintSettings=true

Examples.
> build.ps1                                 #
> build.ps1 -a /p:Retail=true               #
> build.ps1 -p src\Abc.Maybe -c Release     # "Release" build of Abc.Maybe

Looking for more help?
> Get-Help -Detailed reset.ps1

"@
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Hello "this is the build script.`n"

try {
    ___BEGIN___

    $platforms = Get-SolutionPlatforms

    if ($ListPlatforms) {
        say ("Supported platforms:`n- {0}" -f ($platforms -join "`n- "))
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
    if ($NoRestore)     { $args += "--no-restore" }

    $args += '/p:TargetFrameworks=\"' + ($platforms -join ";") + '\"'

    if ($AllPlatforms)  {
        $args += "/p:TargetFramework="
    }
    elseif ($TargetPlatform)  {
        if ($TargetPlatform -notin $platforms) {
            die "The specified platform is not supported: ""$TargetPlatform""."
        }

        $args += "/p:TargetFramework=$TargetPlatform"
    }

    foreach ($arg in $Properties) {
        if ($arg.StartsWith("/p:", "InvariantCultureIgnoreCase")) {
            $args += $arg
        }
    }

    # Do not invoke "dotnet restore" before, it will fail w/ -TargetPlatform.
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

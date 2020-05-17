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

.PARAMETER ProjectPath
The project to build.

.PARAMETER Configuration
The configuration to build the project/solution for.

.PARAMETER Runtime
The runtime to build the project/solution for.

.PARAMETER TargetPlatform
The platform to build the project/solution for.
Ignored if -AllPlatforms is also set and equals $true.

.PARAMETER AllPlatforms
Build the project/solution (exe projects included) for ALL supported platforms.

.PARAMETER ListPlatforms
Display the list of all supported platforms, then exit.

.PARAMETER Sign
Sign the assemblies.

.PARAMETER Unchecked
Use unchecked arithmetic.

.PARAMETER XmlDocumentation
Generate the XML documentation.

.PARAMETER HideInternals
Hide internals.

.PARAMETER Pack
This is a meta-option, it automatically sets -Sign, -XmlDocumentation,
-Unchecked and -HideInternals to $true.

.PARAMETER NoRestore
Do not restore the project/solution.

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
                 [string] $ProjectPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration,

    [Parameter(Mandatory = $false)]
    [Alias("r")] [string] $Runtime,

    [Parameter(Mandatory = $false)]
    [Alias("f")] [string] $TargetPlatform,
    [Alias("a")] [switch] $AllPlatforms,
    [Alias("l")] [switch] $ListPlatforms,

    # See Directory.Build.props/targets.
                 [switch] $Sign,
                 [switch] $Unchecked,
                 [switch] $XmlDocumentation,
                 [switch] $HideInternals,
                 [switch] $Pack,

                 [switch] $MyVerbose,
                 [switch] $PatchEquality,

                 [switch] $NoRestore,
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

#endregion
################################################################################
#region Helpers

function Print-Help {
    say @"

Build the solution for all supported platforms.

Usage: reset.ps1 [arguments]
     -ProjectPath       the project to build.
  -c|-Configuration     the configuration to build the project/solution for.
  -r|-Runtime           the runtime to build the project/solution for.

  -f|-TargetPlatform    the platform to build the project/solution for.
  -a|-AllPlatforms      build the project/solution for ALL supported platforms.
  -l|-ListPlatforms     print the list of supported platforms, then exit.

     -Sign              sign the assemblies.
     -Unchecked         use unchecked arithmetic.
     -XmlDocumentation  generate the XML documentation.
     -HideInternals     hide internals.
     -Pack              meta-option setting the four previous one at once.

     -MyVerbose         set MSBuild property "DisplaySettings" to true.
     -PatchEquality     set MSBuild property "PatchEquality" to true.

     -NoRestore         do not restore the project/solution.

  -h|-Help              print this help and exit.

Examples.
> build.ps1                             #
> build.ps1 -AllPlatforms -Pack         #
> build.ps1 src\Abc.Maybe -c Release    # "Release" build of Abc.Maybe

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

    $args = @('/p:TargetFrameworks=\"' + ($platforms -join ";") + '\"')
    if ($Configuration) { $args += "-c $Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($NoRestore)     { $args += "--no-restore" }

    if ($AllPlatforms)  {
        $args += "/p:TargetFramework="
    }
    elseif ($TargetPlatform)  {
        if ($TargetPlatform -notin $platforms) {
            die "The specified platform is not supported: ""$TargetPlatform""."
        }

        $args += "/p:TargetFramework=$TargetPlatform"
    }

    if ($Pack) {
        $args += "/p:Pack=true"
    }
    else {
        if ($Sign)             { $args += "/p:SignAssembly=true" }
        if ($Unchecked)        { $args += "/p:CheckForOverflowUnderflow=false" }
        if ($XmlDocumentation) { $args += "/p:GenerateDocumentationFile=true" }
        if ($HideInternals)    { $args += "/p:HideInternals=true" }
    }

    # Local settings.
    if ($MyVerbose)            { $args += "/p:DisplaySettings=true" }
    if ($PatchEquality)        { $args += "/p:PatchEquality=true" }

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

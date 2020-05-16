# See LICENSE in the project root for license information.

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
Specify a single project to build.

.PARAMETER Configuration
The configuration to build the project/solution for.

.PARAMETER Runtime
The runtime to build the project/solution for.

.PARAMETER TargetPlatform
A (single) platform to build the project/solution for.
Ignored if -AllPlatforms is also set and equals $true.

.PARAMETER AllPlatforms
Build ALL projects (exe projects included) for ALL supported platforms.

.PARAMETER SignAssembly
Sign the assembly.

.PARAMETER NoDocumentation
Do not build the XML documentation.

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

    # Platform selection.
    #
    [Parameter(Mandatory = $false)]
    [Alias("f")] [string] $TargetPlatform,
    [Alias("a")] [switch] $AllPlatforms,

    # Standard settings.
    #
                 [switch] $SignAssembly,
                 [switch] $NoDocumentation,
                 [switch] $NoRestore,

    # Local settings (see Directory.Build.props).
    #
    [Alias("v")] [switch] $MyVerbose,
                 [switch] $Pack,
                 [switch] $PatchEquality,
                 [switch] $HideInternals,


    # Other parameters.
    #
    [Alias("h")] [switch] $Help
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

if ($Help) {
    say @"

Build the solution for all supported platforms.

Usage: reset.ps1 [arguments]
     -ProjectPath       specify a single project to build.
  -c|-Configuration     the configuration to build the project/solution for.
  -r|-Runtime           the runtime to build the project/solution for.

  -f|-TargetPlatform    a (single) platform to build the project/solution.
  -a|-AllPlatforms      build ALL projects for ALL supported platforms.

     -SignAssembly      sign the assembly.
     -NoDocumentation   do not build the XML documentation.
     -NoRestore         do not restore the project/solution.

  -v|-MyVerbose         set MSBuild property "DisplaySettings" to true.
     -Pack              set MSBuild property "Pack" to true.
     -PatchEquality     set MSBuild property "PatchEquality" to true.
     -HideInternals     set MSBuild property "HideInternals" to true.

  -h|-Help              print this help and exit.

Examples.
> build.ps1                             #
> build.ps1 -AllPlatforms               #
> build.ps1 src\Abc.Maybe -c Release    # "Release" build of Abc.Maybe

"@

    exit
}

Hello "this is the build script.`n"

try {
    ___BEGIN___

    if ($ProjectPath) {
        if (-not (Test-Path $ProjectPath)) {
            die "The specified project path doe not exist: ""$ProjectPath""."
        }
    }
    else {
        $ProjectPath = Join-Path $ROOT_DIR "Maybe.sln" -Resolve
    }

    $args = @()
    if ($Configuration) { $args += "-c $Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($NoRestore)     { $args += "--no-restore" }

    # Platforms.
    $platforms = ($SOLUTION_SUPPORTED_PLATFORMS + (Get-MaxApiPlatform)) -join ";"
    $args += '/p:TargetFrameworks=\"' + $platforms + '\"'

    if ($AllPlatforms)         { $args += "/p:TargetFramework=" }
    elseif ($TargetFramework)  { $args += "/p:TargetFramework=$TargetFramework" }

    # Standard settings.
    if ($SignAssembly)         { $args += "/p:SignAssembly=true" }
    if (-not $NoDocumentation) { $args += "/p:GenerateDocumentationFile=true" }

    # Local settings.
    if ($MyVerbose)            { $args += "/p:DisplaySettings=true" }
    if ($Pack)                 { $args += "/p:Pack=true" }
    if ($PatchEquality)        { $args += "/p:PatchEquality=true" }
    if ($HideInternals)        { $args += "/p:HideInternals=true" }

    & dotnet build $ProjectPath $args
        || die "Build task failed."
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

################################################################################

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
The .NET command to be called. Default = "build".

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
    [Alias('a')] [switch] $AllKnown,
                 [switch] $Smoke,

    [Parameter(Mandatory = $false)]
    [ValidateSet('q', 'quiet', 'm', 'minimal', 'n', 'normal', 'd', 'detailed', 'diag', 'diagnostic')]
    [Alias('v')] [string] $Verbosity,

                 [switch] $Force,
                 [switch] $NoAnalyzers,
                 [switch] $NoCheck,
                 [switch] $NoRestore,
                 [switch] $NoBuild,
    [Alias("v")] [switch] $MyVerbose,
                 [switch] $DryRun,
    [Alias("h")] [switch] $Help,

    [Parameter(Mandatory=$false, ValueFromRemainingArguments = $true)]
               [string[]] $Properties
)

# ------------------------------------------------------------------------------

New-Variable ROOT_DIR (Get-Item $PSScriptRoot).Parent.FullName `
    -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers

function Print-Help {
    Write-Host @"

Build the solution for all supported platforms.

Usage: reset.ps1 [arguments]
  -t|-Task           the .NET command to be called.
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

# ------------------------------------------------------------------------------

function Get-Platforms([Xml] $props, [switch] $allKnown) {
    if ($allKnown) {
        $classic = Select-Property $props 'MaxClassicPlatforms'
        $core    = Select-Property $props 'MaxCorePlatforms'
    }
    else {
        $classic = Select-Property $props 'MinClassicPlatforms'
        $core    = Select-Property $props 'MinCorePlatforms'
    }

    @($classic, $core)
}

function Get-Standards([Xml] $props) {
    Select-Property $props 'SupportedStandards'
}

function Get-TargetFrameworks([string[]] $platforms) {
    '/p:TargetFrameworks=\"' + ($platforms -join ';') + '\"'
}

function Load-Properties([string] $path) {
    $xml = Get-Content $path
    $props = New-Object -TypeName System.Xml.XmlDocument
    $props.PreserveWhitespace = $false
    $props.LoadXml($xml)
    $props
}

function Select-Property([Xml] $props, [string] $property) {
    $nodes = $props | Select-Xml -XPath "//Project/PropertyGroup/$property"
    if ($nodes -eq $null -or $nodes.Count -ne 1) {
        Write-Error "Could not find the property named ""$property""."
    }
    $text = $nodes[0].Node.InnerText.Trim().Trim(';').Replace(' ', '')
    $text.Split(';')
}

#endregion
################################################################################
#region Main.

if ($Help) { Print-Help ; exit }

Write-Host "Hello, this is the make script.`n"

try {
    pushd $ROOT_DIR

    $props = Load-Properties (Join-Path $ROOT_DIR 'Directory.Build.props')
    $classic, $core = Get-Platforms $props -AllKnown:($AllKnown -or $Platform -or $ListPlatforms)
    $platformList = $classic + $core
    #$standardList = Get-Standards $props

    if ($ListPlatforms) {
        Write-Host ("Supported platforms (option -Platform):`n- {0}" -f ($platformList -join "`n- "))
        exit
    }

    # Project.
    if ($ProjectPath) {
        if (-not (Test-Path $ProjectPath)) {
            Write-Error "The specified project path does not exist: ""$ProjectPath""."
        }
    }
    else {
        $ProjectPath = Join-Path $ROOT_DIR "Maybe.sln" -Resolve
    }

    # Common args available to all commands.
    $args = @()
    if ($Configuration) { $args += "-c:$Configuration" }
    if ($Runtime)       { $args += "--runtime:$runtime" }
    if ($Verbosity)     { $args += "--verbosity:$Verbosity" }
    if ($NoRestore)     { $args += "--no-restore" }
    if ($NoAnalyzers)   { $args += "/p:RunAnalyzers=false" }

    $cmd = $Task.ToLowerInvariant()
    switch ($cmd) {
        'build' {
            if ($Force)     { $args += "--force" }
            if ($MyVerbose) { $args += "/p:PrintSettings=true" }
        }
        'test' {
            if ($NoBuild)   { $args += "--no-build" }
            if ($MyVerbose) { $args += "-v:minimal", "/p:PrintSettings=true" }
        }

    }

    # Platform.
    if ($Smoke) {
        $args += "/p:SmokeBuild=true"
    }
    elseif ($Platform)  {
        if (-not $NoCheck -and $Platform -notin $platformList) {
            Write-Error "The specified platform is not supported: ""$Platform""."
        }

        $args += "/p:TargetFrameworks=$Platform"
    }

    # Additional properties.
    foreach ($arg in $Properties) {
        if ($arg.StartsWith("/p:", "InvariantCultureIgnoreCase")) {
            $args += $arg
        }
    }

    Write-Host "dotnet.exe is about to run using"
    Write-Host "  Command -> $cmd"
    Write-Host "  Args    -> $args"

    if (-not $DryRun) {
        & dotnet $cmd $ProjectPath $args
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
    Write-Host "`nGoodbye."
}

#endregion
################################################################################

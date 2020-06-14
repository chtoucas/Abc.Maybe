# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Wrapper for dotnet.exe.

.DESCRIPTION
Build the solution for all supported platforms.
To build a single project, specify its path via -Project.
NB: the list of supported platforms can NOT be overriden.

The default behaviour is to build libraries for all supported platforms, and to
build exe projects only for "DefaultPlatform".

To target a single platform, use -Platform (no "s").

Targetting a single platform or all supported platforms may "transform" an exe
project into a library.

.PARAMETER Task
The .NET command to be called.

.PARAMETER Project
The project to build. Default (implicit) = solution.

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

.PARAMETER NoCheck
Do not check whether the specified platform is supported or not?
Useful to test the solution for platforms listed in "NotSupportedTestPlatforms"
from D.B.props. Of course, as the name suggests, a succesful outcome is not
guaranteed, to say the least, it might not even run.

.PARAMETER NoRestore
Do not restore the project/solution?

.PARAMETER Help
Print help text then exit?
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('restore', 'build', 'test')]
    [Alias('t')] [string] $Task = 'build',

    [Parameter(Mandatory = $false)]
    [Alias('p')] [string] $Project,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [Alias('c')] [string] $Configuration,

    [Parameter(Mandatory = $false)]
    [Alias('r')] [string] $Runtime,

    [Parameter(Mandatory = $false)]
    [Alias('f')] [string] $Platform,

    [Parameter(Mandatory = $false)]
    [ValidateSet('q', 'quiet', 'm', 'minimal', 'n', 'normal', 'd', 'detailed', 'diag', 'diagnostic')]
    [Alias('v')] [string] $Verbosity,

                 [switch] $Flat,
    [Alias('l')] [switch] $ListPlatforms,
    [Alias('a')] [switch] $AllKnown,
                 [switch] $NoStandard,
                 [switch] $NoCore,
                 [switch] $NoClassic,
                 [switch] $NoCheck,

                 [switch] $Force,
                 [switch] $NoRestore,
                 [switch] $NoBuild,

                 [switch] $DryRun,
    [Alias('h')] [switch] $Help,

    [Parameter(ValueFromRemainingArguments = $true)]
               [string[]] $Properties
)

# ------------------------------------------------------------------------------

New-Variable ROOT_DIR (Get-Item $PSScriptRoot).Parent.FullName `
    -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers

function Print-Help {
    Write-Host @'

Wrapper for dotnet.exe.

Usage: reset.ps1 [arguments]
  -t|-Task           the .NET command to be called.
  -p|-Project        the project to build. Default = solution.
  -c|-Configuration  the configuration to build the project/solution for. Default = "Debug".
  -r|-Runtime        the runtime to build the project/solution for.
  -f|-Platform       the platform to build the project/solution for.
  -v|-Verbosity

     -Flat
  -l|-ListPlatforms  print the list of supported platforms, then exit?
     -AllKnown
     -NoStandard
     -NoCore
     -NoClassic
     -NoCheck        do not check whether the specified platform is supported or not?

     -Force          forces all dependencies to be resolved even if the last restore was successful?
     -NoRestore      do not restore the project/solution?
     -NoBuild

     -Verbose
     -Debug
     -DryRun
  -h|-Help           print this help and exit?

Arguments starting with '/p:' are passed through to dotnet.exe.

Commonly used properties.
> make.ps1 [...] /p:SmokeBuild=true             # mimic build inside VS.
                                                # shortcut: $env:SMOKE_BUILD = 'true'.
> make.ps1 [...] /p:Retail=true
> make.ps1 [...] /p:PrintSettings=true          # display settings used to compile each DLL.
                                                # With the task 'test', one should use at
                                                # least "-Verbosity=minimal".
> make.ps1 [...] /p:RunAnalyzers=false          # turn off source code analysis.

Misc properties.
> make.ps1 [...] /p:HideInternals=true
> make.ps1 [...] /p:PatchEquality=true

Examples.
> make.ps1                                      # build...
> make.ps1 -t test -NoBuild                     # ... then test.

CI tasks.
> make.ps1 -t restore -Flat -NoStandard            /p:Retail=true
> make.ps1 -t build   -Flat -NoStandard -NoRestore /p:Retail=true /p:VersionSuffix=ci
> make.ps1 -t test    -Flat -NoStandard -NoBuild   /p:Retail=true
Remark: to mimic a CI build, add '/p:ContinuousIntegrationBuild=true' which is
implicit on CI servers.

Looking for more help?
> Get-Help -Detailed make.ps1

'@
}

# ------------------------------------------------------------------------------

function Get-Platforms(
    [switch] $noStandard,
    [switch] $noCore,
    [switch] $noClassic,
    [switch] $allKnown) {

    # Load property files.
    $xml = Get-Content (Join-Path $ROOT_DIR 'Directory.Build.props')
    $props = New-Object -TypeName System.Xml.XmlDocument
    $props.PreserveWhitespace = $false
    $props.LoadXml($xml)

    $platforms = @()

    if (-not $noStandard) {
        $platforms = Select-Property $props 'SupportedStandards'
    }

    if (-not $noCore) {
        if ($allKnown) {
            $platforms += Select-Property $props 'MaxCorePlatforms'
        }
        else {
            $platforms += Select-Property $props 'MinCorePlatforms'
        }
    }

    # We ignore Mono on Linux and MacOS...
    if (-not $noClassic -and $IsWindows) {
        if ($allKnown) {
            $platforms += Select-Property $props 'MaxClassicPlatforms'
        }
        else {
            $platforms += Select-Property $props 'MinClassicPlatforms'
        }
    }

    $platforms
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

$hello = 'Hello, this is the make script'
if ($DryRun) { Write-Host "$hello (DRY RUN).`n" }
        else { Write-Host "$hello.`n" }

try {
    pushd $ROOT_DIR

    if ($ListPlatforms) {
        $platforms = (Get-Platforms -AllKnown) -join "`n- "
        Write-Host "Supported platforms (option -Flat):`n- $platforms"
        exit
    }

    # Command and its common arguments.
    $args = @()
    if ($Configuration) { $args += "-c:$Configuration" }
    if ($Runtime)       { $args += "-r:$runtime" }
    if ($Verbosity)     { $args += "-v:$Verbosity" }

    $cmd = $Task.ToLowerInvariant()
    switch ($cmd) {
        'restore' {
            $args += '--configfile:NuGet.Config'
        }
        'build' {
            if ($NoRestore) { $args += '--no-restore' }
            if ($Force)     { $args += '--force' }
        }
        'test' {
            if ($NoRestore) { $args += '--no-restore' }
            if ($NoBuild)   { $args += '--no-build' }
        }
    }

    # Project.
    if ($Project -and -not (Test-Path $Project)) {
        Write-Error "The specified project path does not exist: ""$Project""."
    }

    # Targets.
    Write-Debug ('SMOKE_BUILD -> {0}' -f $env:SMOKE_BUILD)

    if ($env:SMOKE_BUILD -eq 'true' -or ($Properties -and $Properties.Contains('/p:SmokeBuild=true'))) {
        Write-Verbose "Execute command using smoke context."
    }
    else {
        if ($Flat) {
            $platforms = Get-Platforms `
                -NoStandard:$NoStandard `
                -NoCore:$NoCore `
                -NoClassic:$NoClassic `
                -AllKnown:($AllKnown -or $Platform)

            if ($cmd -eq 'test') {
                $platforms = $platforms | where { -not $_.StartsWith('netstandard') }
            }

            if ($Platform)  {
                Write-Verbose "Execute command for platform ""$Platform"" (FLAT)."
                if (-not $NoCheck -and $Platform -notin $platforms) {
                    Write-Error "The specified platform is not supported: ""$Platform""."
                }

                $args += "/p:TargetFrameworks=$Platform"
            }
            else {
                Write-Verbose "Execute command for a custom platform set (FLAT)."
                if (-not $platforms) {
                    Write-Error 'The lits of targets is empty.'
                }
                $args += '/p:TargetFrameworks=\"' + ($platforms -join ';') + '\"'
            }
        }
        elseif ($Platform)  {
            Write-Verbose "Execute command for platform ""$Platform""."
            $args += "-f:$Platform"
        }
        else {
            Write-Verbose "Execute command for the default platform set."
        }
    }

    # Additional properties.
    Write-Debug "Properties -> $Properties"
    foreach ($prop in $Properties) {
        if ($prop.StartsWith('/p:', 'InvariantCultureIgnoreCase')) {
            $args += $prop
        }
    }

    $msg  = "  Command -> $cmd`n"
    $msg += "  Project -> $Project`n"
    $msg += "  Args    -> $args"

    if ($DryRun) {
        Write-Host 'dotnet.exe would run using'
        Write-Host $msg
    }
    else {
        Write-Verbose 'dotnet.exe is about to run using'
        Write-Verbose $msg
        & dotnet $cmd $Project $args
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

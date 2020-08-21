# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2019 Narvalo.Org. All rights reserved.

#Requires -Version 7

################################################################################
#region Preamble.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet('restore', 'build', 'test')]
                 [string] $Task = 'build',

    [Parameter(Mandatory = $false)]
    [Alias('p')] [string] $Project,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [Alias('c')] [string] $Configuration,

    [Parameter(Mandatory = $false)]
    [Alias('r')] [string] $Runtime,

    [Parameter(Mandatory = $false)]
    [Alias('f')] [string] $Framework,

    [Alias('X')] [switch] $Flatten,
    [Alias('l')] [switch] $ListFrameworks,
                 [switch] $AllKnown,
                 [switch] $NoStandard,
                 [switch] $NoCore,
                 [switch] $NoClassic,
                 [switch] $NoCheck,

    [Parameter(Mandatory = $false)]
                 [string] $Trx,

    [Parameter(Mandatory = $false)]
    [ValidateSet('q', 'quiet', 'm', 'minimal', 'n', 'normal', 'd', 'detailed', 'diag', 'diagnostic')]
    [Alias('v')] [string] $Verbosity,
                 [switch] $Force,
                 [switch] $NoRestore,
                 [switch] $NoBuild,

                 [switch] $DryRun,
    [Alias('h')] [switch] $Help,

    [Parameter(ValueFromRemainingArguments = $true, Position = 1)]
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
     -Task           the .NET command to be called. Default = "build".
  -p|-Project        the project to build. Default (implicit) = solution.
  -c|-Configuration  the configuration to build the project for. Default (implicit) = "Debug".
  -r|-Runtime        the runtime to build the project for.
  -f|-Framework      the framework to build the project for.

  -X|-Flatten	     flatten the project dependencies graph?
  -l|-ListFrameworks print the list of supported frameworks then exit?
     -AllKnown       inlude ALL known framework versions (SLOW)?
     -NoStandard     exclude .NET Standard?
     -NoCore         exclude .NET Core?
     -NoClassic      exclude .NET Framework?
     -NoCheck        do not check whether the specified framework is supported or not?

     -Trx            specifies a VSTest results file (format trx).

  # Common options for dotnet.exe.
  -v|-Verbosity      sets the verbosity level.
     -Force          forces all dependencies to be resolved even if the last restore was successful?
     -NoRestore      do not restore the project?
     -NoBuild        do not build the project?

  # Other options.
     -Verbose        PS verbose mode?
     -Debug          PS debug mode?
     -DryRun         do not execute dotnet.exe?
  -h|-Help           print this help then exit?

Arguments starting with '/p:' are passed through to dotnet.exe.

Remarks:
- Option -Flatten.
  We override "TargetFrameworks" which means that all projects are compiled With
  the same targets. Beware, it changes the dependency resolution graph.
  Caveats:
  - testing w/ option -Flatten on is supported but might not do what we expect.
    To properly test the package for a target not explicitely listed, which is
    always the case except for "net461", one should use test-package.ps1 instead.
  - if "TargetFrameworks" contains a .NET Standard, an exe project will be
    compiled for it, and therefore won't be executable.
- Option -NoCheck.
  Useful to build/test the project for frameworks listed in
  "MyNotSupportedTestFrameworks" from D.B.props. Of course, as the name suggests,
  a succesful outcome is not guaranteed, to say the least, it might not even run.

Commonly used properties.
> make.ps1 [...] /p:SlimBuild=true              # mimic building inside VS.
                                                # shortcut: $env:SLIM_BUILD = 'true'.
> make.ps1 [...] /p:PrintSettings=true          # display settings used to compile each DLL.
                                                # With the task 'test', one should use at
                                                # least "-Verbosity=minimal".
> make.ps1 [...] /p:RunAnalyzers=false          # turn off source code analysis.

Misc properties.
> make.ps1 [...] /p:vNext=true                  # Release-only
> make.ps1 [...] /p:VisibleInternals=true       # Default = false for Release, true othewise
> make.ps1 [...] /p:PatchEquality=true          # Debug-only
> make.ps1 [...] /p:PlainLinq=true              # Debug-only

Example: build then test.
> make.ps1
> make.ps1 test -NoBuild -Trx ..\..\..\__\xunit.trx

Azure tasks.
> make.ps1 restore -c Release -X -NoStandard
> make.ps1 build   -c Release -X -NoStandard -NoRestore
Remark: to truely mimic an Azure task, one should also add '/p:TF_BUILD=true'
(implicitly set on an Azure server).

'@
}

# ------------------------------------------------------------------------------

function Get-Frameworks(
    [switch] $noStandard,
    [switch] $noCore,
    [switch] $noClassic,
    [switch] $allKnown) {

    # Load the top-level D.B.props.
    $xml = Get-Content (Join-Path $ROOT_DIR 'Directory.Build.props')
    $props = New-Object -TypeName System.Xml.XmlDocument
    $props.PreserveWhitespace = $false
    $props.LoadXml($xml)

    $fmks = @()
    if (-not $noStandard) {
        $fmks = Select-Property $props 'MySupportedStandards'
    }
    if (-not $noCore) {
        $propName = $allKnown ? 'MyMaxCoreFrameworks' : 'MyMinCoreFrameworks'
        $fmks += Select-Property $props $propName
    }
    # WARNING: we ignore Mono on Linux and MacOS...
    if (-not $noClassic -and $IsWindows) {
        $propName = $allKnown ? 'MyMaxClassicFrameworks' : 'MyMinClassicFrameworks'
        $fmks += Select-Property $props $propName
    }

    $fmks
}

# ------------------------------------------------------------------------------

function Format-TargetFrameworks([string[]] $fmks) {
    if (-not $fmks) { Write-Error 'The lits of targets is empty.' }
    # Quotes and multiple values:
    # - On Windows,     /p:TargetFrameworks=\"XXX;YYY\"
    # - On Linux/MacOs, /p:TargetFrameworks='"XXX;YYY"'
    # See https://github.com/dotnet/sdk/issues/8792#issuecomment-393756980
    if ($IsWindows) { $bquote = '\"' ; $equote = '\"' }
               else { $bquote = "'"""; $equote = """'" }
    $targetFrameworks = $fmks -join ';'
    '/p:TargetFrameworks=' + $bquote + ($fmks -join ';') + $equote
}

# ------------------------------------------------------------------------------

function Select-Property([Xml] $props, [string] $property) {
    $nodes = $props | Select-Xml -XPath "//Project/PropertyGroup/$property"
    if ($nodes -eq $null -or $nodes.Count -ne 1) {
        Write-Error "Could not find the property named ""$property""."
    }
    $text = $nodes[0].Node.InnerText.Trim().Trim(';').Replace(' ', '')
    $text.Split(';')
}

# ------------------------------------------------------------------------------

# Only one arg...
function sprintf([string] $string, [string] $arg) {
    if (-not $arg) { $arg = '(empty)' }
    $string -f $arg
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

    if ($ListFrameworks) {
        $fmks = (Get-Frameworks -AllKnown) -join "`n- "
        Write-Host "Supported frameworks (option -Flatten):`n- $fmks"
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
            if ($Trx)       { $args += "--logger:""trx;LogFileName=$Trx""" }
        }
    }

    # Project.
    if ($Project -and -not (Test-Path $Project)) {
        Write-Error "The specified project path does not exist: ""$Project""."
    }

    # Targets.
    Write-Debug (sprintf 'SLIM_BUILD = {0}' $env:SLIM_BUILD)

    if ($env:SLIM_BUILD -eq 'true' -or ($Properties -and $Properties.Contains('/p:SlimBuild=true'))) {
        Write-Verbose "Execute command in a smoke context."
    }
    else {
        if ($Flatten) {
            if ($cmd -eq 'test') {
                Write-Warning 'Testing w/ option -Flatten on...'
                Write-Warning 'To properly test the package, one should use test-package.ps1 instead.'
            }

            if ($Framework)  {
                Write-Verbose "Execute command for framework ""$Framework"" (FLAT)."
                if (-not $NoCheck -and $Framework -notin (Get-Frameworks -AllKnown)) {
                    Write-Error "The specified framework is not supported: ""$Framework""."
                }
                $args += "/p:TargetFrameworks=$Framework"
            }
            else {
                Write-Verbose "Execute command for a custom framework set (FLAT)."
                $fmks = Get-Frameworks `
                    -NoStandard:($NoStandard -or $cmd -eq 'test') `
                    -NoCore:$NoCore `
                    -NoClassic:$NoClassic `
                    -AllKnown:$AllKnown
                $args += Format-TargetFrameworks $fmks
            }
        }
        elseif ($Framework)  {
            Write-Verbose "Execute command for framework ""$Framework""."
            # If the framework is not listed in "TargetFrameworks", dotnet.exe
            # will fail silently :-(
            $args += "-f:$Framework"
        }
        else {
            Write-Verbose "Execute command for the default framework set."
        }
    }

    # Additional properties.
    Write-Debug (sprintf "Properties = {0}" $Properties)
    foreach ($prop in $Properties) {
        if ($prop.StartsWith('/p:', 'InvariantCultureIgnoreCase')) {
            $args += $prop
        }
    }

    if ($DryRun) {
        Write-Host 'dotnet.exe would run using:'
        Write-Host "  Command -> $cmd"
        Write-Host (sprintf "  Project -> {0}" $Project)
        Write-Host (sprintf "  Args    -> {0}" $args)
    }
    else {
        Write-Verbose 'dotnet.exe is about to run using:'
        Write-Verbose "  Command -> $cmd"
        Write-Verbose (sprintf "  Project -> {0}" $Project)
        Write-Verbose (sprintf "  Args    -> {0}" $args)
        & dotnet $cmd $Project $args
    }
}
catch {
    Write-Host $_ -Foreground Red
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

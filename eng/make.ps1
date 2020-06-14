# See LICENSE in the project root for license information.

#Requires -Version 7

################################################################################
#region Preamble.

<#
.SYNOPSIS
Wrapper for dotnet.exe.
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

                 [switch] $Flat,
    [Alias('l')] [switch] $ListPlatforms,
                 [switch] $AllKnown,
                 [switch] $NoStandard,
                 [switch] $NoCore,
                 [switch] $NoClassic,
                 [switch] $NoCheck,

    [Parameter(Mandatory = $false)]
    [ValidateSet('q', 'quiet', 'm', 'minimal', 'n', 'normal', 'd', 'detailed', 'diag', 'diagnostic')]
    [Alias('v')] [string] $Verbosity,
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

New-Variable SRC_DIR (Join-Path $ROOT_DIR "src" -Resolve) `
    -Scope Script -Option Constant

#endregion
################################################################################
#region Helpers

function Print-Help {
    Write-Host @'

Wrapper for dotnet.exe.

Usage: reset.ps1 [arguments]
  -t|-Task           the .NET command to be called. Default = "build".
  -p|-Project        the project to build. Default (implicit) = solution.
  -c|-Configuration  the configuration to build the project/solution for. Default (implicit) = "Debug".
  -r|-Runtime        the runtime to build the project/solution for.
  -f|-Platform       the platform to build the project/solution for.

     -Flat
  -l|-ListPlatforms  print the list of supported platforms, then exit?
     -AllKnown       inlude ALL known platform versions (SLOW)?
     -NoStandard     exclude .NET Standard?
     -NoCore         exclude .NET Core?
     -NoClassic      exclude .NET Framework?
     -NoCheck        do not check whether the specified platform is supported or not?

  # Common options for dotnet.exe.
  -v|-Verbosity      sets the verbosity level.
     -Force          forces all dependencies to be resolved even if the last restore was successful?
     -NoRestore      do not restore the project/solution?
     -NoBuild        do not build the project/solution?

  # Other options.
     -Verbose        PS verbose mode.
     -Debug          PS debug mode.
     -DryRun         do not execute dotnet.exe.
  -h|-Help           print this help then exit?

Arguments starting with '/p:' are passed through to dotnet.exe.

Remarks:
- Option -Flat.
  An exe may "become" a library.
- Option -NoCheck.
  Useful to test the solution for platforms listed in "NotSupportedTestPlatforms"
  from D.B.props. Of course, as the name suggests, a succesful outcome is not
  guaranteed, to say the least, it might not even run.

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

Azure tasks.
> make.ps1 -t restore -Flat -NoStandard            /p:Retail=true
> make.ps1 -t build   -Flat -NoStandard -NoRestore /p:Retail=true /p:VersionSuffix=ci
> make.ps1 -t test    -Flat -NoStandard -NoBuild   /p:Retail=true
Remark: to truely mimic an Azure task, one should add
'/p:ContinuousIntegrationBuild=true' which is implicit set on an Azure server.

'@
}

# ------------------------------------------------------------------------------

function Get-Platforms(
    [switch] $noStandard,
    [switch] $noCore,
    [switch] $noClassic,
    [switch] $allKnown) {

    # Load the top-level D.B.props.
    $xml = Get-Content (Join-Path $ROOT_DIR 'Directory.Build.props')
    $props = New-Object -TypeName System.Xml.XmlDocument
    $props.PreserveWhitespace = $false
    $props.LoadXml($xml)

    $platforms = @()
    if (-not $noStandard) {
        $platforms = Select-Property $props 'SupportedStandards'
    }
    if (-not $noCore) {
        $propName = $allKnown ? 'MaxCorePlatforms' : 'MinCorePlatforms'
        $platforms += Select-Property $props $propName
    }
    # WARNING: we ignore Mono on Linux and MacOS...
    if (-not $noClassic -and $IsWindows) {
        $propName = $allKnown ? 'MaxClassicPlatforms' : 'MinClassicPlatforms'
        $platforms += Select-Property $props $propName
    }

    $platforms
}

# ------------------------------------------------------------------------------

function Get-TargetFrameworks([string[]] $platforms) {
    if (-not $platforms) { Write-Error 'The lits of targets is empty.' }
    # Quotes and multiple values:
    # - On Windows,     /p:TargetFrameworks=\"XXX;YYY\"
    # - On Linux/MacOs, /p:TargetFrameworks='"XXX;YYY"'
    # See https://github.com/dotnet/sdk/issues/8792#issuecomment-393756980
    if ($IsWindows) { $bquote = '\"' ; $equote = '\"' }
               else { $bquote = "'"""; $equote = """'" }
    $targetFrameworks = $platforms -join ';'
    '/p:TargetFrameworks=' + $bquote + ($platforms -join ';') + $equote
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
    Write-Debug (sprintf 'SMOKE_BUILD = {0}' $env:SMOKE_BUILD)

    if ($env:SMOKE_BUILD -eq 'true' -or ($Properties -and $Properties.Contains('/p:SmokeBuild=true'))) {
        Write-Verbose "Execute command in a smoke context."
    }
    else {
        if ($Flat) {
            if ($Platform)  {
                Write-Verbose "Execute command for platform ""$Platform"" (FLAT)."
                if (-not $NoCheck -and $Platform -notin (Get-Platforms -AllKnown)) {
                    Write-Error "The specified platform is not supported: ""$Platform""."
                }
                $args += "/p:TargetFrameworks=$Platform"
            }
            else {
                Write-Verbose "Execute command for a custom platform set (FLAT)."
                $platforms = Get-Platforms `
                    -NoStandard:($NoStandard -or $cmd -eq 'test') `
                    -NoCore:$NoCore `
                    -NoClassic:$NoClassic `
                    -AllKnown:$AllKnown
                $args += Get-TargetFrameworks $platforms
            }
        }
        elseif ($Platform)  {
            Write-Verbose "Execute command for platform ""$Platform""."
            # If the platform is not listed in "TargetFrameworks", dotnet.exe
            # will fail silently :-(
            $args += "-f:$Platform"
        }
        else {
            Write-Verbose "Execute command for the default platform set."
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

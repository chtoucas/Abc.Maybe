# See LICENSE in the project root for license information.

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('restore', 'build', 'test')]
  [string] $Task,

  [Parameter(Mandatory = $false, Position = 1)]
  [ValidateSet('core', 'classic', 'any')]
  [string] $Family = 'core',

  [Parameter(Mandatory = $false)]
  [ValidateSet('Debug', 'Release')]
  [Alias('c')] [string] $Configuration = 'Release',

  [Parameter(Mandatory = $false)]
  [Alias('r')] [string] $Runtime,

  [Parameter(Mandatory = $false)]
  [ValidateSet('q', 'quiet', 'm', 'minimal', 'n', 'normal', 'd', 'detailed', 'diag', 'diagnostic')]
  [Alias('v')] [string] $Verbosity,

  [Alias('a')] [switch] $All,
  [switch] $DryRun
)

# ------------------------------------------------------------------------------

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

function Get-Platforms([Xml] $props, [string] $family, [switch] $all) {
  if ($all) {
    $classic = Select-Property $props 'MaxClassicPlatforms'
    $core    = Select-Property $props 'MaxCorePlatforms'
  }
  else {
    $classic = Select-Property $props 'MinClassicPlatforms'
    $core    = Select-Property $props 'MinCorePlatforms'
  }
  switch ($family) {
    'classic' { return $classic }
    'core'    { return $core }
    'any'     { return $core + $classic }
  }
}

function Get-Standards([Xml] $props) {
  Select-Property $props 'SupportedStandards'
}

function Get-TargetFrameworks([string[]] $platforms) {
  '/p:TargetFrameworks=\"' + ($platforms -join ';') + '\"'
}

# ------------------------------------------------------------------------------

try {
  $rootDir = (Get-Item $PSScriptRoot).Parent.FullName

  pushd $rootDir

  $props = Load-Properties (Join-Path $rootDir 'Directory.Build.props')
  $platforms = Get-Platforms $props $Family -All:$all
  $standards = Get-Standards $props

  $cmd = $Task.ToLowerInvariant()

  # NB: '/p:ContinuousIntegrationBuild=true' is implicit for CI build.
  $args = @('/p:ContinuousIntegrationBuild=true')
  if ($Runtime)   { $args += "-r:$Runtime" }
  if ($Verbosity) { $args += "-v:$Verbosity" }

  $params = "-c:$Configuration", '/p:Retail=true'

  switch ($cmd) {
    'restore' {
      $args   += '--configfile:NuGet.Config'
      $targets = $platforms + $standards
    }
    'build' {
      $args   += $params + '--no-restore' + '--version-suffix=ci'
      $targets = $platforms + $standards
    }
    'test' {
      $args   += $params + '--no-build'
      $targets = $platforms
    }
  }

  Write-Host "`ndotnet.exe is about to run using"
  Write-Host "  Command -> $cmd"
  Write-Host "  Args    -> $args"
  Write-Host "  Targets -> $targets`n"

  if (-not $DryRun) {
    $args += Get-TargetFrameworks $targets
    & dotnet $cmd $args
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
}

# ------------------------------------------------------------------------------

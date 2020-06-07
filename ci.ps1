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

# We extract the list of supported .NET Standards from the "build" and "pack" lists.
function Get-Standards([Xml] $props) {
  $standards = Select-Property $props 'PackPlatforms' |
    where { $_.StartsWith('netstandard') }
  $list = Select-Property $props 'BuildPlatforms' |
    where { $_.StartsWith('netstandard') }
  foreach ($item in $list) {
    if (-not $standards.Contains($item)) { $standards += $item }
  }
  $standards
}

function Get-TargetFrameworks([string[]] $platforms) {
  '/p:TargetFrameworks=\"' + ($platforms -join ';') + '\"'
}

# ------------------------------------------------------------------------------

try {
  pushd $PSScriptRoot

  $props = Load-Properties (Join-Path $PSScriptRoot 'Directory.Build.props')
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
      # We filter out platforms no longer supported by Xunit runners.
      $targets = $platforms | where { $_ -notin 'netcoreapp2.0', 'net451', 'net45' }
    }
  }

  if ($DryRun) {
    Write-Host "  Command -> $cmd"
    Write-Host "  Args    -> $args"
    Write-Host "  Targets -> $targets"
  } else {
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

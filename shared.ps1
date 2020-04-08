#Requires -Version 4.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Relative path
$PSScriptRoot | New-Variable -Name ROOT_DIR -Scope Script -Option Constant

(join-path $ROOT_DIR "src") `
  | New-Variable -Name SRC_DIR -Scope Script -Option Constant

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".
(join-path $ROOT_DIR "__") `
  | New-Variable -Name ARTIFACTS_DIR -Scope Script -Option Constant

################################################################################

function say-loud {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -BackgroundColor DarkCyan -ForegroundColor Green
}

function carp {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -ForegroundColor Yellow
}

function croak {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -BackgroundColor Red -ForegroundColor Yellow
  Exit 1
}

function confess {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -ForegroundColor Green
}

################################################################################

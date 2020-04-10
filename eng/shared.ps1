#Requires -Version 4.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Relative path
(get-item $PSScriptRoot).Parent.FullName `
  | New-Variable -Name ROOT_DIR -Scope Script -Option Constant

(join-path $ROOT_DIR "src") `
  | New-Variable -Name SRC_DIR -Scope Script -Option Constant

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".
(join-path $ROOT_DIR "__") `
  | New-Variable -Name ARTIFACTS_DIR -Scope Script -Option Constant

(join-path $ARTIFACTS_DIR "packages") `
  | New-Variable -Name PKG_DIR -Scope Script -Option Constant

################################################################################

<#
.SYNOPSIS
Print a message.
#>
function say {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message
}

<#
.SYNOPSIS
Say out loud a message; print it with emphasis.
#>
function say-loud {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -BackgroundColor DarkCyan -ForegroundColor Green
}

<#
.SYNOPSIS
Print a recap.
#>
function recap {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-host $Message -ForegroundColor Green
}

<#
.SYNOPSIS
Warn user.
#>
function carp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-warning $Message
}

<#
.SYNOPSIS
Die of errors.
#>
function croak {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message,

    [string] $StackTrace
  )

  # We don't write the message to the error stream (we use write-host not
  # write-error).
  write-host $Message -BackgroundColor Red -ForegroundColor Yellow

  if ($StackTrace -ne '') { write-host $StackTrace -ForegroundColor Yellow }
  exit 1
}

<#
.SYNOPSIS
Die if the exit code of the last external command that was run is not equal to zero.
#>
function on-lastcmderr {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  if ($LastExitCode -ne 0) { croak $Message }
}

################################################################################

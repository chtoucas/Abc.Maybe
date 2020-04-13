#Requires -Version 4.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

################################################################################

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".

# Root directory.
(Get-Item $PSScriptRoot).Parent.FullName `
  | New-Variable -Name "ROOT_DIR" -Scope Script -Option Constant

# Artifacts directory.
(Join-Path $ROOT_DIR "__") `
  | New-Variable -Name "ARTIFACTS_DIR" -Scope Script -Option Constant

# Engineering directory.
(Join-Path $ROOT_DIR "eng") `
  | New-Variable -Name "ENG_DIR" -Scope Script -Option Constant

# Source directory.
(Join-Path $ROOT_DIR "src") `
  | New-Variable -Name "SRC_DIR" -Scope Script -Option Constant

# Packages output directory.
(Join-Path $ARTIFACTS_DIR "packages") `
  | New-Variable -Name "PKG_OUTDIR" -Scope Script -Option Constant

################################################################################

# Print a message.
function Say {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  Write-Host $Message
}

# Say out loud a message; print it with emphasis.
function Say-Loud {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  Write-Host $Message -BackgroundColor DarkCyan -ForegroundColor Green
}

# Print a recap.
function Recap {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  Write-Host $Message -ForegroundColor Green
}

# Warn user.
function Carp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  write-warning $Message
}

# Die of errors.
function Croak {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $Message,

    [string] $StackTrace
  )

  # We don't write the message to the error stream (we use Write-Host not
  # Write-Error).
  Write-Host $Message -BackgroundColor Red -ForegroundColor Yellow

  if ($StackTrace -ne "") { Write-Host $StackTrace -ForegroundColor Yellow }
  exit 1
}

# Die if the exit code of the last external command that was run is not equal to zero.
function On-LastCmdErr {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  if ($LastExitCode -ne 0) { Croak $Message }
}

################################################################################

function Get-GitExe {
  [CmdletBinding()]
  param([switch] $Force)

  Write-Verbose "Finding the installed git command."

  $git = (Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue)

  if ($git -eq $null) {
    Write-Warning "Git could not be found in your PATH. Please ensure Git is installed."
    return $null
  }

  $exe = $git.Path

  $status = Get-GitStatus $exe

  if ($status -eq $null) {
    Write-Warning "Unabled to verify the git status."
    if (-not $Force) { return $null }
  }
  elseif ($status -ne "") {
    Write-Warning "Uncommitted changes are pending."
    if (-not $Force) { return $null }
  }

  $exe
}

function Get-GitStatus {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Git
  )

  Write-Verbose "Getting the git status."

  $status = $null

  try {
    Write-Debug "Calling git.exe status."
    $status = & $git status -s 2>&1

    if ($status -eq $null) {
      $status = ""
    }
  }
  catch {
    Write-Warning "Git command failed: $_"
  }

  $status
}

function Get-GitCommitHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Git
  )

  Write-Verbose "Getting the last git commit hash."

  $hash = ""

  try {
    Write-Debug "Calling git.exe log."
    $hash = & $git log -1 --format="%H" 2>&1
  }
  catch {
    Write-Warning "Git command failed: $_"
  }

  $hash
}

function Get-GitBranch {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Git
  )

  Write-Verbose "Getting the git branch."

  $branch = ""

  try {
    Write-Debug "Calling git.exe rev-parse."
    $branch = & $git rev-parse --abbrev-ref HEAD 2>&1
  }
  catch {
    Write-Warning "Git command failed: $_"
  }

  $branch
}

################################################################################


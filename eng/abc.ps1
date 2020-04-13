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
  | New-Variable -Name "ROOT_DIR" -Scope Local -Option Constant

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

# Reporting.
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
function Write-Recap {
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

  Write-Warning $Message
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

# Helpers.
################################################################################

function Approve-ProjectRoot {
    [CmdletBinding()]
    param()

    if (![System.IO.Path]::IsPathRooted($ROOT_DIR)) {
        Croak "The path MUST be absolute."
    }

    if (!(Test-Path $ROOT_DIR)) {
        Croak "The path does NOT exist."
    }

    return $ROOT_DIR
}

# Requests confirmation from the user.
function Confirm-Yes {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Question
  )

  while ($true) {
    $answer = (Read-Host $Question, "[y/N]")

    if ($answer -eq "" -or $answer -eq "n") {
      return $false
    }
    elseif ($answer -eq "y") {
      return $true
    }
  }
}

function Confirm-Continue {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Question
  )

  while ($true) {
    $answer = (Read-Host $Question, "[y/N]")

    if ($answer -eq "" -or $answer -eq "n") {
      Write-Recap "Stopping on user request."
      exit 0
    }
    elseif ($answer -eq "y") {
      break
    }
  }
}

# Die if the exit code of the last external command that was run is not equal to zero.
function Assert-CmdSuccess {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $ErrMessage
  )

  if ($LastExitCode -ne 0) { Croak $ErrMessage }
}

# Git-related functions.
################################################################################

# Find the path to the system git command.
function Find-GitExe {
  [CmdletBinding()]
  param([switch] $Force)

  Write-Verbose "Finding the installed git command."

  $git = (Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue)

  if ($git -eq $null) {
    Carp "Git could not be found in your PATH. Please ensure Git is installed."
    return $null
  }

  $exe = $git.Path

  $status = Get-GitStatus $exe

  if ($status -eq $null) {
    Carp "Unabled to verify the git status."
    if (-not $Force) { return $null }
  }
  elseif ($status -ne "") {
    Carp "Uncommitted changes are pending."
    if (-not $Force) { return $null }
  }

  $exe
}

# Get the git status.
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
    $status = & $git status -s 2>&1

    if ($status -eq $null) {
      $status = ""
    }
  }
  catch {
    Carp "Git command failed: $_"
  }

  $status
}

# Get the last git commit hash of the local repository.
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
    $hash = & $git log -1 --format="%H" 2>&1
  }
  catch {
    Carp "Git command failed: $_"
  }

  $hash
}

# Get the git branch of the local repository.
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
    $branch = & $git rev-parse --abbrev-ref HEAD 2>&1
  }
  catch {
    Carp "Git command failed: $_"
  }

  $branch
}

################################################################################


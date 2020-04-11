#Requires -Version 4.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
    [string] $Git,

    [switch] $Abbrev
  )

  Write-Verbose "Getting the last git commit hash."

  if ($Abbrev.IsPresent) {
    $fmt = '%h'
  }
  else {
    $fmt = '%H'
  }

  $hash = ""

  try {
    Write-Debug "Calling git.exe log."
    $hash = & $git log -1 --format="$fmt" 2>&1
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

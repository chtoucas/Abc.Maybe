#Requires -Version 4.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

################################################################################
#region Project-specific constants.

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".

# Root directory.
(Get-Item $PSScriptRoot).Parent.FullName `
    | New-Variable -Name "ROOT_DIR" -Scope Local -Option Constant

# Engineering directory.
(Join-Path $ROOT_DIR "eng" -Resolve) `
    | New-Variable -Name "ENG_DIR" -Scope Script -Option Constant

# Source directory.
(Join-Path $ROOT_DIR "src" -Resolve) `
    | New-Variable -Name "SRC_DIR" -Scope Script -Option Constant

# Test directory.
(Join-Path $ROOT_DIR "test" -Resolve) `
    | New-Variable -Name "TEST_DIR" -Scope Script -Option Constant

# Artifacts directory. Be careful with -Resolve, dir does not necessary exist.
(Join-Path $ROOT_DIR "__" -Resolve) `
    | New-Variable -Name "ARTIFACTS_DIR" -Scope Script -Option Constant
# Packages.
(Join-Path $ARTIFACTS_DIR "packages") `
    | New-Variable -Name "PKG_OUTDIR" -Scope Script -Option Constant
# CI packages.
(Join-Path $ARTIFACTS_DIR "packages-ci") `
    | New-Variable -Name "PKG_CI_OUTDIR" -Scope Script -Option Constant
# Local NuGet feed.
(Join-Path $ARTIFACTS_DIR "nuget-feed") `
    | New-Variable -Name "NUGET_LOCAL_FEED" -Scope Script -Option Constant
# Local NuGet cache.
(Join-Path $ARTIFACTS_DIR "nuget-cache" -Resolve) `
    | New-Variable -Name "NUGET_LOCAL_CACHE" -Scope Script -Option Constant

# ------------------------------------------------------------------------------

function Approve-RepositoryRoot {
    if (-not [System.IO.Path]::IsPathRooted($ROOT_DIR)) {
        Croak "The root path MUST be absolute."
    }
}

#endregion
################################################################################
#region Reporting.

# Print a message.
function Say {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [switch] $NoNewline
    )

    Write-Host $Message -NoNewline:$NoNewline.IsPresent
}

# Say out loud a message; print it with emphasis.
function Say-Loud {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    Write-Host $Message -BackgroundColor DarkCyan -ForegroundColor Green
}

function Chirp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

  Write-Host $Message -ForegroundColor Green
}

# Warn user.
function Carp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

  Write-Warning $Message
}

# Die of errors.
function Croak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    # We don't write the message to the error stream (we use Write-Host not
    # Write-Error).
    Write-Host $Message -BackgroundColor Red -ForegroundColor Yellow
    exit 1
}

#endregion
################################################################################
#region Misc helpers.

# Request confirmation to continue.
function Confirm-Yes {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Question
    )

    while ($true) {
        $answer = (Read-Host $Question, '[y/N]')

        if ($answer -eq "" -or $answer -eq "n") {
            Say "  Discarding on your request."
            return $false
        }
        elseif ($answer -eq "y") {
            return $true
        }
    }
}

# Request confirmation to continue.
function Confirm-Continue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Question
    )

    while ($true) {
        $answer = (Read-Host $Question, "[y/N]")

        if ($answer -eq "" -or $answer -eq "n") {
            Say "  Stopping on your request."
            exit 0
        }
        elseif ($answer -eq "y") {
            break
        }
    }
}

# ------------------------------------------------------------------------------

# Die if the exit code of the last external command that was run is not equal to zero.
function Assert-CmdSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ErrMessage
    )

    if ($LastExitCode -ne 0) { Croak $ErrMessage }
}

# ------------------------------------------------------------------------------

function Remove-BinAndObj {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('p')] [string[]] $PathList
    )

    Write-Verbose "Removing 'bin' and 'obj' directories."

    $PathList | %{
        if (-not (Test-Path $_)) {
            Carp "Ignoring '$_'; the path does NOT exist."
            return
        }
        if (-not [System.IO.Path]::IsPathRooted($_)) {
            Carp "Ignoring '$_'; the path MUST be absolute."
            return
        }

        Write-Verbose "Processing directory '$_'."

        ls $_ -Include bin,obj -Recurse | ?{
            Write-Verbose "Deleting '$_'."

            rm $_.FullName -Force -Recurse
        }
    }
}

#endregion
################################################################################
#region Git-related functions.

# Find the path to the system git command.
function Find-GitExe {
    [CmdletBinding()]
    param()

    Write-Verbose "Finding the system git command."

    $git = Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($git -eq $null) {
        Carp "Git could not be found in your PATH. Please ensure Git is installed."
        return $null
    }

    $git.Path
}

# ------------------------------------------------------------------------------

# Verify that there are no pending changes.
function Approve-GitStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git
    )

    Write-Verbose "Getting the git status."

    try {
        # If there no uncommitted changes, the result is null, not empty.
        $status = & $Git status -s 2>&1

        if ($status -eq $null) {
            return $true
        }
        else {
            Carp "Uncommitted changes are pending."
            return $false
        }
    }
    catch {
        Carp "Git status failed: $_"
    }
}

# Get the last git commit hash.
function Get-GitCommitHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git
    )

    Write-Verbose "Getting the last git commit hash."

    try {
        return & $Git log -1 --format="%H" 2>&1
    }
    catch {
        Carp "Git log failed: $_"
    }
}

# Get the current git branch.
function Get-GitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git
    )

    Write-Verbose "Getting the git branch."

    try {
        return & $Git rev-parse --abbrev-ref HEAD 2>&1
    }
    catch {
        Carp "Git rev-parse failed: $_"
    }
}

#endregion
################################################################################
#region VS-related functions.

# & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -?
# https://aka.ms/vs/workloads for a list of workload (-requires)
function Find-VsWhere {
    Write-Verbose "Finding the vswhere command."

    $vswhere = Get-Command "vswhere.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($vswhere -ne $null) {
        return $vswhere.Path
    }

    Write-Verbose "vswhere.exe could not be found in your PATH."

    $path = "${ENV:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $path) {
        return $path
    }
    else {
        Croak "Could not find vswhere."
    }
}

# ------------------------------------------------------------------------------

function Find-MSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $vswhere
    )
    Write-Verbose "Finding MSBuild."

    $exe = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1

    if (-not $exe) {
        Croak "Could not find MSBuild."
    }

    $exe
}

function Find-Fsi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $vswhere
    )
    Write-Verbose "Finding fsi.exe."

    $vspath = & $vswhere -legacy -latest -property installationPath

    $path = "$vspath\Common7\IDE\CommonExtensions\Microsoft\FSharp\fsi.exe"
    if (Test-Path $path) {
        return $path
    }
    else {
        Croak "Could not find vswhere."
    }
}

#endregion
################################################################################

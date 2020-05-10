# See LICENSE in the project root for license information.

# Version 5.1 for ErrorRecord.
#Requires -Version 5.1

Set-StrictMode -Version Latest

################################################################################
#region Say something.

function Hello {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    Write-Host "Hello, $message" -ForegroundColor Magenta -NoNewline:$noNewline
}

# ------------------------------------------------------------------------------

function say {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    Write-Host $message -NoNewline:$noNewline
}

# ------------------------------------------------------------------------------

function say-softly {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    Write-Host $message -ForegroundColor Cyan -NoNewline:$noNewline
}

# ------------------------------------------------------------------------------

function SAY-LOUDLY {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    Write-Host $message -ForegroundColor Green -NoNewline:$noNewline
}

#endregion
################################################################################
#region Warn or die.

$Script:___ExitCode = 0

# ------------------------------------------------------------------------------

# Warn user.
function die {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int] $exitCode = 1
    )

    $Script:___ExitCode = $exitCode

    exit $exitCode
}

# ------------------------------------------------------------------------------

# Warn user.
function carp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    Write-Warning $message
}

# ------------------------------------------------------------------------------

# Die of errors.
# Not seen as a terminating error, it does not set $?.
function croak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    $Host.UI.WriteErrorLine($message)

    die
}

# ------------------------------------------------------------------------------

# Die of errors with stack trace.
function confess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.ErrorRecord] $error
    )

    $Host.UI.WriteErrorLine("An unexpected error occurred.")

    if ($error -ne $null) {
        $Host.UI.WriteErrorLine($error.ScriptStackTrace.ToString())

        $Script:___ExitCode = 255

        # Write a terminating error.
        # This will be displayed as a post-mortem stack trace.
        $PSCmdlet.WriteError($error)
    }
    else {
        $Host.UI.WriteErrorLine("Sorry, no further details on the error were given.")
    }

    die 255
}

# ------------------------------------------------------------------------------

# Die if the exit code of the last external command that was run is not equal to zero.
function Assert-CmdSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $error,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $success = ""
    )

    Write-Verbose "Checking exit code of the last external command that was run."

    if ($LastExitCode -ne 0) { croak $error }

    if ($success -ne "") { say-softly $success }
}

#endregion
################################################################################
#region Confirm or not.

# Request confirmation.
function Confirm-Yes {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $question
    )

    while ($true) {
        $answer = (Read-Host $question, "[y/N/q]")

        if ($answer -eq "" -or $answer -eq "n") {
            say-softly "Discarding on your request."
            return $false
        }
        elseif ($answer -eq "y") {
            return $true
        }
        elseif ($answer -eq "q") {
            say-softly "Aborting the script on your request."
            exit
        }
    }
}

# ------------------------------------------------------------------------------

# Request confirmation to continue, terminate the script if not.
function Confirm-Continue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $question
    )

    while ($true) {
        $answer = (Read-Host $question, "[y/N]")

        if ($answer -eq "" -or $answer -eq "n") {
            say-softly "Stopping on your request."
            exit
        }
        elseif ($answer -eq "y") {
            break
        }
    }
}

#endregion
################################################################################
#region FileSystem-related functions.

function Remove-Dir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $path
    )

    Write-Verbose "Deleting directory ""$path""."

    if (-not (Test-Path $path)) {
        Write-Verbose "Skipping ""$path""; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        carp "Skipping ""$path""; the path MUST be absolute."
        return
    }

    Remove-Item $path -Recurse
}

# ------------------------------------------------------------------------------

function Remove-Packages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $path
    )

    Write-Verbose "Deleting NuGet packages in ""$path""."

    if (-not (Test-Path $path)) {
        Write-Verbose "Skipping ""$path""; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        carp "Skipping ""$path""; the path MUST be absolute."
        return
    }

    ls $path -Include "*.nupkg" -Recurse | ?{
        Write-Verbose "Deleting ""$_""."

        Remove-Item $_.FullName
    }
}

# ------------------------------------------------------------------------------

function Remove-BinAndObj {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [string[]] $pathList
    )

    Write-Verbose "Deleting ""bin"" and ""obj"" directories."

    $pathList | %{
        if (-not (Test-Path $_)) {
            Write-Verbose "Skipping ""$_""; the path does NOT exist."
            return
        }
        if (-not [System.IO.Path]::IsPathRooted($_)) {
            carp "Skipping ""$_""; the path MUST be absolute."
            return
        }

        Write-Verbose "Processing directory ""$_""."

        ls $_ -Include bin,obj -Recurse | ?{
            Write-Verbose "Deleting ""$_""."

            Remove-Item $_.FullName -Recurse
        }
    }
}

#endregion
################################################################################
#region Git-related functions.

function Find-Git {
    [CmdletBinding()]
    param(
        [switch] $exitOnError
    )

    Write-Verbose "Finding git.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    $cmd = Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($cmd -eq $null) {
        . $onError "Could not find git.exe. Please ensure git.exe is installed."

        return $null
    }

    $path = $cmd.Path

    Write-Verbose "git.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

# Verify that there are no pending changes.
function Approve-GitStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $git,

        [switch] $exitOnError
    )

    Write-Verbose "Getting the git status."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    try {
        # If there no uncommitted changes, the result is null, not empty.
        $status = & $git status -s 2>&1

        if ($status -eq $null) { return $true }

        . $onError "Uncommitted changes are pending."
    }
    catch {
        . $onError """git status"" failed: $_"
    }

    return $false
}

# ------------------------------------------------------------------------------

# Get the last git commit hash.
function Get-GitCommitHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $git,

        [switch] $exitOnError
    )

    Write-Verbose "Getting the last git commit hash."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    try {
        $commit = & $git log -1 --format="%H" 2>&1

        Write-Verbose "Current git commit hash: ""$commit""."

        return $commit
    }
    catch {
        . $onError """git log"" failed: $_"

        return ""
    }
}

# ------------------------------------------------------------------------------

# Get the current git branch.
function Get-GitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $git,

        [switch] $exitOnError
    )

    Write-Verbose "Getting the git branch."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    try {
        $branch = & $git rev-parse --abbrev-ref HEAD 2>&1

        Write-Verbose "Current git branch: ""$branch""."

        return $branch
    }
    catch {
        . $onError """git rev-parse"" failed: $_"

        return ""
    }
}

#endregion
################################################################################
#region VS-related functions.

# Returns $null if the package is not referenced.
function Get-PackageReferenceVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $package
    )

    Write-Verbose "Getting version for ""$package"" from ""$projectPath""."

    [Xml] (Get-Content $projectPath) `
        | Select-Xml -XPath "//Project/ItemGroup/PackageReference[@Include='$package']" `
        | select -ExpandProperty Node `
        | select -First 1 -ExpandProperty Version
}

# ------------------------------------------------------------------------------

# & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -?
# https://aka.ms/vs/workloads for a list of workload (-requires)
function Find-VsWhere {
    [CmdletBinding()]
    param(
        [switch] $exitOnError
    )

    Write-Verbose "Finding vswhere.exe."

    $cmd = Get-Command "vswhere.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue
    if ($cmd -ne $null) { return $cmd.Path }

    Write-Verbose "vswhere.exe could not be found in your PATH."

    $path = Join-Path ${Env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $path) {
        Write-Verbose "vswhere.exe found here: ""$path""."

        return $path
    }
    else {
        if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

        . $onError "Could not find vswhere.exe."

        return $null
    }
}

# ------------------------------------------------------------------------------

function Find-MSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string] $vswhere,

        [switch] $exitOnError
    )

    Write-Verbose "Finding MSBuild.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    if (-not $vswhere) {
        $cmd = Get-Command "MSBuild.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

        if ($cmd -ne $null) { return $cmd.Path }
        else { . $onError "MSBuild.exe could not be found in your PATH." ; return $null }
    }
    else {
        $path = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe `
            | select-object -first 1

        if ($path) { Write-Verbose "MSBuild.exe found here: ""$path""." ;  return $path }
        else { . $onError "Could not find MSBuild.exe." ; return $null }
    }
}

# ------------------------------------------------------------------------------

function Find-Fsi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string] $vswhere,

        [switch] $exitOnError
    )

    Write-Verbose "Finding fsi.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    if (-not $vswhere) {
        $cmd = Get-Command "fsi.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

        if ($cmd -ne $null) { return $cmd.Path }
        else { . $onError "fsi.exe could not be found in your PATH." ; return $null }
    }
    else {
        $vspath = & $vswhere -legacy -latest -property installationPath

        $path = Join-Path $vspath "\Common7\IDE\CommonExtensions\Microsoft\FSharp\fsi.exe"
        if (Test-Path $path) { Write-Verbose "fsi.exe found here: ""$path""." ; return $path }
        else { . $onError "Could not find fsi.exe." ; return $null }
    }
}

#endregion
################################################################################

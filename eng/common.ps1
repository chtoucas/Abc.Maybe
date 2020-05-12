# See LICENSE in the project root for license information.

#Requires -Version 5.1

New-Alias "my"      New-Variable
New-Alias "say"     Write-Host
New-Alias "diag"    Write-Debug
New-Alias "confess" Write-Verbose
New-Alias "whereis" Get-Command

New-Alias "const"   New-Constant
New-Alias "yesno"   Confirm-Yes
New-Alias "guard"   Confirm-Continue

################################################################################

function New-Constant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $name,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object] $value
    )

    New-Variable -Name $name -Value $value -Scope Script -Option Constant
}

################################################################################
#region Warn or die (inspired by Perl).

$Script:___Warned = $false
$Script:___Died   = $false

# ------------------------------------------------------------------------------

# Warn user.
function warn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    $Script:___Warned = $true

    Write-Warning $message
}

# ------------------------------------------------------------------------------

# Die of errors.
# Not seen as a terminating error, it does not set $?.
function die {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    $Script:___Died = $true

    $Host.UI.WriteErrorLine($message)

    exit 1
}

# ------------------------------------------------------------------------------

# Warn user (from perspective of caller).
function carp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    $Script:___Warned = $true

    # The first element is for "carp", let's remove it.
    $x, $callstack = Get-PSCallStack
    $msg = $message + "`n  " + ($callstack -join "`n  ")

    Write-Warning $msg
}

# ------------------------------------------------------------------------------

# Die of errors (from perspective of caller).
# Not seen as a terminating error, it does not set $?.
function croak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    $Script:___Died = $true

    # The first element is for "croak", let's remove it.
    $x, $callstack = Get-PSCallStack
    $msg = $message + "`n  " + ($callstack -join "`n  ")

    $Host.UI.WriteErrorLine($msg)

    exit 1
}

#endregion
################################################################################
#region UI.

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
            say "Discarded on your request." -ForegroundColor DarkCyan
            return $false
        }
        elseif ($answer -eq "y") {
            return $true
        }
        elseif ($answer -eq "q") {
            say "Aborting the script on your request." -ForegroundColor DarkCyan
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
            say "Stopping on your request." -ForegroundColor DarkCyan
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

    confess "Deleting directory ""$path""."

    if (-not (Test-Path $path)) {
        confess "Skipping ""$path""; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        carp "Skipping ""$path""; the path MUST be absolute."
        return
    }

    rm $path -Recurse
}

# ------------------------------------------------------------------------------

function Remove-BinAndObj {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [string] $path
    )

    confess "Deleting ""bin"" and ""obj"" directories within ""$path""."

    if (-not (Test-Path $path)) {
        confess "Skipping ""$path""; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        carp "Skipping ""$path""; the path MUST be absolute."
        return
    }

    ls $path -Include bin,obj -Recurse `
        | % { confess "Deleting ""$_""." ; rm $_.FullName -Recurse }
}

#endregion
################################################################################
#region Git-related functions.

function Find-Git {
    [CmdletBinding()]
    param(
        [switch] $exitOnError
    )

    confess "Finding git.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    $cmd = whereis "git.exe" -CommandType Application -TotalCount 1 -ErrorAction Ignore

    if ($cmd -eq $null) {
        . $onError "Could not find git.exe. Please ensure git.exe is installed."

        return $null
    }

    $path = $cmd.Path

    confess "git.exe found here: ""$path""."

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

    confess "Getting the git status."

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

    confess "Getting the last git commit hash."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    try {
        $commit = & $git log -1 --format="%H" 2>&1

        confess "Current git commit hash: ""$commit""."

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

    confess "Getting the git branch."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    try {
        $branch = & $git rev-parse --abbrev-ref HEAD 2>&1

        confess "Current git branch: ""$branch""."

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

    confess "Getting version for ""$package"" from ""$projectPath""."

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

    confess "Finding vswhere.exe."

    $cmd = whereis "vswhere.exe" -CommandType Application -TotalCount 1 -ErrorAction Ignore
    if ($cmd -ne $null) { return $cmd.Path }

    confess "vswhere.exe could not be found in your PATH."

    $path = Join-Path ${Env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"

    if (Test-Path $path) {
        confess "vswhere.exe found here: ""$path""."

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

    confess "Finding MSBuild.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    if (-not $vswhere) {
        $cmd = whereis "MSBuild.exe" -CommandType Application -TotalCount 1 -ErrorAction Ignore

        if ($cmd) { return $cmd.Path }
        else { . $onError "MSBuild.exe could not be found in your PATH." ; return $null }
    }
    else {
        $path = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe `
            | select-object -first 1

        if ($path) { confess "MSBuild.exe found here: ""$path""." ;  return $path }
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

    confess "Finding fsi.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    if (-not $vswhere) {
        $cmd = whereis "fsi.exe" -CommandType Application -TotalCount 1 -ErrorAction Ignore

        if ($cmd) { return $cmd.Path }
        else { . $onError "fsi.exe could not be found in your PATH." ; return $null }
    }
    else {
        $vspath = & $vswhere -legacy -latest -property installationPath
        $path = Join-Path $vspath "\Common7\IDE\CommonExtensions\Microsoft\FSharp\fsi.exe"

        if (Test-Path $path) { confess "fsi.exe found here: ""$path""." ; return $path }
        else { . $onError "Could not find fsi.exe." ; return $null }
    }
}

#endregion
################################################################################

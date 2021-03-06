# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2019 Narvalo.Org. All rights reserved.

using namespace Microsoft.PowerShell.Commands

New-Alias "say"        Write-Host
New-Alias "___debug"   Write-Debug
New-Alias "___confess" Write-Verbose

New-Alias "const"      New-Constant
New-Alias "readonly"   New-ReadOnly
New-Alias "yesno"      Confirm-Yes
New-Alias "guard"      Confirm-Continue
New-Alias "whereis"    Find-SingleExe

################################################################################
#region Core functions.

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

# ------------------------------------------------------------------------------

function New-ReadOnly {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $name,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object] $value
    )

    New-Variable -Name $name -Value $value -Scope Script -Option ReadOnly
}

# ------------------------------------------------------------------------------

function Find-SingleExe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $name
    )

    ___confess "Finding $name in your PATH."

    $exe = Get-Command $name -CommandType Application -TotalCount 1 -ErrorAction Ignore
    if (-not $exe) { return ___debug "Could not find $name in your PATH." }

    $path = $exe.Path

    ___debug "$name found here: ""$path""."

    $path
}

#endregion
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

# Warn user or die of errors (from perspective of caller).
function carp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $exitOnError
    )

    # The first element is for "carp", and the last one is useless, let's remove them.
    $stack = Get-PSCallStack
    $c = $stack.Count
    if ($c -gt 2)     { $message += "`n  " + ($stack[1..($c-2)] -join "`n  ") }
    elseif ($c -eq 2) { $message += "`n  " + $stack[1] }

    if ($exitOnError) {
        $Script:___Died = $true

        $Host.UI.WriteErrorLine($message)

        exit 1
    }
    else {
        $Script:___Warned = $true

        Write-Warning $message
    }
}

# ------------------------------------------------------------------------------

# Die of errors (from perspective of caller).
function croak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    $Script:___Died = $true

    # The first element is for "croak", and the last one is useless, let's remove them.
    $stack = Get-PSCallStack
    $c = $stack.Count
    if ($c -gt 2)     { $message += "`n  " + ($stack[1..($c-2)] -join "`n  ") }
    elseif ($c -eq 2) { $message += "`n  " + $stack[1] }

    $Host.UI.WriteErrorLine($message)

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

    ___confess "Deleting directory ""$path""."

    if (-not (Test-Path $path)) {
        return ___debug "Skipping ""$path""; the file does NOT exist."
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        return carp "Skipping ""$path""; the path MUST be absolute."
    }

    rm $path -Recurse
}

# ------------------------------------------------------------------------------

function Remove-BinAndObj {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $path
    )

    ___confess "Deleting ""bin"" and ""obj"" directories within ""$path""."

    if (-not (Test-Path $path)) {
        return ___debug "Skipping ""$path""; the file does NOT exist."
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        return carp "Skipping ""$path""; the path MUST be absolute."
    }

    ls $path -Include bin,obj -Recurse `
        | foreach { ___debug "Deleting ""$_""." ; rm $_.FullName -Recurse }
}

#endregion
################################################################################
#region Git-related functions.

# Verify that there are no pending changes.
function Approve-GitStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $git,

        [switch] $exitOnError
    )

    ___confess "Getting the git status."

    try {
        # If there no uncommitted changes, the result is null, not empty.
        $status = & $git status -s 2>&1

        if ($status -eq $null) { return $true }

        carp "Uncommitted changes are pending." -ExitOnError:$exitOnError
    }
    catch {
        carp """git status"" failed: $_" -ExitOnError:$exitOnError
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

    ___confess "Getting the last git commit hash."

    try {
        $commit = & $git log -1 --format="%H" 2>&1

        ___debug "Current git commit hash: ""$commit""."

        return $commit
    }
    catch {
        carp """git log"" failed: $_" -ExitOnError:$exitOnError

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

    ___confess "Getting the git branch."

    try {
        $branch = & $git rev-parse --abbrev-ref HEAD 2>&1

        ___debug "Current git branch: ""$branch""."

        return $branch
    }
    catch {
        carp """git rev-parse"" failed: $_" -ExitOnError:$exitOnError

        return ""
    }
}

#endregion
################################################################################
#region VS-related functions.

function Get-PackageReferenceVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $package,

        [switch] $exitOnError
    )

    ___confess "Getting version for ""$package"" from ""$projectPath""."

    [SelectXmlInfo[]] $nodes = [Xml] (Get-Content $projectPath) `
        | Select-Xml -XPath "//Project/ItemGroup/PackageReference[@Include='$package']"

    if ($nodes.Count -ne 1) {
        return carp """$package"" is not referenced in ""$projectPath""." `
            -ExitOnError:$exitOnError
    }

    $nodes[0].Node.Version.Trim()
}

# ------------------------------------------------------------------------------

# & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -?
# https://aka.ms/vs/workloads for a list of workload (-requires)
function Find-VsWhere {
    [CmdletBinding()]
    param(
        [switch] $exitOnError
    )

    ___confess "Finding vswhere.exe."

    if ($exe = whereis "vswhere.exe") { return $exe }

    $path = Join-Path ${Env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"

    if (-not (Test-Path $path)) {
        return carp "Could not find vswhere.exe." -ExitOnError:$exitOnError
    }

    ___debug "vswhere.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

function Find-MSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $vswhere,

        [switch] $exitOnError
    )

    ___confess "Finding MSBuild.exe."

    # NB: vswhere.exe does not produce proper exit codes.
    $path = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe `
        | select -First 1

    if (-not (Test-Path $path)) {
        return carp "Could not find MSBuild.exe." -ExitOnError:$exitOnError
    }

    ___debug "MSBuild.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

function Find-Fsi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $vswhere,

        [switch] $exitOnError
    )

    ___confess "Finding fsi.exe using vswhere.exe."

    # NB: vswhere.exe does not produce proper exit codes.
    $vspath = & $vswhere -legacy -latest -property installationPath

    ___debug "VS Installation Path = ""$vspath""."

    $path = Join-Path $vspath "\Common7\IDE\CommonExtensions\Microsoft\FSharp\fsi.exe"

    if (-not (Test-Path $path)) {
        return carp "Could not find fsi.exe." -ExitOnError:$exitOnError
    }

    ___debug "fsi.exe found here: ""$path""."

    $path
}

#endregion
################################################################################

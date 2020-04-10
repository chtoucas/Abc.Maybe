#Requires -Version 4.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

################################################################################

<#
.SYNOPSIS
    Get the path to the system git command.
.INPUTS
    None.
.OUTPUTS
    System.String. Get-GitExe returns a string that contains the path to the git
    command or $null if git is nowhere to be found.
#>
function Get-GitExe {
    [CmdletBinding()]
    param()

    Write-Verbose 'Finding the installed git command.'

    $git = (Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue)

    if ($git -eq $null) {
        return $null
    }
    else {
        return $git.Path
    }
}

<#
.SYNOPSIS
    Get the last git commit hash of the local repository.
.PARAMETER Git
    Specifies the path to the Git executable.
.PARAMETER Abbrev
    If present, returns the abbreviated commit hash.
.INPUTS
    The path to the Git executable.
.OUTPUTS
    System.String. Get-GitCommitHash returns a string that contains the git
    commit hash.
.NOTES
    If anything fails, returns an empty string.
#>
function Get-GitCommitHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git,

        [switch] $Abbrev
    )

    Write-Verbose 'Getting the last git commit hash.'

    if ($Abbrev.IsPresent) {
        $fmt = '%h'
    }
    else {
        $fmt = '%H'
    }

    $hash = ''

    try {
        Write-Debug 'Calling git.exe log.'
        $hash = . $git log -1 --format="$fmt" 2>&1
    } catch {
        Write-Warning "Git command failed: $_"
    }

    $hash
}

<#
.SYNOPSIS
    Get the git status.
.PARAMETER Git
    Specifies the path to the Git executable.
.INPUTS
    The path to the Git executable.
.OUTPUTS
    System.String. Get-GitStatus returns a string that contains the git status.
.NOTES
    If anything fails, returns $null.
#>
function Get-GitStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git
    )

    Write-Verbose 'Getting the git status.'

    $status = $null

    try {
        Write-Debug 'Calling git.exe status.'
        $status = . $git status -s 2>&1

        if ($status -eq $null) {
            $status = ''
        }
    } catch {
        Write-Warning "Git command failed: $_"
    }

    $status
}

################################################################################

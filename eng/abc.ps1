#Requires -Version 4.0

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
(Join-Path $ARTIFACTS_DIR "nuget-feed" -Resolve) `
    | New-Variable -Name "NUGET_LOCAL_FEED" -Scope Script -Option Constant
# Local NuGet cache.
(Join-Path $ARTIFACTS_DIR "nuget-cache") `
    | New-Variable -Name "NUGET_LOCAL_CACHE" -Scope Script -Option Constant

# ------------------------------------------------------------------------------

function Approve-RepositoryRoot {
    [CmdletBinding()]
    param()

    Write-Verbose "Approving repository root."

    if (-not [System.IO.Path]::IsPathRooted($ROOT_DIR)) {
        Croak "The root path MUST be absolute."
    }
}

#endregion
################################################################################
#region Project-specific helpers.

function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectName,

        [switch] $AsString
    )

    Write-Verbose "Getting package version."

    $proj = Join-Path $ENG_DIR "$ProjectName.props" -Resolve

    $xml = [Xml] (Get-Content $proj)
    $node = (Select-Xml -Xml $xml -XPath "//Project/PropertyGroup/MajorVersion/..").Node

    $major = $node | Select -First 1 -ExpandProperty MajorVersion
    $minor = $node | Select -First 1 -ExpandProperty MinorVersion
    $patch = $node | Select -First 1 -ExpandProperty PatchVersion
    $precy = $node | Select -First 1 -ExpandProperty PreReleaseCycle
    $preno = $node | Select -First 1 -ExpandProperty PreReleaseNumber

    if ($AsString) {
        if ($precy -eq "") {
            return "$major.$minor.$patch"
        }
        else {
            return "$major.$minor.$patch-$precy$preno"
        }
    }
    else {
        @($major, $minor, $patch, $precy, $preno)
    }
}

# ------------------------------------------------------------------------------

function Reset-SourceTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $Yes
    )

    Write-Verbose "Resetting source tree."

    if ($Yes -or (Confirm-Yes "Hard clean the directory ""src""?")) {
        Say-Indent "Deleting ""bin"" and ""obj"" directories within ""src""."
        Remove-BinAndObj $SRC_DIR
    }
}

# ------------------------------------------------------------------------------

function Reset-TestTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $Yes
    )

    Write-Verbose "Resetting test tree."

    if ($Yes -or (Confirm-Yes "Hard clean the directory ""test""?")) {
        Say-Indent "Deleting ""bin"" and ""obj"" directories within ""test""."
        Remove-BinAndObj $TEST_DIR
    }
}

# ------------------------------------------------------------------------------

function Reset-PackageOutDir {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $Yes
    )

    Write-Verbose "Resetting output directory for packages."

    if ($Yes -or (Confirm-Yes "Reset output directory for packages?")) {
        Say-Indent "Clearing output directory for packages."
        Remove-Packages $PKG_OUTDIR
    }
}

# ------------------------------------------------------------------------------

function Reset-PackageCIOutDir {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $Yes
    )

    Write-Verbose "Resetting output directory for CI packages."

    if ($Yes -or (Confirm-Yes "Reset output directory for CI packages?")) {
        Say-Indent "Clearing output directory for CI packages."
        Remove-Packages $PKG_CI_OUTDIR
    }
}

# ------------------------------------------------------------------------------

function Reset-LocalNuGet {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $Yes
    )

    Write-Verbose "Resetting local NuGet feed/cache."

    if ($Yes -or (Confirm-Yes "Reset local NuGet feed/cache?")) {
        # When we reset the NuGet feed, better to clear the cache too, this is
        # not mandatory but it keeps cache and feed in sync.
        # The inverse is also true.
        # If we clear the cache but don't reset the feed, things will continue
        # to work but packages from the local NuGet feed will then be restored
        # to the global cache, exactly what we wanted to avoid.

        # We can't delete the directory, otherwise "dotnet restore" will fail.
        Say-Indent "Resetting local NuGet feed."
        Remove-Packages $NUGET_LOCAL_FEED

        # "dotnet restore" will recreate the directory if needed.
        Say-Indent "Clearing local NuGet cache."
        Remove-Dir $NUGET_LOCAL_CACHE
    }
}

# ------------------------------------------------------------------------------

function Remove-PackageFromLocalNuGet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $projectName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version
    )

    Indent "Removing obsolete package data from local NuGet feed/cache."

    $cacheEntry = Join-Path $projectName.ToLower() $version
    Remove-Dir (Join-Path $NUGET_LOCAL_CACHE $cacheEntry)

    $oldFilename = "$projectName.$version.nupkg"
    rm -Force (Join-Path $NUGET_LOCAL_FEED $oldFilename)
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

# ------------------------------------------------------------------------------

# Print an indented (2 spaces) message.
function Say-Indent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [switch] $NoNewline
    )

    Write-Host "  $Message" -NoNewline:$NoNewline.IsPresent
}

# ------------------------------------------------------------------------------

# Say out loud a message; print it with emphasis.
function Say-Loud {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [switch] $NoNewline
    )

    Write-Host $Message -BackgroundColor DarkCyan -ForegroundColor Green -NoNewline:$NoNewline.IsPresent
}

# ------------------------------------------------------------------------------

function Chirp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [switch] $NoNewline
    )

    Write-Host $Message -ForegroundColor Green -NoNewline:$NoNewline.IsPresent
}

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------

# Die of errors.
function Croak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    # NB: we don't write the message to the error stream.
    Write-Host $Message -BackgroundColor Red -ForegroundColor Yellow
    exit 1
}

#endregion
################################################################################
#region Misc helpers.

# Request confirmation.
function Confirm-Yes {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Question
    )

    while ($true) {
        $answer = (Read-Host $Question, "[y/N/q]")

        if ($answer -eq "" -or $answer -eq "n") {
            Say-Indent "Discarding on your request."
            return $false
        }
        elseif ($answer -eq "y") {
            return $true
        }
        elseif ($answer -eq "q") {
            Say-Indent "Terminating the script on your request."
            exit 0
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
        [string] $Question
    )

    while ($true) {
        $answer = (Read-Host $Question, "[y/N]")

        if ($answer -eq "" -or $answer -eq "n") {
            Say-Indent "Stopping on your request."
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

    Write-Verbose "Checking exit code of the last external command that was run."

    if ($LastExitCode -ne 0) { Croak $ErrMessage }
}

#endregion
################################################################################
#region FileSystem-related functions.

function Remove-Dir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    Write-Verbose "Deleting directory ""$Path""."

    if (-not (Test-Path $Path)) {
        Write-Verbose "Skipping ""$Path""; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        Carp "Skipping ""$Path""; the path MUST be absolute."
        return
    }

    rm $Path -Force -Recurse
}

# ------------------------------------------------------------------------------

function Remove-Packages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    Write-Verbose "Deleting NuGet packages in ""$Path""."

    if (-not (Test-Path $Path)) {
        Write-Verbose "Skipping ""$Path""; the path does NOT exist."
        return
    }
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        Carp "Skipping ""$Path""; the path MUST be absolute."
        return
    }

    ls $Path -Include "*.nupkg" -Recurse | ?{
        Write-Verbose "Deleting ""$_""."

        rm $_.FullName -Force
    }
}

# ------------------------------------------------------------------------------

function Remove-BinAndObj {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $PathList
    )

    Write-Verbose "Deleting ""bin"" and ""obj"" directories."

    $PathList | %{
        if (-not (Test-Path $_)) {
            Write-Verbose "Skipping ""$_""; the path does NOT exist."
            return
        }
        if (-not [System.IO.Path]::IsPathRooted($_)) {
            Carp "Skipping ""$_""; the path MUST be absolute."
            return
        }

        Write-Verbose "Processing directory ""$_""."

        ls $_ -Include bin,obj -Recurse | ?{
            Write-Verbose "Deleting ""$_""."

            rm $_.FullName -Force -Recurse
        }
    }
}

#endregion
################################################################################
#region Git-related functions.

function Find-Git {
    [CmdletBinding()]
    param(
        [switch] $Fatal
    )

    Write-Verbose "Finding git.exe."

    if ($Fatal) { $onError = "Croak" } else { $onError = "Carp" }

    $cmd = Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($cmd -eq $null) {
        . $onError "Could not be find git.exe. Please ensure Git is installed."
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
        [string] $Git,

        [switch] $Fatal
    )

    Write-Verbose "Getting the git status."

    if ($Fatal) { $onError = "Croak" } else { $onError = "Carp" }

    try {
        # If there no uncommitted changes, the result is null, not empty.
        $status = & $Git status -s 2>&1

        if ($status -eq $null) {
            return $true
        }
        else {
            . $onError "Uncommitted changes are pending."
            return $false
        }
    }
    catch {
        . $onError """git status"" failed: $_"
    }
}

# ------------------------------------------------------------------------------

# Get the last git commit hash.
function Get-GitCommitHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git,

        [switch] $Fatal
    )

    Write-Verbose "Getting the last git commit hash."

    if ($Fatal) { $onError = "Croak" } else { $onError = "Carp" }

    try {
        $commit = & $Git log -1 --format="%H" 2>&1

        Write-Verbose "Current git commit hash: ""$commit""."

        return $commit
    }
    catch {
        . $onError """git log"" failed: $_"
    }
}

# ------------------------------------------------------------------------------

# Get the current git branch.
function Get-GitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Git,

        [switch] $Fatal
    )

    Write-Verbose "Getting the git branch."

    if ($Fatal) { $onError = "Croak" } else { $onError = "Carp" }

    try {
        $branch = & $Git rev-parse --abbrev-ref HEAD 2>&1

        Write-Verbose "Current git branch: ""$branch""."

        return $branch
    }
    catch {
        . $onError """git rev-parse"" failed: $_"
    }
}

#endregion
################################################################################
#region VS-related functions.

# & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -?
# https://aka.ms/vs/workloads for a list of workload (-requires)
function Find-VsWhere {
    [CmdletBinding()]
    param()

    Write-Verbose "Finding vswhere.exe."

    $cmd = Get-Command "vswhere.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($cmd -ne $null) {
        return $cmd.Path
    }

    Write-Verbose "vswhere.exe could not be found in your PATH."

    $path = Join-Path ${ENV:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $path) {
        Write-Verbose "vswhere.exe found here: ""$path""."

        return $path
    }
    else {
        Croak "Could not find vswhere.exe."
    }
}

# ------------------------------------------------------------------------------

function Find-MSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $VSWhere
    )

    Write-Verbose "Finding MSBuild.exe."

    $path = & $VSWhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1

    if (-not $path) {
        Croak "Could not find MSBuild.exe."
    }

    Write-Verbose "MSBuild.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

function Find-Fsi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $VSWhere
    )

    Write-Verbose "Finding fsi.exe."

    $vspath = & $VSWhere -legacy -latest -property installationPath

    $path = Join-Path $vspath "\Common7\IDE\CommonExtensions\Microsoft\FSharp\fsi.exe"
    if (Test-Path $path) {
        Write-Verbose "fsi.exe found here: ""$path""."

        return $path
    }
    else {
        Croak "Could not find fsi.exe."
    }
}

#endregion
################################################################################

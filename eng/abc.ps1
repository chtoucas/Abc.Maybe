# See LICENSE in the project root for license information.

# Version 5.1 for ErrorRecord.
#Requires -Version 5.1

# Dot sourcing this file ensures that it executes in the caller scope.
# For safety, we still add the $Script: prefix.
Set-StrictMode -Version Latest
$Script:ErrorActionPreference = "Stop"

# UNUSED: does not seem to work for what I want: english messages, eg
# "dotnet restore" continues to output french messages.
function Initialize-Env {
    [CmdletBinding()]
    param()

    Write-Verbose "Initialization."

    # Set language used by MSBuild, dotnet and VS.
    # See https://github.com/microsoft/msbuild/issues/1596
    # and https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet
    [Environment]::SetEnvironmentVariable("DOTNET_CLI_UI_LANGUAGE", "en", "User")
    [Environment]::SetEnvironmentVariable("VSLANG", "1033", "User")
}

################################################################################
#region Project-specific constants.

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".

# All paths are ABSOLUTE.

# Root directory = absolute path of the parent directory containing *this* file.
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
# .NET Framework tools.
(Join-Path $ARTIFACTS_DIR "tools") `
    | New-Variable -Name "NET_FRAMEWORK_TOOLS_DIR" -Scope Script -Option Constant

# Reference project used to restore .NET Framework tools.
(Join-Path $ENG_DIR "NETFrameworkTools\NETFrameworkTools.csproj") `
    | New-Variable -Name "NET_FRAMEWORK_TOOLS_PROJECT" -Scope Script -Option Constant

#endregion
################################################################################
#region Project-specific functions.

function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName,

        [switch] $asString
    )

    Write-Verbose "Getting package version."

    $proj = Join-Path $ENG_DIR "$packageName.props" -Resolve

    $xml = [Xml] (Get-Content $proj)
    $node = (Select-Xml -Xml $xml -XPath "//Project/PropertyGroup/MajorVersion/..").Node

    # NB: if one of the nodes does not actually exist, the function throws.
    $major = $node | select -First 1 -ExpandProperty MajorVersion
    $minor = $node | select -First 1 -ExpandProperty MinorVersion
    $patch = $node | select -First 1 -ExpandProperty PatchVersion
    $precy = $node | select -First 1 -ExpandProperty PreReleaseCycle
    $preno = $node | select -First 1 -ExpandProperty PreReleaseNumber

    if ($asString) {
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

function Restore-NETFrameworkTools {
    [CmdletBinding()]
    param()

    Say "Restoring local .NET Framework tools."
    & dotnet restore $NET_FRAMEWORK_TOOLS_PROJECT | Out-Host
}

# ------------------------------------------------------------------------------

function Restore-NETCoreTools {
    [CmdletBinding()]
    param()

    try {
        pushd $ROOT_DIR

        Say "Restoring local .NET Core tools."
        & dotnet tool restore | Out-Host
    }
    finally {
        popd
    }
}

# ------------------------------------------------------------------------------

function Restore-Solution {
    [CmdletBinding()]
    param()

    try {
        pushd $ROOT_DIR

        Say "Restoring solution."
        & dotnet restore | Out-Host
    }
    finally {
        popd
    }
}

# ------------------------------------------------------------------------------

function Find-OpenCover {
    [CmdletBinding()]
    param(
        [switch] $fatal
    )

    Write-Verbose "Finding OpenCover.Console.exe."

    if ($fatal) { $onError = "Croak" } else { $onError = "Carp" }

    $version = Get-PackageReferenceVersion $NET_FRAMEWORK_TOOLS_PROJECT "OpenCover"

    if ($version -eq $null) {
        . $onError "OpenCover is not referenced in ""$NET_FRAMEWORK_TOOLS_PROJECT""."
        return $null
    }

    $path = Join-Path $NET_FRAMEWORK_TOOLS_DIR "opencover\$version\tools\OpenCover.Console.exe"

    if (-not (Test-Path $path)) {
        . $onError "Couldn't find OpenCover v$version where I expected it to be. Maybe use -Restore?"
        return $null
    }

    Write-Verbose "OpenCover.Console.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

function Find-XunitRunner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $platform,

        [switch] $fatal
    )

    Write-Verbose "Finding xunit.console.exe."

    if ($fatal) { $onError = "Croak" } else { $onError = "Carp" }

    $version = Get-PackageReferenceVersion $NET_FRAMEWORK_TOOLS_PROJECT "xunit.runner.console"

    if ($version -eq $null) {
        . $onError "Xunit console runner is not referenced in ""$NET_FRAMEWORK_TOOLS_PROJECT""."
        return $null
    }

    $path = Join-Path $NET_FRAMEWORK_TOOLS_DIR `
        "xunit.runner.console\$version\tools\$platform\xunit.console.exe"

    if (-not (Test-Path $path)) {
        . $onError "Couldn't find Xunit Console Runner v$version where I expected it to be. Maybe use -Restore?"
        return $null
    }

    Write-Verbose "xunit.console.exe found here: ""$path""."

    $path
}

# ------------------------------------------------------------------------------

function Reset-SourceTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    Write-Verbose "Resetting source tree."

    if ($yes -or (Confirm-Yes "Hard clean the directory ""src""?")) {
        Say "Deleting ""bin"" and ""obj"" directories within ""src""."
        Remove-BinAndObj $SRC_DIR
    }
}

# ------------------------------------------------------------------------------

function Reset-TestTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    Write-Verbose "Resetting test tree."

    if ($yes -or (Confirm-Yes "Hard clean the directory ""test""?")) {
        Say "Deleting ""bin"" and ""obj"" directories within ""test""."
        Remove-BinAndObj $TEST_DIR
    }
}

# ------------------------------------------------------------------------------

function Reset-PackageOutDir {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    Write-Verbose "Resetting output directory for packages."

    if ($yes -or (Confirm-Yes "Reset output directory for packages?")) {
        Say "Clearing output directory for packages."
        Remove-Packages $PKG_OUTDIR
    }
}

# ------------------------------------------------------------------------------

function Reset-PackageCIOutDir {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    Write-Verbose "Resetting output directory for CI packages."

    if ($yes -or (Confirm-Yes "Reset output directory for CI packages?")) {
        Say "Clearing output directory for CI packages."
        Remove-Packages $PKG_CI_OUTDIR
    }
}

# ------------------------------------------------------------------------------

function Reset-LocalNuGet {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    Write-Verbose "Resetting local NuGet feed/cache."

    if ($yes -or (Confirm-Yes "Reset local NuGet feed/cache?")) {
        # When we reset the NuGet feed, better to clear the cache too, this is
        # not mandatory but it keeps cache and feed in sync.
        # The inverse is also true.
        # If we clear the cache but don't reset the feed, things will continue
        # to work but packages from the local NuGet feed will then be restored
        # to the global cache, exactly what we wanted to avoid.
        #
        # We can't delete the directories, otherwise "dotnet restore" will fail.

        Say "Resetting local NuGet feed."
        Remove-Packages $NUGET_LOCAL_FEED

        Say "Clearing local NuGet cache."
        Get-ChildItem $NUGET_LOCAL_CACHE -Exclude "_._" `
            | % { Remove-Item $_ -Recurse }
    }
}

# ------------------------------------------------------------------------------

function Remove-PackageFromLocalNuGet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $version
    )

    Say "Removing obsolete package data from local NuGet feed/cache."

    Join-Path $NUGET_LOCAL_CACHE $packageName.ToLower() `
        | Join-Path -ChildPath $version `
        | Remove-Dir

    $oldFilepath = Join-Path $NUGET_LOCAL_FEED "$packageName.$version.nupkg"
    if (Test-Path $oldFilepath) {
        Remove-Item $oldFilepath
    }
}

#endregion
################################################################################
#region Print.

function Say {
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

function Say-Indent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    Write-Host "  $message" -NoNewline:$noNewline
}

# ------------------------------------------------------------------------------

function Say-Softly {
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

function Say-LOUDLY {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline,
        [switch] $invert
    )

    if ($invert) {
        Write-Host $message -ForegroundColor Green -NoNewline:$noNewline -BackgroundColor DarkCyan
    }
    else {
        Write-Host $message -ForegroundColor Green -NoNewline:$noNewline
    }
}

#endregion
################################################################################
#region Error reporting.

# Warn user.
function Carp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    # NB: we don't write the message to the warning stream.
    Write-Host "WARNING: $message" -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------

# Die of errors.
function Croak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message
    )

    # NB: we don't write the message to the error stream.
    Write-Host $message -BackgroundColor Red -ForegroundColor Yellow

    exit 1
}

# ------------------------------------------------------------------------------

# Die of errors with stack trace.
function Confess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.ErrorRecord] $error
    )

    # NB: we don't write the message to the error stream.
    Write-Host "An unexpected error occured." -BackgroundColor Red -ForegroundColor Yellow
    if ($error -ne $null) {
        Write-Host $error -ForegroundColor Red
        Write-Host $error.ScriptStackTrace
    }
    else {
        Write-Host "Sorry, no further details about the error were given."
    }

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
        [string] $question
    )

    while ($true) {
        $answer = (Read-Host $question, "[y/N/q]")

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
        [string] $question
    )

    while ($true) {
        $answer = (Read-Host $question, "[y/N]")

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
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $error,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $success = ""
    )

    Write-Verbose "Checking exit code of the last external command that was run."

    if ($LastExitCode -ne 0) { Croak $error }

    if ($success -ne "") {
        Say-Softly $success
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
        Carp "Skipping ""$path""; the path MUST be absolute."
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
        Carp "Skipping ""$path""; the path MUST be absolute."
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
            Carp "Skipping ""$_""; the path MUST be absolute."
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
    param()

    Write-Verbose "Finding git.exe."

    $cmd = Get-Command "git.exe" -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue

    if ($cmd -eq $null) {
        Croak "Could not be find git.exe. Please ensure Git is installed."
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

        [switch] $fatal
    )

    Write-Verbose "Getting the git status."

    if ($fatal) { $onError = "Croak" } else { $onError = "Carp" }

    try {
        # If there no uncommitted changes, the result is null, not empty.
        $status = & $git status -s 2>&1

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
        [string] $git,

        [switch] $fatal
    )

    Write-Verbose "Getting the last git commit hash."

    if ($fatal) { $onError = "Croak" } else { $onError = "Carp" }

    try {
        $commit = & $git log -1 --format="%H" 2>&1

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
        [string] $git,

        [switch] $fatal
    )

    Write-Verbose "Getting the git branch."

    if ($fatal) { $onError = "Croak" } else { $onError = "Carp" }

    try {
        $branch = & $git rev-parse --abbrev-ref HEAD 2>&1

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

    $path = Join-Path ${Env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"
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
        [string] $vswhere
    )

    Write-Verbose "Finding MSBuild.exe."

    $path = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe `
        | select-object -first 1

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
        [string] $vswhere
    )

    Write-Verbose "Finding fsi.exe."

    $vspath = & $vswhere -legacy -latest -property installationPath

    $path = Join-Path $vspath "\Common7\IDE\CommonExtensions\Microsoft\FSharp\fsi.exe"
    if (Test-Path $path) {
        Write-Verbose "fsi.exe found here: ""$path""."

        return $path
    }
    else {
        Croak "Could not find fsi.exe."
    }
}

# ------------------------------------------------------------------------------

# Return $null if the XML node does not exist.
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

    $xml = [Xml] (Get-Content $projectPath)
    $xpath = "//Project/ItemGroup/PackageReference[@Include='$package']"

    Select-Xml -Xml $xml -XPath $xpath `
        | select -ExpandProperty Node `
        | select -First 1 -ExpandProperty Version
}

#endregion
################################################################################

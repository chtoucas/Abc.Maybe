# See LICENSE in the project root for license information.

# Dot sourcing this file ensures that it executes in the caller scope.
# For safety, we still add the $Script: prefix.
Set-StrictMode -Version Latest
$Script:ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

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
#region Begin/End.

# ------------------------------------------------------------------------------

function Initialize-Env {
    [CmdletBinding()]
    param()

    Write-Verbose "Initializing environment."

    # These changes won't survive when the script ends, which is good.
    [CultureInfo]::CurrentCulture = "en"
    [CultureInfo]::CurrentUICulture = "en"

    # Set language used by MSBuild, dotnet and VS.
    # These changes are global...
    # UNUSED: does not seem to work for what I want: english messages, eg
    # "dotnet restore" continues to output french messages.
    # See https://github.com/microsoft/msbuild/issues/1596
    # and https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet
    #$Env:DOTNET_CLI_UI_LANGUAGE = "en"
    #$Env:VSLANG = "1033"
}

# ------------------------------------------------------------------------------

function ___BEGIN___ {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $false)]
        [string] $fromLocation
    )

    Initialize-Env
    if ($fromLocation) { pushd $fromLocation } else { pushd $ROOT_DIR }
}

# ------------------------------------------------------------------------------

# Meant to be used within the top-level catch.
function ___ERR___ {
    [CmdletBinding()]
    param()

    $Host.UI.WriteErrorLine("An unexpected error occurred.")

    $error = $Error[0]
    if ($error -is [System.Management.Automation.ErrorRecord]) {
        $Host.UI.WriteErrorLine($error.ScriptStackTrace.ToString())
    }
    else {
        # Very unlikely to happen, but we never know.
        $Host.UI.WriteErrorLine("Sorry, no further details on the error were given.")
    }

    exit 255
}

# ------------------------------------------------------------------------------

function ___END___ {
    # Do not remove this, we want a nice output with $PSCmdlet.WriteError().
    [CmdletBinding()]
    param()

    popd

    if ($Script:___Warned) {
        Write-Host "`nExecution terminated with warning(s)." -ForegroundColor Yellow
    }
    elseif ($Script:___Died) {
        Write-Host "`nExecution aborted." -ForegroundColor Red
    }
    else {
        Write-Host "`nGoodbye." -ForegroundColor Green
    }

    $error = $Error[0]
    if ($error -is [System.Management.Automation.ErrorRecord]) {
        Write-Host "`n--- Post-mortem." -ForegroundColor Red

        # Write a terminating error.
        $PSCmdlet.WriteError($error)
    }
}

#endregion
################################################################################
#region Project-specific functions.

# Throws if the property file does not exist, or if its content is not valid.
function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName,

        [switch] $asString
    )

    Write-Verbose "Getting package version."

    $projectPath = Join-Path $ENG_DIR "$packageName.props" -Resolve

    $node = [Xml] (Get-Content $projectPath) `
        | Select-Xml -XPath "//Project/PropertyGroup/MajorVersion/.." `
        | select -ExpandProperty Node

    if ($node -eq $null) {
        croak "The property file for ""$packageName"" is not valid."
    }

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

function Find-OpenCover {
    [CmdletBinding()]
    param(
        [switch] $exitOnError
    )

    Write-Verbose "Finding OpenCover.Console.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

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

        [switch] $exitOnError
    )

    Write-Verbose "Finding xunit.console.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

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

#endregion
################################################################################
#region Restore

function Restore-NETFrameworkTools {
    [CmdletBinding()]
    param()

    say "Restoring local .NET Framework tools."
    & dotnet restore $NET_FRAMEWORK_TOOLS_PROJECT | Out-Host
}

# ------------------------------------------------------------------------------

function Restore-NETCoreTools {
    [CmdletBinding()]
    param()

    try {
        pushd $ROOT_DIR

        say "Restoring local .NET Core tools."
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

        say "Restoring solution."
        & dotnet restore | Out-Host
    }
    finally {
        popd
    }
}

#endregion
################################################################################
#region Reset

function Reset-SourceTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    Write-Verbose "Resetting source tree."

    if ($yes -or (Confirm-Yes "Hard clean the directory ""src""?")) {
        say "Deleting ""bin"" and ""obj"" directories within ""src""."
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
        say "Deleting ""bin"" and ""obj"" directories within ""test""."
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
        say "Clearing output directory for packages."
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
        say "Clearing output directory for CI packages."
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

        say "Resetting local NuGet feed."
        Remove-Packages $NUGET_LOCAL_FEED

        say "Clearing local NuGet cache."
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

    say "Removing obsolete package data from local NuGet feed/cache."

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

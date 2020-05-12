# See LICENSE in the project root for license information.

# Dot sourcing this file ensures that it executes in the caller scope.
# For safety, we still add the $Script: prefix.
Set-StrictMode -Version Latest
$Script:ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

################################################################################
#region Aliases / Constants.

New-Alias "Hello"      Write-Hello   -Scope Script
New-Alias "say-softly" Write-Cyan    -Scope Script
New-Alias "SAY-LOUDLY" Write-Green   -Scope Script

# ------------------------------------------------------------------------------

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".

# All paths are ABSOLUTE.

# Root directory = absolute path of the parent directory containing *this* file.
(Get-Item $PSScriptRoot).Parent.FullName | my ROOT_DIR -Option Constant

# Root subdirectories.
(Join-Path $ROOT_DIR "eng"  -Resolve) | my ENG_DIR -Option Constant
(Join-Path $ROOT_DIR "src"  -Resolve) | my SRC_DIR -Option Constant
(Join-Path $ROOT_DIR "test" -Resolve) | my TEST_DIR -Option Constant
(Join-Path $ROOT_DIR "__"   -Resolve) | my ARTIFACTS_DIR -Option Constant

# Artifacts subdirectories. No -Resolve, dir does not necessary exist.
(Join-Path $ARTIFACTS_DIR "packages")    | my PKG_OUTDIR -Option Constant
(Join-Path $ARTIFACTS_DIR "packages-ci") | my PKG_CI_OUTDIR -Option Constant
(Join-Path $ARTIFACTS_DIR "nuget-feed")  | my NUGET_LOCAL_FEED -Option Constant
(Join-Path $ARTIFACTS_DIR "nuget-cache") | my NUGET_LOCAL_CACHE -Option Constant
(Join-Path $ARTIFACTS_DIR "tools")       | my NET_FRAMEWORK_TOOLS_DIR -Option Constant

# Reference project used to restore .NET Framework tools.
(Join-Path $ENG_DIR "NETFrameworkTools\NETFrameworkTools.csproj") `
    | my NET_FRAMEWORK_TOOLS_PROJECT -Option Constant

#endregion
################################################################################
#region Begin / End.

function Initialize-Env {
    [CmdletBinding()]
    param()

    confess "Initialising environment."

    # These changes won't survive when the script ends, which is good.
    [CultureInfo]::CurrentCulture = "en"
    [CultureInfo]::CurrentUICulture = "en"

    # Set language used by MSBuild, dotnet and VS.
    # UNUSED: does not seem to work for what I want: english messages, eg
    # "dotnet restore" continues to output messages in french.
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

    if ($Error -and ($err = $Error[0]) -is [System.Management.Automation.ErrorRecord]) {
        $Host.UI.WriteErrorLine($err.ScriptStackTrace.ToString())
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
        say "`nExecution terminated with warning(s)." -ForegroundColor Yellow
    }
    elseif ($Script:___Died) {
        say "`nExecution aborted." -ForegroundColor Red
    }
    else {
        say "`nGoodbye." -ForegroundColor Green
    }

    if ($Error -and ($err = $Error[0]) -is [System.Management.Automation.ErrorRecord]) {
        say "`n--- Post-mortem." -ForegroundColor Red

        # Write a terminating error.
        $PSCmdlet.WriteError($err)
    }
}

#endregion
################################################################################
#region UI.

function Write-Hello {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    say "Hello, $message" -ForegroundColor White -NoNewline:$noNewline
}

# ------------------------------------------------------------------------------

function Write-Cyan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    say $message -ForegroundColor Cyan -NoNewline:$noNewline
}

# ------------------------------------------------------------------------------

function Write-Green {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $message,

        [switch] $noNewline
    )

    say $message -ForegroundColor Green -NoNewline:$noNewline
}

#endregion
################################################################################
#region Tools.

# Throws if the property file does not exist, or if its content is not valid.
function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName,

        [switch] $asString
    )

    confess "Getting package version."

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

    confess "Finding OpenCover.Console.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    $version = Get-PackageReferenceVersion $NET_FRAMEWORK_TOOLS_PROJECT "OpenCover"

    if ($version -eq $null) {
        . $onError "OpenCover is not referenced in ""$NET_FRAMEWORK_TOOLS_PROJECT""."
        return $null
    }

    $path = Join-Path $NET_FRAMEWORK_TOOLS_DIR "opencover\$version\tools\OpenCover.Console.exe"

    if (Test-Path $path) {
        confess "OpenCover.Console.exe found here: ""$path""."
        return $path
    }
    else {
        . $onError "Could not find OpenCover v$version. Maybe use -Restore?"
        return $null
    }
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

    confess "Finding xunit.console.exe."

    if ($exitOnError) { $onError = "croak" } else { $onError = "carp" }

    $version = Get-PackageReferenceVersion $NET_FRAMEWORK_TOOLS_PROJECT "xunit.runner.console"

    if ($version -eq $null) {
        . $onError "Xunit console runner is not referenced in ""$NET_FRAMEWORK_TOOLS_PROJECT""."
        return $null
    }

    $path = Join-Path $NET_FRAMEWORK_TOOLS_DIR `
        "xunit.runner.console\$version\tools\$platform\xunit.console.exe"

    if (Test-Path $path) {
        confess "xunit.console.exe found here: ""$path""."
        return $path
    }
    else {
        . $onError "Could not find Xunit Console Runner v$version. Maybe use -Restore?"
        return $null
    }
}

# ------------------------------------------------------------------------------

# TODO: to be removed.
# Die if the exit code of the last external command that was run is not equal to zero.
function Assert-CmdSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $error,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $success
    )

    confess "Checking exit code of the last external command that was run."

    if ($LastExitCode -ne 0) { croak $error }

    if ($success) { say-softly $success }
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
#region Reset / Clear

function Reset-SourceTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { $echo = "say" } else { $echo = "confess" }

    . $echo "Resetting source tree."

    if ($yes -or (yesno "Reset the source tree?")) {
        Remove-BinAndObj $SRC_DIR
        say-softly "The source tree was reset."
    }
}

# ------------------------------------------------------------------------------

function Reset-TestTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { $echo = "say" } else { $echo = "confess" }

    . $echo "Resetting test tree."

    if ($yes -or (yesno "Reset the test tree?")) {
        Remove-BinAndObj $TEST_DIR
        say-softly "The test tree was reset."
    }
}

# ------------------------------------------------------------------------------

function Reset-PackageOutDir {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { $echo = "say" } else { $echo = "confess" }

    . $echo "Resetting output directory for packages."

    if ($yes -or (yesno "Clear output directory for packages?")) {
        confess "Clearing output directory for packages."

        if (Test-Path $PKG_OUTDIR) {
            ls $PKG_OUTDIR -Include "*.nupkg" -Recurse `
                | % { confess "Deleting ""$_""." ; rm $_.FullName }
        }

        say-softly "Output directory for packages was cleared."
    }
}

# ------------------------------------------------------------------------------

function Reset-PackageCIOutDir {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { $echo = "say" } else { $echo = "confess" }

    . $echo "Resetting output directory for CI packages."

    if ($yes -or (yesno "Clear output directory for CI packages?")) {
        confess "Clearing output directory for CI packages."

        if (Test-Path $PKG_CI_OUTDIR) {
            ls $PKG_CI_OUTDIR -Include "*.nupkg" -Recurse `
                | % { confess "Deleting ""$_""." ; rm $_.FullName }
        }

        say-softly "Output directory for CI packages was cleared."
    }
}

# ------------------------------------------------------------------------------

function Reset-LocalNuGet {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { $echo = "say" } else { $echo = "confess" }

    . $echo "Resetting local NuGet feed/cache."

    if ($yes -or (yesno "Clear local NuGet feed/cache?")) {
        # When we reset the NuGet feed, better to clear the cache too, this is
        # not mandatory but it keeps cache and feed in sync.
        # The inverse is also true.
        # If we clear the cache but don't reset the feed, things will continue
        # to work but packages from the local NuGet feed will then be restored
        # to the global cache, exactly what we wanted to avoid.
        #
        # We can't delete the directories, otherwise "dotnet restore" will fail.

        confess "Clearing local NuGet feed."
        ls $NUGET_LOCAL_FEED -Exclude "_._" `
            | % { confess "Deleting ""$_""." ; rm $_ -Recurse }
        say-softly "Local NuGet feed was cleared."

        confess "Clearing local NuGet cache."
        ls $NUGET_LOCAL_CACHE -Exclude "_._" `
            | % { confess "Deleting ""$_""." ; rm $_ -Recurse }
        say-softly "Local NuGet cache was cleared."
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

    confess "Removing package from the local NuGet cache."
    Join-Path $NUGET_LOCAL_CACHE $packageName.ToLower() `
        | Join-Path -ChildPath $version `
        | Remove-Dir

    confess "Removing package from the local NuGet feed."
    $oldFilepath = Join-Path $NUGET_LOCAL_FEED "$packageName.$version.nupkg"
    if (Test-Path $oldFilepath) {
        rm $oldFilepath
    }
}

#endregion
################################################################################

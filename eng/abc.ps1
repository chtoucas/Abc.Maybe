# See LICENSE in the project root for license information.

#Requires -Version 7

using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands

# Dot sourcing this file ensures that it executes in the caller scope.
# For safety, we still add the $Script: prefix.
Set-StrictMode -Version Latest
$Script:ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

$Script:___ForegroundColor = `
    $Host.UI.RawUI.ForegroundColor -eq "White" ? "Blue" : "White"

################################################################################
#region Aliases / Constants.

New-Alias "Hello"      Write-Hello
New-Alias "say-softly" Write-Cyan
New-Alias "SAY-LOUDLY" Write-Green

# ------------------------------------------------------------------------------

# Note to myself: do not use a separate directory for build.
# Build warnings MSB3277, the problem is that we then build all platforms
# within the same dir. This is something that can happen for instance if we
# define a variable $OutDir and call dotnet or MSBuild w/ "." and not "&".

# All paths are ABSOLUTE.

# Root directory = absolute path of the parent directory.
(Get-Item $PSScriptRoot).Parent.FullName | const ROOT_DIR
# Core directories.
(Join-Path $ROOT_DIR "eng"  -Resolve)    | const ENG_DIR
(Join-Path $ROOT_DIR "src"  -Resolve)    | const SRC_DIR
(Join-Path $ROOT_DIR "test" -Resolve)    | const TEST_DIR
(Join-Path $ROOT_DIR "__"   -Resolve)    | const ARTIFACTS_DIR
# Artifacts directories. No -Resolve, dir does not necessary exist.
(Join-Path $ARTIFACTS_DIR "packages")    | const PKG_OUTDIR
(Join-Path $ARTIFACTS_DIR "packages-ci") | const PKG_CI_OUTDIR
(Join-Path $ARTIFACTS_DIR "nuget-feed")  | const NUGET_LOCAL_FEED
(Join-Path $ARTIFACTS_DIR "nuget-cache") | const NUGET_LOCAL_CACHE
(Join-Path $ARTIFACTS_DIR "tools")       | const NET_FRAMEWORK_TOOLS_DIR

# The props where we can informations related to the supported platforms, see:
# - Get-SolutionPlatforms
# - Get-PackagePlatforms
# - Get-SupportedPlatforms
const PLATFORMS_PROPS (Join-Path $ROOT_DIR "Directory.Build.props" -Resolve)

# Reference project used to restore .NET Framework tools.
# NB: we need the project file (not the directory) since we are going to parse it.
const NET_FRAMEWORK_TOOLS_PROJECT `
    (Join-Path $ENG_DIR "NETFrameworkTools\NETFrameworkTools.csproj" -Resolve)

#endregion
################################################################################
#region Begin / End.

function Initialize-Env {
    [CmdletBinding()]
    param()

    ___confess "Initialising environment."

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
    [CmdletBinding()]
    param()

    Initialize-Env
    pushd $ROOT_DIR
}

# ------------------------------------------------------------------------------

# Meant to be used within the top-level catch.
function ___CATCH___ {
    [CmdletBinding()]
    param()

    $Script:___Died = $true

    $Host.UI.WriteErrorLine("An unexpected error occurred.")

    if ($Error -and ($err = $Error[0]) -is [ErrorRecord]) {
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

    if ($Script:___Died) {
        say "`nExecution aborted." -ForegroundColor Red
    }
    elseif ($Script:___Warned) {
        say "`nExecution terminated with warning(s)." -ForegroundColor Yellow
    }
    else {
        say "`nGoodbye." -ForegroundColor $Script:___ForegroundColor
    }

    if ($Error -and ($err = $Error[0]) -is [ErrorRecord]) {
        say "`n--- Post-mortem." -ForegroundColor $Script:___ForegroundColor

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

    say "Hello, $message" -ForegroundColor $Script:___ForegroundColor -NoNewline:$noNewline
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
#region Settings.

# Throws if the property file does not exist, or if its content is not valid.
function Get-PackageVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $packageName,

        [switch] $asString
    )

    ___confess "Getting package version."

    $projectPath = Join-Path $SRC_DIR "$packageName.props" -Resolve

    [SelectXmlInfo[]] $nodes = [Xml] (Get-Content $projectPath) `
        | Select-Xml -XPath "//Project/PropertyGroup/MajorVersion/.."

    if ($nodes.Count -ne 1) {
        croak "The property file for ""$packageName"" is not ""valid""."
    }

    $pg = $nodes[0].Node

    # NB: if one of the nodes does not actually exist, the function throws.
    $major = $pg.MajorVersion.Trim()
    $minor = $pg.MinorVersion.Trim()
    $patch = $pg.PatchVersion.Trim()
    $precy = $pg.PreReleaseCycle.Trim()
    $preno = $pg.PreReleaseNumber.Trim()

    if ($asString) {
        return $precy ? "$major.$minor.$patch-$precy$preno"
            : "$major.$minor.$patch"
    }
    else {
        @($major, $minor, $patch, $precy, $preno)
    }
}

# ------------------------------------------------------------------------------

function Get-SolutionPlatforms {
    [CmdletBinding()]
    param(
        [switch] $asString
    )

    ___confess "Getting the supported platforms by the solution."

    [SelectXmlInfo[]] $nodes = [Xml] (Get-Content $PLATFORMS_PROPS) `
        | Select-Xml -XPath "//Project/PropertyGroup/SolutionPlatforms" `

    if ($nodes.Count -ne 1) {
        croak "The property file for ""$PLATFORMS_PROPS"" is not ""valid""."
    }

    $platforms = $nodes[0].Node.InnerXML.Trim()

    if ($asString) {
        # Ready for MSBuild.exe/dotnet.exe.
        return """$platforms"""
    }
    else {
        return $platforms.Split(";")
    }
}

# ------------------------------------------------------------------------------

function Get-PackagePlatforms {
    [CmdletBinding()]
    param(
        [switch] $asString
    )

    ___confess "Getting the supported platforms by the package."

    [SelectXmlInfo[]] $nodes = [Xml] (Get-Content $PLATFORMS_PROPS) `
        | Select-Xml -XPath "//Project/PropertyGroup/PackagePlatforms" `

    if ($nodes.Count -ne 1) {
        croak "The property file for ""$PLATFORMS_PROPS"" is not ""valid""."
    }

    $platforms = $nodes[0].Node.InnerXML.Trim()

    if ($asString) {
        # Ready for MSBuild.exe/dotnet.exe.
        return """$platforms"""
    }
    else {
        return $platforms.Split(";")
    }
}

# ------------------------------------------------------------------------------

function Get-SupportedPlatforms {
    [CmdletBinding()]
    param()

    ___confess "Getting the list of all supported platforms."

    [SelectXmlInfo[]] $nodes = [Xml] (Get-Content $PLATFORMS_PROPS) `
        | Select-Xml -XPath "//Project/PropertyGroup/MinClassicPlatforms/.." `

    if ($nodes.Count -ne 1) {
        croak "The property file for ""$PLATFORMS_PROPS"" is not ""valid""."
    }

    $pg = $nodes[0].Node

    $minClassic = $pg.MinClassicPlatforms.Trim().Split(";")
    $maxClassic = @("net45", "net451") + $pg.MaxClassicPlatforms.Trim().Split(";")
    $minCore    = $pg.MinCorePlatforms.Trim().Split(";")
    $maxCore    = $pg.MaxCorePlatforms.Trim().Split(";")

    @($minClassic, $maxClassic, $minCore, $maxCore)
}

#endregion
################################################################################
#region Tools.

function Find-OpenCover {
    [CmdletBinding()]
    param(
        [switch] $exitOnError
    )

    ___confess "Finding OpenCover.Console.exe."

    $version = Get-PackageReferenceVersion $NET_FRAMEWORK_TOOLS_PROJECT "OpenCover" `
        -ExitOnError:$exitOnError

    $path = Join-Path $NET_FRAMEWORK_TOOLS_DIR "opencover\$version\tools\OpenCover.Console.exe"

    if (-not (Test-Path $path)) {
        return carp "Could not find OpenCover v$version. Maybe use -Restore?" `
            -ExitOnError:$exitOnError
    }

    ___debug "OpenCover.Console.exe found here: ""$path""."

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

    ___confess "Finding xunit.console.exe."

    $version = Get-PackageReferenceVersion $NET_FRAMEWORK_TOOLS_PROJECT "xunit.runner.console" `
        -ExitOnError:$exitOnError

    $path = Join-Path $NET_FRAMEWORK_TOOLS_DIR `
        "xunit.runner.console\$version\tools\$platform\xunit.console.exe"

    if (-not (Test-Path $path)) {
        return carp "Could not find Xunit Console Runner v$version. Maybe use -Restore?" `
            -ExitOnError:$exitOnError
    }

    ___debug "xunit.console.exe found here: ""$path""."

    $path
}

#endregion
################################################################################
#region Restore tasks.

function Restore-NETFrameworkTools {
    [CmdletBinding()]
    param()

    say "Restoring local .NET Framework tools."

    & dotnet restore $NET_FRAMEWORK_TOOLS_PROJECT
        || carp "Failed to restore local .NET Framework tools."
}

# ------------------------------------------------------------------------------

function Restore-NETCoreTools {
    [CmdletBinding()]
    param()

    try {
        pushd $ROOT_DIR

        say "Restoring local .NET Core tools."

        & dotnet tool restore
            || carp "Failed to restore local .NET Core tools."
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

        & dotnet restore
            || carp "Failed to restore solution."
    }
    finally {
        popd
    }
}

#endregion
################################################################################
#region Reset tasks.

function Reset-SourceTree {
    [CmdletBinding()]
    param(
        [Alias("y")] [switch] $yes
    )

    if ($yes) { say "`nResetting source tree." }

    if ($yes -or (yesno "`nReset the source tree?")) {
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

    if ($yes) { say "`nResetting test tree." }

    if ($yes -or (yesno "`nReset the test tree?")) {
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

    if ($yes) { say "`nResetting output directory for packages." }

    if ($yes -or (yesno "`nClear output directory for packages?")) {
        ___debug "Clearing output directory for packages."

        if (Test-Path $PKG_OUTDIR) {
            ls $PKG_OUTDIR -Include "*.nupkg" -Recurse `
                | foreach { ___debug "Deleting ""$_""." ; rm $_.FullName }
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

    if ($yes) { say "`nResetting output directory for CI packages." }

    if ($yes -or (yesno "`nClear output directory for CI packages?")) {
        ___debug "Clearing output directory for CI packages."

        if (Test-Path $PKG_CI_OUTDIR) {
            ls $PKG_CI_OUTDIR -Include "*.nupkg" -Recurse `
                | foreach { ___debug "Deleting ""$_""." ; rm $_.FullName }
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

    if ($yes) { say "`nResetting local NuGet feed/cache." }

    if ($yes -or (yesno "`nClear local NuGet feed/cache?")) {
        # When we reset the NuGet feed, better to clear the cache too, this is
        # not mandatory but it keeps cache and feed in sync.
        # The inverse is also true.
        # If we clear the cache but don't reset the feed, things will continue
        # to work but packages from the local NuGet feed will then be restored
        # to the global cache, exactly what we wanted to avoid.
        #
        # We can't delete the directories, otherwise "dotnet restore" will fail.

        ___confess "Clearing local NuGet feed."
        ls $NUGET_LOCAL_FEED -Exclude "_._" `
            | foreach { ___debug "Deleting ""$_""." ; rm $_ -Recurse }
        say-softly "Local NuGet feed was cleared."

        ___confess "Clearing local NuGet cache."
        ls $NUGET_LOCAL_CACHE -Exclude "_._" `
            | foreach { ___debug "Deleting ""$_""." ; rm $_ -Recurse }
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

    ___confess "Removing package from the local NuGet cache."
    Join-Path $NUGET_LOCAL_CACHE $packageName.ToLower() `
        | Join-Path -ChildPath $version `
        | Remove-Dir

    ___confess "Removing package from the local NuGet feed."
    $oldFilepath = Join-Path $NUGET_LOCAL_FEED "$packageName.$version.nupkg"
    if (Test-Path $oldFilepath) {
        rm $oldFilepath
    }
}

#endregion
################################################################################

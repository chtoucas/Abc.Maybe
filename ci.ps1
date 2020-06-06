# See LICENSE in the project root for license information.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration
)

# Objectives: extended build/testing (OS-dependent).
# Default behaviour is to build/test for "MaxPlatform" or "LibraryPlatforms".
# Build:
# - Windows: "BuildPlatforms"
#     "netstandard2.1;netstandard1.1;netcoreapp3.1;netcoreapp2.0;net48;net45"
# - Others: idem but without "net4x"
# Testing:
# - Windows: "TestPlatforms"
#     "netcoreapp3.1;netcoreapp2.1;net48;net452"
# - Others: idem but without "net4x"
# Maybe it can be done at the MSBuild-level.

try {
    $targets = "netstandard2.1;netstandard1.1;netcoreapp3.1;netcoreapp2.0;net48;net45"
    $args = @('/p:TargetFrameworks=\"' + $targets + '\"')

    & dotnet restore $args
    & dotnet build $args --no-restore -c $Configuration `
        /p:GenerateDocumentationFile=true `
        /p:HideInternals=true
}
catch {
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
}

# See LICENSE in the project root for license information.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration
)

try {
    # See "BuildPlatforms" in D.B.props.
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

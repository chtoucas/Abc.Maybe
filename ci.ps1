# See LICENSE in the project root for license information.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration
)

try {
    $proj = "src\Abc.Tests\Abc.Tests.csproj"
    $targets = "netcoreapp3.1;netcoreapp2.1;net48;net472;net462;net452"
    $args = @('/p:TargetFrameworks=\"' + $targets + '\"')

    & dotnet restore $proj $args
    & dotnet build $proj $args --no-restore -c $Configuration /p:RunAnalyzers=false
    & dotnet test $proj $args --no-build -c $Configuration
}
catch {
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
}

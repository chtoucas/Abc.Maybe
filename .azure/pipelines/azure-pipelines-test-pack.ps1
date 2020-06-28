# See LICENSE in the project root for license information.

#Requires -Version 7

[CmdletBinding()]
param()

$packageSuffix = "19700101.1"
$packProject   = "src\Abc.Maybe"
$cacheProject  = "test\NuGetCaching"
$testProject   = "test\Package"

$artifactsPath  = "$PSScriptRoot\..\..\__\packages-dev\"
$localNuGetFeed = "$PSScriptRoot\..\..\__\nuget-feed\"

# Main Project.

& dotnet restore $packProject /p:TF_BUILD=true
    || Write-Error "Restore failed."

& dotnet build $packProject --no-restore -c Release /p:Retail=true /p:vNext=true `
    /p:IncludeSourceRevisionInInformationalVersion=true /p:TF_BUILD=true
    || Write-Error "Build failed."

& dotnet pack $packProject --no-build -c Release /p:Retail=true /p:vNext=true `
    /p:PackageSuffix=$packageSuffix /p:RepositoryBranch=master --output $artifactsPath /p:TF_BUILD=true
    || Write-Error "Pack failed."

& dotnet nuget push "${artifactsPath}*.nupkg" -s $localNuGetFeed /p:TF_BUILD=true
    || Write-Error "Push failed."

# Cache Project.

& dotnet restore $cacheProject /p:vNext=true /p:AbcPackageSuffix=$packageSuffix /p:TF_BUILD=true
    || Write-Error "Restore failed."

# Testing Package Project.

& dotnet restore $testProject /p:vNext=true /p:AbcPackageSuffix=$packageSuffix /p:TF_BUILD=true
    || Write-Error "Restore failed."

& dotnet build $testProject --no-restore -c Debug /p:vNext=true /p:AbcPackageSuffix=$packageSuffix /p:TF_BUILD=true
    || Write-Error "Build failed."

#& dotnet test $testProject --no-build -c Debug /p:vNext=true /p:AbcPackageSuffix=$packageSuffix /p:TF_BUILD=true
#    || Write-Error "Test failed."

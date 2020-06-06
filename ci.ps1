# See LICENSE in the project root for license information.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("restore", "build", "test")]
    [string] $Task,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet("Debug", "Release")]
    [Alias("c")] [string] $Configuration = "Release",

    [switch] $Thorough,
    [switch] $WindowsOnly
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

# ------------------------------------------------------------------------------

function Load-Xml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $path
    )

    Write-Verbose "Loading ""$path""."

    $content = Get-Content $path
    $xml = New-Object -TypeName System.Xml.XmlDocument
    $xml.PreserveWhitespace = $false
    $xml.LoadXml($content)

    $xml
}

# ------------------------------------------------------------------------------

function Select-Property {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Xml] $xml,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $property
    )

    $nodes = $xml | Select-Xml -XPath "//Project/PropertyGroup/$property"

    if ($nodes -eq $null -or $nodes.Count -ne 1) {
        Write-Error "Could not find the property named ""$property""."
    }

    $text = $nodes[0].Node.InnerText.Trim().Trim(";").Replace(" ", "")
    $text.Split(";")
}

# ------------------------------------------------------------------------------

function Get-TargetFrameworks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]] $platforms
    )

    '/p:TargetFrameworks=\"' + ($platforms -join ";") + '\"'
}

# ------------------------------------------------------------------------------

try {
    $props = Load-Xml (Join-Path $PSScriptRoot "Directory.Build.props" -Resolve)
    if ($WindowsOnly) {
        if ($Thorough) {
            $platforms = Select-Property $props "MaxClassicPlatforms"
        } else {
            $platforms = Select-Property $props "MinClassicPlatforms"
        }
    } else {
        if ($Thorough) {
            $platforms = Select-Property $props "MaxCorePlatforms"
        } else {
            $platforms = Select-Property $props "MinCorePlatforms"
        }
    }
    # TODO: dynamicic creation.
    $standards = "netstandard2.1", "netstandard2.0", "netstandard1.1"
    $buildPlatforms = $platforms + $standards
    $testPlatforms  = $platforms

    $args = "-c:$Configuration", "/p:Retail=true"

    switch ($Task) {
        'restore' {
            Write-Verbose "Restoring..."
            Write-Verbose "TargetFrameworks -> $buildPlatforms"
            $targetFrameworks = Get-TargetFrameworks $buildPlatforms

            #& dotnet restore $targetFrameworks
        }

        'build' {
            Write-Verbose "Building..."
            Write-Verbose "TargetFrameworks -> $buildPlatforms"
            $targetFrameworks = Get-TargetFrameworks $buildPlatforms

            #& dotnet build $targetFrameworks $args --no-restore
        }

        'test'  {
            Write-Verbose "Testing..."
            $testPlatforms = ($testPlatforms | where { $_ -notin "net45", "net451" })
            Write-Verbose "TargetFrameworks -> $testPlatforms"
            $targetFrameworks = Get-TargetFrameworks $testPlatforms

            #& dotnet test $targetFrameworks $args --no-build
        }
    }
}
catch {
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
}

# See LICENSE in the project root for license information.

#Requires -Version 7

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [switch] $NoTimestamp
)

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

function Get-Timestamp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $fileVersion
    )

    $parts = $fileVersion.Split(".")
    [int] $halfdays = $parts[2]
    [int] $seconds  = $parts[3]
    $orig = New-Object DateTime(2020, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc)

    $orig.AddSeconds(43200 * $halfdays + $seconds)
}

# ------------------------------------------------------------------------------

Hello "this is the script to extract informations from an assembly."

try {
    ___BEGIN___

    if (-not (Test-Path $Path)) {
        die "The file does NOT exist."
    }
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path (Get-Location) $Path -Resolve
    }

    $asm = [System.Reflection.AssemblyName]::GetAssemblyName($Path)
    # System.Diagnostics.FileVersionInfo
    $fileInfo = Get-Item $Path | % VersionInfo

    SAY-LOUDLY "`nAssembly's Full Name."
    say $asm.FullName

    if (-not $NoTimestamp) {
        SAY-LOUDLY "`nAssembly's Timestamp."
        say (Get-Timestamp $fileInfo.FileVersion).ToString("r")
    }

    SAY-LOUDLY "`nAssembly's Version Attributes."
    say ("AssemblyVersion      = {0}" -f $asm.Version)
    say ("FileVersion          = {0}" -f $fileInfo.FileVersion)
    say ("InformationalVersion = {0}" -f $fileInfo.ProductVersion)

    SAY-LOUDLY "`nFile Informations."
    Write-Host $fileInfo
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

################################################################################

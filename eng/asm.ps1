# See LICENSE in the project root for license information.

#Requires -Version 7

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $path
)

. (Join-Path $PSScriptRoot "abc.ps1")

try {
    ___BEGIN___

    if (-not (Test-Path $path)) {
        die "The file does NOT exist."
    }
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path -Resolve
    }

    $asm = [System.Reflection.Assembly]::LoadFile($path)
    # System.Diagnostics.FileVersionInfo
    $fileInfo = Get-Item $path | % VersionInfo

    SAY-LOUDLY "`nAssembly Full Name."
    say $asm.FullName

    SAY-LOUDLY "`nAssembly Version Attributes."
    say ("AssemblyVersion      = {0}" -f $asm.GetName().Version)
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

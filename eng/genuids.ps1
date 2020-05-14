# See LICENSE in the project root for license information.

#Requires -Version 7

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "common.ps1")

$fsi = (whereis "fsi.exe") ?? (Find-VsWhere -ExitOnError | Find-Fsi -ExitOnError)
$fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

$uids = & $fsi $fsx

say $uids

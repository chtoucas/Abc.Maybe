# See LICENSE in the project root for license information.

#Requires -Version 7

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "common.ps1")

$Script:___ExitOnError = $true

$fsi = whereis "fsi.exe"
$fsi ??= Find-VsWhere | Find-Fsi
$fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

$uids = & $fsi $fsx

say $uids

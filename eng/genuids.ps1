# See LICENSE in the project root for license information.

. (Join-Path $PSScriptRoot "common.ps1")

$fsi = Find-Fsi (Find-VsWhere) -ExitOnError
$fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

$uids = & $fsi $fsx

say $uids

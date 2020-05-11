# See LICENSE in the project root for license information.

. (Join-Path $PSScriptRoot "abc.ps1")

try {
    $fsi = Find-Fsi (Find-VsWhere) -ExitOnError
    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

    $uids = & $fsi $fsx

    say $uids
}
catch {
    ___ERR___ $_
}

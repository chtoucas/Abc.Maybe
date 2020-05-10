# See LICENSE in the project root for license information.

. (Join-Path $PSScriptRoot "abc.ps1")

try {
    Initialize-Env

    $fsi = Find-Fsi (Find-VsWhere) -ExitOnError
    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

    $uids = & $fsi $fsx

    say $uids
}
catch {
    confess $_
}
finally {
    Restore-Env
}
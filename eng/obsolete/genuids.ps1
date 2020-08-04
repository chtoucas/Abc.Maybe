# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2019 Narvalo.Org. All rights reserved.

#Requires -Version 7

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "..\utils.ps1")

# ------------------------------------------------------------------------------

function Generate-UIDs {
    [CmdletBinding()]
    param()

    say "Generating build UIDs."

    $fsi = (whereis "fsi.exe") ?? (Find-VsWhere -ExitOnError | Find-Fsi)
    if (-not $fsi) { return @("", "", "") }

    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve
    $uids = & $fsi $fsx

    if (-not $?) {
        warn "genuids.fsx did not complete succesfully."
        return @("", "", "")
    }

    ___debug "Build UIDs: ""$uids""."

    $uids.Split(";")
}

# ------------------------------------------------------------------------------

$fsi = (whereis "fsi.exe") ?? (Find-VsWhere -ExitOnError | Find-Fsi -ExitOnError)
$fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

$uids = & $fsi $fsx

say $uids

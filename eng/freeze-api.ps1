# See LICENSE.dotnet in the project root for license information.

# Adapted from https://github.com/dotnet/roslyn/tree/master/scripts/PublicApi

<#
.SYNOPSIS
Update the PublicAPI files.

.DESCRIPTION
Update PublicAPI.Shipped.txt and PublicAPI.Unshipped.txt:
- Unshipped members are moved to Shipped.
- Obsolete members are moved from Shipped to Unshipped and prefixed w/ *REMOVED*.
#>
[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "abc.ps1")

# ------------------------------------------------------------------------------

function Update-PublicAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $dir
    )

    SAY-LOUDLY "`nProcessing $dir"

    $shippedPath = Join-Path $dir "PublicAPI.Shipped.txt" -Resolve
    $shipped = Get-Content $shippedPath

    if (-not $shipped) { $shipped = @() }

    $unshippedPath = Join-Path $dir "PublicAPI.Unshipped.txt" -Resolve
    $unshipped = Get-Content $unshippedPath
    $removed = @()
    $removedPrefix = "*REMOVED*";

    foreach ($item in $unshipped) {
        if ($item.Length -gt 0) {
            if ($item.StartsWith($removedPrefix, "InvariantCultureIgnoreCase")) {
                $item = $item.Substring($removedPrefix.Length)
                $removed += $item
            }
            else {
                $shipped += $item
            }
        }
    }

    say "  Writing PublicAPI.Shipped.txt."
    $shipped `
        | Sort-Object `
        | where { -not $removed.Contains($_) } `
        | Out-File $shippedPath -Encoding UTF8

    say "  Writing PublicAPI.Unshipped.txt."
    "" | Out-File $unshippedPath -Encoding UTF8

    say-softly "Directory successfully processed."
}

# ------------------------------------------------------------------------------

Hello "this is the script to update the PublicAPI files."

try {
    ___BEGIN___

    foreach ($file in Get-ChildItem -Recurse -Include "PublicApi.Shipped.txt") {
        $dir = Split-Path -Parent $file
        Update-PublicAPI $dir
    }
}
catch {
    ___CATCH___
}
finally {
    ___END___
}

################################################################################

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

    Say-LOUDLY "`nProcessing $dir"

    $shippedPath = Join-Path $dir "PublicAPI.Shipped.txt" -Resolve
    $shipped = Get-Content $shippedPath

    if ($shipped -eq $null) {
        $shipped = @()
    }

    $unshippedPath = Join-Path $dir "PublicAPI.Unshipped.txt" -Resolve
    $unshipped = Get-Content $unshippedPath
    $removed = @()
    $removedPrefix = "*REMOVED*";

    foreach ($item in $unshipped) {
        if ($item.Length -gt 0) {
            if ($item.StartsWith($removedPrefix)) {
                $item = $item.Substring($removedPrefix.Length)
                $removed += $item
            }
            else {
                $shipped += $item
            }
        }
    }

    Say-Indent "Writing PublicAPI.Shipped.txt."
    $shipped `
        | Sort-Object `
        | ?{ -not $removed.Contains($_) } `
        | Out-File $shippedPath -Encoding UTF8

    Say-Indent "Writing PublicAPI.Unshipped.txt."
    "" | Out-File $unshippedPath -Encoding UTF8

    Say-Softly "Directory successfully processed."
}

# ------------------------------------------------------------------------------

Hello "this is the script to update the PublicAPI files."

try {
    Initialize-Env
    pushd $SRC_DIR

    foreach ($file in Get-ChildItem -Recurse -Include "PublicApi.Shipped.txt") {
        $dir = Split-Path -Parent $file
        Update-PublicAPI $dir
    }
}
catch {
    Confess $_
}
finally {
    popd
    Restore-Env
    Goodbye
}

################################################################################

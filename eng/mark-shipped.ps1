# Adapted from
# https://github.com/dotnet/roslyn/tree/master/scripts/PublicApi

<#
.SYNOPSIS
Update PublicAPI.Shipped.txt and PublicAPI.Unshipped.txt.
Unshipped members are moved to Shipped.
Obsolete members are moved from Shipped to Unshipped and prefixed w/ *REMOVED*.
#>
[CmdletBinding(PositionalBinding=$false)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "shared.ps1")

################################################################################

function mark-shipped([string] $dir) {
  $shippedFile = Join-Path $dir "PublicAPI.Shipped.txt"
  $shipped = Get-Content $shippedFile

  if ($shipped -eq $null) {
    $shipped = @()
  }

  $unshippedFile = Join-Path $dir "PublicAPI.Unshipped.txt"
  $unshipped = Get-Content $unshippedFile
  $removed = @()
  $removedPrefix = "*REMOVED*";

  say-loud "Processing $dir"

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

  $shipped | Sort-Object | ?{ -not $removed.Contains($_) } `
    | Out-File $shippedFile -Encoding UTF8

  "" | Out-File $unshippedFile -Encoding UTF8
}

################################################################################

try {
  pushd $ROOT_DIR

  foreach ($file in Get-ChildItem -Recurse -Include "PublicApi.Shipped.txt") {
    $dir = Split-Path -Parent $file
    mark-shipped $dir
  }
}
catch {
  croak ("An unexpected error occured: {0}." -f $_.Exception.Message) `
    -StackTrace $_.ScriptStackTrace
}
finally {
  popd
}

################################################################################

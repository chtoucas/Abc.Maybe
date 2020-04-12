# Adapted from
# https://github.com/dotnet/roslyn/tree/master/scripts/PublicApi

[CmdletBinding(PositionalBinding=$false)]
param ()

Set-StrictMode -version Latest
$ErrorActionPreference = "Stop"

. (join-path $PSScriptRoot "shared.ps1")

function mark-shipped([string] $dir) {
  $shippedFile = Join-Path $dir "PublicAPI.Shipped.txt"
  $shipped = Get-Content $shippedFile

  if ($null -eq $shipped) {
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
    | Out-File $shippedFile -Encoding Ascii

  "" | Out-File $unshippedFile -Encoding Ascii
}

try {
  pushd $ROOT_DIR

  foreach ($file in Get-ChildItem -re -in "PublicApi.Shipped.txt") {
    $dir = Split-Path -parent $file
    mark-shipped $dir
  }
}
catch {
  Write-Host $_
  Write-Host $_.Exception
  exit 1
}
finally {
  popd
}

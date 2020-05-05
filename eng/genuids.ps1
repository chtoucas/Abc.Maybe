#Requires -Version 4.0

. (Join-Path $PSScriptRoot "abc.ps1")

try {
    $vswhere = Find-VsWhere
    $fsi = Find-Fsi $vswhere
    $fsx = Join-Path $PSScriptRoot "genuids.fsx" -Resolve

    $uids = & $fsi $fsx

    Say $uids
}
catch {
    Write-Host "An unexpected error occured." -BackgroundColor Red -ForegroundColor Yellow
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
}
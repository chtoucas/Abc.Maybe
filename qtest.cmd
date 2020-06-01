:: Test harness (fast and simple).
:: Beware, will crash if the packages were not restored before.
::
:: Examples:
:: > qtest /p:DebugType=none
:: > qtest --no-build
:: > qtest --logger "trx;LogFileName=..\..\..\xunit.trx"
:: > qtest --filter Category=XXXX
:: > qtest --filter Priority!=XXX

@echo off
@setlocal

@call dotnet test %~dp0\src\Abc.Tests\Abc.Tests.csproj %* ^
    -v q ^
    --nologo ^
    --no-restore ^
    -c Release ^
    /p:RunAnalyzers=false

@endlocal
@exit /b %ERRORLEVEL%

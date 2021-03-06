:: Test harness (plain and simple).
:: Beware, will crash if the packages were not restored before.
:: > dotnet restore /p:SlimBuild=true
::
:: Examples:
:: > harness /p:DebugType=none
:: > harness --no-build
:: > harness --logger:"console;verbosity=normal"
:: > harness --logger "trx;LogFileName=..\..\..\__\xunit.trx"
:: > harness --filter Category=XXXX
:: > harness --filter Priority!=XXX

@echo off
@setlocal

@call dotnet test %~dp0\..\src\Abc.Tests\Abc.Tests.csproj %* ^
    --nologo ^
    --no-restore ^
    -c Release ^
    /p:RunAnalyzers=false ^
    /p:SlimBuild=true

@endlocal
@exit /b %ERRORLEVEL%

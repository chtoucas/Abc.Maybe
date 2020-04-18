:: Quickly run the test suite.
:: Beware, will crash if the packages were not restored before.
::
:: Examples:
:: > qtest --filter Category=XXXX
:: > qtest --filter Priority!=XXX -v q

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet test .\src\Abc.Tests\ %* -c Release --no-restore

@popd

@endlocal
@exit /b %ERRORLEVEL%

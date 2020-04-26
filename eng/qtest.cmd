:: Quickly run the test suite.
:: Beware, will crash if the packages were not correctly restored before
:: (correctly because we seem to have a problem since we enabled .NET 4.6.1).
::
:: Multi-targeting at once does not yet work:
:: > qtest /p:TargetFrameworks=\"netcoreapp3.1%2cnet461\"   <-- %2c is ; for MSBuild
:: What we can do:
:: - Test for netcoreapp3.1, nothing special, this is the default target.
:: - Test for net461
:: > qtest /p:TargetFramework=net461
::
:: Examples:
:: > qtest --no-restore
:: > qtest --filter Category=XXXX
:: > qtest --filter Priority!=XXX -v q

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet test .\src\Abc.Tests\ %* -c Release

@popd

@endlocal
@exit /b %ERRORLEVEL%

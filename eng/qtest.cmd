:: Quickly run the test suite.
:: Beware, will crash if the packages were not correctly restored before
:: (correctly because we seem to have a problem since we enabled .NET 4.6.1).
::
:: Multi-targeting at once does not work. What we can do:
:: - Test for the default target.
:: - Test for net461
:: > qtest /p:TargetFramework=net461
:: but we CANNOT write:
:: > qtest -f net461
:: because net461 is not listed in the supported framework within the project file.
::
:: Examples:
:: > qtest --no-restore
:: > qtest --filter Category=XXXX
:: > qtest --filter Priority!=XXX -v q

@echo off
@setlocal

@pushd %~dp0\..\src

@call dotnet test Abc.Tests %* -c Release

@popd

@endlocal
@exit /b %ERRORLEVEL%

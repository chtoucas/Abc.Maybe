:: Beware, will crash if the packages were not restored before.

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet test .\src\Abc.Tests\ --nologo -v q --no-restore ^
  --list-tests -c Release ^
  > .\__\test-suite.txt

@popd

@endlocal
@exit /b %ERRORLEVEL%

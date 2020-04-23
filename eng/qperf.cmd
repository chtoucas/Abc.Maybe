:: Quickly run the "perf" program.

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet run -c Release %* -p .\src\perf\

@popd

@endlocal
@exit /b %ERRORLEVEL%

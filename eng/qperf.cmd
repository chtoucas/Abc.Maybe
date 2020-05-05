:: Quickly run the "perf" program.

@echo off
@setlocal

@pushd %~dp0\..\src

@call dotnet run -c Release %* -p perf

@popd

@endlocal
@exit /b %ERRORLEVEL%

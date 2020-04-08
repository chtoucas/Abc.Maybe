:: Quickly run the "perf" program.

@echo off
@setlocal

@call dotnet run -c Release -p .\src\perf\ -- %*

@endlocal
@exit /b %ERRORLEVEL%

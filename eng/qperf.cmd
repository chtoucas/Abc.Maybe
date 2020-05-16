:: Quickly run the "perf" program.
:: TODO: check .NET Core tool for BenchmarkDotNet.

@echo off
@setlocal

@pushd %~dp0\..\src

@call dotnet run -c Release %* -p perf

@popd

@endlocal
@exit /b %ERRORLEVEL%

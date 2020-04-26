:: Build the solution for all supported frameworks.
:: Ensure that the XML comments are well-formed too.
::
:: Examples:
:: > qbuild -c Release                          --> default = Debug
:: > qbuild /p:Property=Value
:: > qbuild .\src\Abc.Maybe\
::
:: Standard settings:
:: > qbuild /p:SignAssembly=true
:: > qbuild /p:CheckForOverflowUnderflow=false
:: > qbuild /p:DebugType=embedded
:: > qbuild /p:GenerateDocumentationFile=true   --> always included but can be overriden
::
:: Project-specific options:
:: > qbuild /p:DisplaySettings=true
:: > qbuild /p:Retail=true
:: > qbuild /p:PatchEquality=true
:: > qbuild /p:HideInternals=true

@echo off
@setlocal

@pushd %~dp0\..

:: Remarks:
:: - GenerateDocumentationFile can be overriden
:: - TargetFrameworks can NOT be overriden
::   BUT one can use TargetFramework (no "s") to target a specific framework
::   Useful when we want to build projects like Abc.Tests, play or perf.
@call dotnet build ^
  /p:GenerateDocumentationFile=true %* ^
  /p:TargetFrameworks=\"net461;netstandard2.0;netstandard2.1;netcoreapp3.1\"

@popd

@endlocal
@exit /b %ERRORLEVEL%

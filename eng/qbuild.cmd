:: Build the solution for all supported frameworks.
:: Ensure that the XML comments are well-formed too (GenerateDocumentationFile)
:: and that InternalsVisibleTo works (SignAssembly).
::
:: Examples:
:: > qbuild -c Release                          --> default = Debug
:: > qbuild /p:Property=Value
:: > qbuild .\src\Abc.Maybe\
::
:: Standard settings:
:: > qbuild /p:SignAssembly=true                --> always included but can be overriden
:: > qbuild /p:CheckForOverflowUnderflow=false
:: > qbuild /p:DebugType=embedded
:: > qbuild /p:GenerateDocumentationFile=true   --> always included but can be overriden
::
:: Project-specific options: see Directory.Build.props
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
  /p:GenerateDocumentationFile=true ^
  /p:SignAssembly=true ^
  %* ^
  /p:TargetFrameworks=\"netstandard2.1;netstandard2.0;netcoreapp3.1;net461\"

@popd

@endlocal
@exit /b %ERRORLEVEL%

:: Build the solution for all supported frameworks.
:: Ensure that the XML comments are well-formed too.
::
:: Examples:
:: > qbuild -c Release
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

@call dotnet build ^
  /p:TargetFrameworks=\"net461;netstandard2.0;netstandard2.1;netcoreapp3.1\" ^
  /p:GenerateDocumentationFile=true %*

@popd

@endlocal
@exit /b %ERRORLEVEL%

:: Beware, will crash if the packages were not restored before.
::
:: Examples:
:: > qbuild -c Release
:: > qbuild /p:Property=Value
:: > qbuild .\src\Abc.Maybe\
:: > qbuild /p:TargetFrameworks=\"netstandard2.0;netstandard2.1;netcoreapp3.1\"
::
:: Standard settings:
:: > qbuild /p:SignAssembly=true
:: > qbuild /p:CheckForOverflowUnderflow=false
:: > qbuild /p:DebugType=embedded
:: > qbuild /p:GenerateDocumentationFile=true   --> always included but can be overriden
::                                              (to ensure that the XML comments are well-formed)
::
:: Project-specific options:
:: > qbuild /p:DisplaySettings=true
:: > qbuild /p:Retail=true
:: > qbuild /p:PatchEquality=true
:: > qbuild /p:HideInternals=true

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet build --no-restore /p:GenerateDocumentationFile=true %*

@popd

@endlocal
@exit /b %ERRORLEVEL%

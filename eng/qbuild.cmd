:: Beware, will crash if the packages were not restored before.
::
:: Examples:
:: > qbuild /p:Property=Value .\src\Abc.Maybe\
::
:: Standard settings:
:: > qbuild /p:SignAssembly=true
:: > qbuild /p:CheckForOverflowUnderflow=true
:: > qbuild /p:DebugType=embedded
:: > qbuild /p:GenerateDocumentationFile=true   --> always included but can be overriden
::                                              (to ensure that the XML comments are well-formed)
::
:: Local settings:
:: > qbuild /p:DisplaySettings=true
:: > qbuild /p:Retail=true
:: > qbuild /p:PatchEquality=true

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet build -c Release --no-restore /p:GenerateDocumentationFile=true %*

@popd

@endlocal
@exit /b %ERRORLEVEL%

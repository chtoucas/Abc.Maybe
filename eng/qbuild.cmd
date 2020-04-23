:: Beware, will crash if the packages were not restored before.

@echo off
@setlocal

@pushd %~dp0\..

@call dotnet build -c Release --no-restore %* ^
    /p:GenerateDocumentationFile=true ^
    /p:SignAssembly=true

@popd

@endlocal
@exit /b %ERRORLEVEL%

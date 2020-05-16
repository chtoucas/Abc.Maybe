:: Build the solution for all supported frameworks.
:: Ensure that the XML comments are well-formed too (GenerateDocumentationFile).
::
:: Remarks:
:: - GenerateDocumentationFile can be overriden
:: - TargetFrameworks can NOT be overriden
::   BUT one can use TargetFramework (no "s") to target a specific framework
::
:: When we want to build exe projects like Abc.Tests, play or perf for a
:: specific platform, specify the project path, eg .\src\Abc.Tests,
:: - Without TargetFramework, build for MaxApiPlatform (see Directory.Build.props).
:: - With    TargetFramework, build for TargetFramework.
::
:: The default behaviour is to build for all supported targets, except that
:: exe projects using a specific "TargetFramework", they are only built for it
:: (see above). To build **all** projects (exe projs included) for **all**
:: supported targets, use
::   /p:TargetFramework=
::
:: Examples:
:: > qtest --no-restore                         --> Be careful w/ this one
:: > qbuild -c Release                          --> default = Debug
:: > qbuild /p:Property=Value
:: > qbuild .\src\Abc.Maybe\
::
:: Standard settings (default = opposite value):
:: > qbuild /p:SignAssembly=true
:: > qbuild /p:CheckForOverflowUnderflow=false
:: > qbuild /p:GenerateDocumentationFile=true   --> always included but can be overriden
::
:: Local options (see Directory.Build.props):
:: > qbuild /p:DisplaySettings=true
:: > qbuild /p:Pack=true
:: > qbuild /p:PatchEquality=true
:: > qbuild /p:HideInternals=true

@echo off
@setlocal

@pushd %~dp0\..

:: Package restore: we MUST always include netcoreapp3.1 (MaxApiPlatform).
:: We do NOT include netstandard1.0 as it is only supported by Abc.Maybe.
@set fmks="netcoreapp3.1;netstandard2.1;netstandard2.0;net461"

:: Do not invoke "dotnet restore" before, it will fail if we specify eg
:: /p:TargetFramework= on the command-line.
@call dotnet build ^
  /p:GenerateDocumentationFile=true ^
  %* ^
  /p:TargetFrameworks=\"%fmks%\"

@popd

@endlocal
@exit /b %ERRORLEVEL%

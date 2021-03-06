[![NuGet](https://img.shields.io/nuget/v/Abc.Maybe.svg)](https://www.nuget.org/packages/Abc.Maybe/)
[![tests](https://github.com/chtoucas/Abc.Maybe/workflows/smoke/badge.svg)](https://github.com/chtoucas/Abc.Maybe/actions?query=workflow%3Asmoke)
[![Build Status](https://chtoucas.visualstudio.com/Abc.Maybe/_apis/build/status/Test?branchName=master&label=testing)](https://chtoucas.visualstudio.com/Abc.Maybe/_build?definitionId=1&branchName=master)
[![Coverlet](./__/coverlet.svg)](./__/coverlet.txt)

Abc.Maybe features an Option type for .NET, supports .NET Standard 1.1 or later.

- [Documentation](doc/README.md) (WIP)
- [Usage Guidelines](doc/usage-guidelines.md) (WIP)
- [Changelog](CHANGELOG)

### Objectives/Features

- [x] Being safe yet effective.
  - [x] Immutable.
  - [x] Curated API largely inspired by Haskell's Maybe.
  - [x] Extensible.
  - [x] Incurring no significant overhead when used wisely.
- [x] Being a good citizen of the .NET ecosystem.
  - [x] .NET Standard 1.1+.
  - [x] Aware of Nullable Reference Types (NRT).
  - [x] Debugger-friendly, Source Link.
  - [x] Strongly named assembly.
- [ ] Being well tested.
  - [x] 100% code coverage.
  - [x] Tested on Windows, Linux and MacOS.
  - [ ] Wide range of functional tests.
- [ ] Being well documented.
  - [ ] XML comments with code samples.
  - [ ] Quick start.
  - [ ] Provides guidance.

# Abc.Maybe

Abc.Maybe features an Option type for .NET.

|NuGet|Coverlet|OpenCover|
|-----|--------|---------|
| [![NuGet](https://img.shields.io/nuget/v/Abc.Maybe.svg)](https://www.nuget.org/packages/Abc.Maybe/) | [![Coverlet](./__/coverlet.svg)](./__/coverlet.txt) | [![OpenCover](./__/opencover.svg)](./__/opencover.txt) |

- [Documentation](doc/README.md)
- [Usage Guidelines](doc/usage-guidelines.md)
- [Changelog](CHANGELOG)
- [BSD 3-Clause "New" or "Revised" License](LICENSE)

__Objectives/Features__

- [x] Being safe yet effective.
  - [x] Immutable.
  - [x] Curated API largely inspired by Haskell's Maybe.
  - [x] Extensible.
  - [x] Incurring no significant overhead when used wisely.
- [ ] Being a good citizen of the .NET ecosystem.
  - [x] Equatable and comparable, both optionally structural.
  - [x] NRT-aware (NRT = Nullable Reference Types).
  - [x] Debugger-friendly.
  - [ ] Supported frameworks:
    - [x] .NET Standard 2.0 for recent systems.
    - [ ] .NET Framework 4.6.1 for older systems.
- [ ] Being well tested.
  - [x] 100% test coverage.
  - [ ] Functional tests.
- [ ] Being well documented.
  - [ ] XML comments with integrated examples.
  - [ ] Quick start (see below).
  - [ ] Provides guidance (see below).
  - [ ] Samples.

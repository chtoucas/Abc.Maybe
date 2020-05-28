# Abc.Maybe

Abc.Maybe features an Option type for .NET.

|NuGet|Coverlet|OpenCover|
|-----|--------|---------|
| [![NuGet](https://img.shields.io/nuget/v/Abc.Maybe.svg)](https://www.nuget.org/packages/Abc.Maybe/) | [![Coverlet](./__/coverlet.svg)](./__/coverlet.txt) | [![OpenCover](./__/opencover.svg)](./__/opencover.txt) |

- [Documentation](doc/README.md)
- [Usage Guidelines](doc/usage-guidelines.md)
- [Changelog](CHANGELOG)
- [BSD 3-Clause "New" or "Revised" License](LICENSE)

### NuGet Package

The NuGet package offers full support for:
- .NET Standard 1.1 or later.
- .NET Framework 4.5 or later.

The public API is not the same for all targets. We currently define two profiles,
one is for the [platforms implementing .NET Standard 2.1](https://dotnet.microsoft.com/platform/dotnet-standard#versions),
and the other is for those preceding it.

### Objectives/Features

- [x] Being safe yet effective.
  - [x] Immutable.
  - [x] Curated API largely inspired by Haskell's Maybe.
  - [x] Extensible.
  - [x] Incurring no significant overhead when used wisely.
- [x] Being a good citizen of the .NET ecosystem.
  - [x] .NET Standard 2.0 and .NET Framework 4.6.1.
  - [x] Aware of Nullable Reference Types (NRT).
  - [x] Debugger-friendly, Source Link.
  - [x] Strongly named assembly.
- [ ] Being well tested.
  - [x] 100% test coverage.
  - [ ] Wide range of functional tests.
- [ ] Being well documented.
  - [ ] XML comments with code samples.
  - [x] Quick start.
  - [ ] Provides guidance.
  - [ ] Samples.

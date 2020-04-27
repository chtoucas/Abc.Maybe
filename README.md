# Abc.Maybe

Abc.Maybe features an Option type for .NET.

|NuGet|Coverlet|OpenCover|
|-----|--------|---------|
| [![NuGet](https://img.shields.io/nuget/v/Abc.Maybe.svg)](https://www.nuget.org/packages/Abc.Maybe/) | [![Coverlet](./__/coverlet.svg)](./__/coverlet.txt) | [![OpenCover](./__/opencover.svg)](./__/opencover.txt) |

- [Documentation](doc/README.md)
- [Usage Guidelines](doc/usage-guidelines.md)
- [Changelog](CHANGELOG)
- [BSD 3-Clause "New" or "Revised" License](LICENSE)

__NuGet package__

The NuGet package targets:
- .NET Standard 2.1.
- .NET Standard 2.0.
- .NET Framework 4.6.1.

and offers basic support for .NET Standard 1.0 (_provided as is, untested_).

The public API is not the same for all targets. We currently define two profiles,
the scheme is rather simple,
- Profile 2.0 is for .NET Standard 2.0 and the legacy systems (.NET Framework
  4.6.1 and .NET Standard 1.0)
- Profile 2.1, a superset of the profile 2.0, is for .NET Standard 2.1.

__Objectives/Features__

- [x] Being safe yet effective.
  - [x] Immutable.
  - [x] Curated API largely inspired by Haskell's Maybe.
  - [x] Extensible.
  - [x] Incurring no significant overhead when used wisely.
- [x] Being a good citizen of the .NET ecosystem.
  - [x] Equatable and comparable, both optionally structural.
  - [x] NRT-aware (NRT = Nullable Reference Types).
  - [x] Debugger-friendly.
  - [x] .NET Standard 2.0, and the legacy .NET Framework 4.6.1.
- [ ] Being well tested.
  - [x] 100% test coverage.
  - [ ] Wide range of functional tests.
- [ ] Being well documented.
  - [ ] XML comments with integrated examples.
  - [x] Quick start.
  - [ ] Provides guidance.
  - [ ] Samples.

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
- .NET Standard 2.0 or later.
- .NET Framework 4.5.2 or later.

The public API is not the same for all targets. We currently define two profiles,
one is for the platforms implementing .NET Standard 2.1, and the other is for
those implementing .NET Standard 2.0, but also for versions of .NET Framework
not covered by .NET Standard 2.0; of course, the former profile is
a superset of the latter one.

### Objectives/Features

- [x] Being safe yet effective.
  - [x] Immutable.
  - [x] Curated API largely inspired by Haskell's Maybe.
  - [x] Extensible.
  - [x] Incurring no significant overhead when used wisely.
- [x] Being a good citizen of the .NET ecosystem.
  - [x] .NET Standard 2.0, and .NET Framework 4.6.1.
  - [x] Equatable and comparable, both optionally structural.
  - [x] NRT-aware (NRT = Nullable Reference Types).
  - [x] Debugger-friendly.
  - [x] Strongly named assembly.
- [ ] Being well tested.
  - [x] 100% test coverage.
  - [ ] Wide range of functional tests.
- [ ] Being well documented.
  - [ ] XML comments with integrated examples.
  - [x] Quick start.
  - [ ] Provides guidance.
  - [ ] Samples.

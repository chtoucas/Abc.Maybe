# Abc.Maybe

Abc.Maybe features an Option type for .NET.

|NuGet|Coverlet|OpenCover|
|-----|--------|---------|
| [![NuGet](https://img.shields.io/nuget/v/Abc.Maybe.svg)](https://www.nuget.org/packages/Abc.Maybe/) | [![Coverlet](./__/coverlet.svg)](./__/coverlet.txt) | [![OpenCover](./__/opencover.svg)](./__/opencover.txt) |

- [Documentation](doc/README.md)
- [Usage Guidelines](doc/usage-guidelines.md)
- [Changelog](CHANGELOG)
- [BSD 3-Clause "New" or "Revised" License](LICENSE)

## NuGet package

The NuGet package offers full support for:
- .NET Standard 1.0 / 2.0 / 2.1.
- .NET Framework 4.6.1.

The package is tested using .NET Core, all versions from 2.0 to 3.1, and the
.NET Framework, all versions from 4.5 to 4.8.
It should work with .NET Core 1.0 and 1.1 too, but keep in mind that I never
bothered to port the test suite to these platforms, and I do not intend to.

The public API is not the same for all targets. We currently define two profiles,
- one for .NET Standard 2.1.
- one for .NET Standard 1.0 / 2.0 and .NET Framework 4.6.1.
  Of course, it is a subset of the previous one.

## Objectives/Features

- [x] Being safe yet effective.
  - [x] Immutable.
  - [x] Curated API largely inspired by Haskell's Maybe.
  - [x] Extensible.
  - [x] Incurring no significant overhead when used wisely.
- [x] Being a good citizen of the .NET ecosystem.
  - [x] .NET Standard 2.0, and the legacy .NET Framework 4.6.1.
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

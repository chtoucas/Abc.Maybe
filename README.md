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

.NET Standard 1.0 is _provided as is_ (see caveats below).

The public API is not the same for all targets. We currently define two profiles,
- _API Profile 2.1_ is for .NET Standard 2.1.
- _API Profile 2.0_ is for .NET Standard 2.0 and the legacy systems (either
  platform or standard).

Of course, API Profile 2.1 is a superset of 2.0.

### Testing

We primarily run tests against the following targets:
- .NET Core 3.1.
- .NET Framework 4.6.1.

We also check that everything is fine with
- .NET Core, all versions from 2.0 to 3.0.
- .NET Framework, all versions from 4.5 to 4.8.

but only after we push a new package upstream, and it is not done automatically,
which means that it may take some time before a failing test is discovered (and
fixed). Everything should work with .NET Core 1.0/1.1 too, but keep in mind that
I never bothered to port the test suite to these platforms, and I do not intend
to.

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
  - [x] Strong named assembly.
- [ ] Being well tested.
  - [x] 100% test coverage.
  - [ ] Wide range of functional tests.
- [ ] Being well documented.
  - [ ] XML comments with integrated examples.
  - [x] Quick start.
  - [ ] Provides guidance.
  - [ ] Samples.

// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System.Diagnostics;
    using System.Diagnostics.CodeAnalysis;

    /// <summary>
    /// Provides static methods that help debug the code.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    [ExcludeFromCodeCoverage]
    internal static class DebugEx
    {
        /// <summary>
        /// Checks that <paramref name="value"/> is not null.
        /// <para>Strictly identical to Debug.Assert(value != null), but discards
        /// the false-positive warnings CS8601/CS8602 too.</para>
        /// </summary>
        // Added to silent CS8601/CS8602.
        // In VS 16.2.5 everything works fine but building the projects with the
        // command-line tool we get a lot of warnings.The problem
        // [seems](https://github.com/dotnet/roslyn/issues/37979) to be caused
        // by `Debug.Assert`, or is it a
        // [conflict](https://github.com/dotnet/csharplang/wiki/Nullable-Reference-Types-Preview#microsoftcodeanalysiscompilers-nuget-package-conflict)
        // with the package `Microsoft.CodeAnalysis.Compilers`? Another possibility is
        // that we use the version 2.0 of the .NET Standard. The real odd thing is that
        // `dotnet` also complains in `RELEASE` builds.If we comment out the debug
        // assertions, things work as expected (tag `ASSERT_NULL`).
        //
        // Maybe an [explanation](https://devblogs.microsoft.com/dotnet/announcing-net-core-3-0-release-candidate-1/):
        // > For technical and historical reasons, the .NET toolset (compilers,
        // > NuGet client, MSBuild, …) is duplicated between Visual Studio and
        // > the .NET Core SDK.
        [Conditional("DEBUG")]
        public static void NotNull<T>(T value) where T : class
            => Debug.Assert(value != null);
    }
}

// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Diagnostics.CodeAnalysis;

    using Xunit;

    /// <summary>
    /// Attribute that is applied to a method to indicate that it is a fact that
    /// should be skipped by the test runner.
    /// <para>
    /// The test is skipped __silently__ when the compiler symbol
    /// <c>SILENT_SKIP</c> is set.
    /// </para>
    /// </summary>
    public sealed class SkippedFactAttribute : FactAttribute
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="SkippedFactAttribute"/> class.
        /// </summary>
        [SuppressMessage("Usage", "CA1801:Review unused parameters", Justification = "SILENT_SKIP is set")]
        public SkippedFactAttribute(string reason)
        {
#if !SILENT_SKIP
            Skip = reason;
#endif
        }
    }
}

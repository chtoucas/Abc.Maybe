// See LICENSE in the project root for license information.

namespace Abc
{
    /// <summary>
    /// Nongeneric interface for <see cref="Maybe{T}"/> so that we can perform
    /// structural comparisons between maybe's with heterogeneous generic type
    /// parameters.
    /// </summary>
    internal interface IMaybe
    {
        /// <summary>
        /// Checks whether the current instance does hold a value or not.
        /// </summary>
        bool IsSome { get; }

        /// <summary>
        /// Gets the enclosed value.
        /// <para>You MUST check IsSome before calling this property.</para>
        /// </summary>
        object? Value { get; }
    }
}

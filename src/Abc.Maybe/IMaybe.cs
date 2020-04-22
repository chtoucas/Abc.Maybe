// See LICENSE in the project root for license information.

#if NONGENERIC_MAYBE

namespace Abc
{
    // FIXME: nongeneric Maybe for structural comparisons.

    /// <summary>
    /// Nongeneric interface for <see cref="Maybe{T}"/> so that we can perform
    /// structural comparisons between heterogeneous types.
    /// </summary>
    internal interface IMaybe
    {
        bool IsSome { get; }
        object? Value { get; }
    }
}

#endif

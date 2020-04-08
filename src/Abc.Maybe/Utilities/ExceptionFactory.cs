// See LICENSE in the project root for license information.

#pragma warning disable CA1303 // Do not pass literals as localized parameters.

namespace Abc.Utilities
{
    using System;
    using System.Diagnostics;
    using System.Diagnostics.Contracts;

    /// <summary>
    /// Provides static methods to create exceptions.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    internal static class ExceptionFactory
    {
        public static readonly InvalidOperationException EmptySequence
            = new InvalidOperationException("The sequence was empty.");

        public static readonly NotSupportedException ReadOnlyCollection
            = new NotSupportedException("The collection is read-only.");

        [Pure]
        [DebuggerStepThrough]
        public static ArgumentException InvalidType(
            string paramName, Type expected, object obj) =>
            new ArgumentException(
                $"The object should be of type {expected} but it is of type {obj.GetType()}.",
                paramName);

        public static readonly ArgumentException MaybeComparer_InvalidType
            = new ArgumentException("Type of argument is not compatible with MaybeComparer<T>.");

        public static readonly InvalidOperationException Maybe_NoValue
            = new InvalidOperationException("The object does not contain any value.");

        public static readonly InvalidCastException FromMaybe_NoValue
            = new InvalidCastException("The object does not contain any value.");
    }
}

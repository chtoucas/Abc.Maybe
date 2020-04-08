// See LICENSE in the project root for license information.

#pragma warning disable CA1303 // Do not pass literals as localized parameters.

namespace Abc.Utilities
{
    using System;
    using System.Diagnostics.Contracts;

    /// <summary>
    /// Provides static methods to create exceptions.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    internal static class ExceptionFactory
    {
        public static InvalidOperationException ControlFlow
            => new InvalidOperationException(
                "The flow of execution just reached a section of the code that should have been unreachable."
                + $"{Environment.NewLine}Most certainly signals a coding error. Please report.");

        [Pure]
        public static InvalidOperationException Faillible_NoValue
            => new InvalidOperationException(
                "The object does not contain any value."
                + $"{Environment.NewLine}You should have checked that the property IsError is not true.");

        [Pure]
        public static InvalidOperationException Faillible_NoInnerException
            => new InvalidOperationException(
                "The object does not contain any exception."
                + $"{Environment.NewLine}You should have checked that the property IsError is true.");
    }
}

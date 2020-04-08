// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System;
    using System.Diagnostics;

    /// <summary>
    /// Decorating a parameter with this attribute informs the Code Analysis
    /// tool that the method is validating the parameter against null value.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    /// <remarks>
    /// Using this attribute suppresses the CA1062 warning.
    /// </remarks>
    [AttributeUsage(AttributeTargets.Parameter, AllowMultiple = false)]
    internal sealed class ValidatedNotNullAttribute : Attribute { }

    internal static class Require
    {
        [DebuggerStepThrough]
        public static void NotNull<T>([ValidatedNotNull] T value, string paramName)
            where T : class
        {
            if (value is null)
            {
                throw new ArgumentNullException(paramName);
            }
        }
    }
}

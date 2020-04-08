// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System;

    internal static class Thunks
    {
        /// <summary>
        /// Represents the action that does nothing.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Action Noop = () => { };
    }

    internal static class Thunks<T>
    {
        /// <summary>
        /// Represents the identity map.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Func<T, T> Ident = x => x;

        /// <summary>
        /// Represents the action that does nothing.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Action<T> Noop = _ => { };
    }
}

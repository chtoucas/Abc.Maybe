// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;

    /// <summary>
    /// Represents the empty iterator.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    [DebuggerDisplay("Count = 0")]
    internal sealed class EmptyIterator<T> : IEnumerator<T>
    {
        public static readonly IEnumerator<T> Instance = new EmptyIterator<T>();

        private EmptyIterator() { }

        // No one should ever call these properties.
        [ExcludeFromCodeCoverage] [MaybeNull] public T Current => default;
        [ExcludeFromCodeCoverage] [MaybeNull] object IEnumerator.Current => default;

        [Pure] public bool MoveNext() => false;

        void IEnumerator.Reset() { }
        void IDisposable.Dispose() { }
    }
}

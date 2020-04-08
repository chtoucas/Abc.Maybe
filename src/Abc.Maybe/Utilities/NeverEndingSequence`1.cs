// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;

    [DebuggerDisplay("Count = ∞")]
    internal sealed class NeverEndingSequence<T> : IEnumerable<T>, IEnumerator<T>
    {
        [NotNull] private readonly T _element;

        public NeverEndingSequence([DisallowNull] T element)
        {
            _element = element;
        }

        // IEnumerable<T>
        [Pure] public IEnumerator<T> GetEnumerator() => this;

        // IEnumerable
        [Pure] IEnumerator IEnumerable.GetEnumerator() => this;

        // IEnumerator<T>
        [Pure] public T Current => _element;

        // IEnumerator
        [Pure] object IEnumerator.Current => _element;
        [Pure] public bool MoveNext() => true;
        void IEnumerator.Reset() { }

        // IDisposable
        void IDisposable.Dispose() { }
    }
}

// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel;
    using System.Diagnostics;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;
    using EF = Abc.Utilities.ExceptionFactory;

    // Inner error (?) but more importantly aggregate errors.

    [DebuggerDisplay("{" + nameof(DebuggerDisplay) + ",nq}")]
    public sealed partial class Err<T> : Result<T>
    {
        internal static readonly Err<T> NoValue = new Err<T>();

        internal Err()
        {
            Message = "No value";
            IsNone = true;
        }

        public Err(string message)
        {
            Message = message ?? throw new Anexn(nameof(message));
            IsNone = false;
        }

        public override bool IsError => true;

        internal override T ValueIntern { [DoesNotReturn] get => throw EF.ControlFlow; }

        public bool IsNone { get; }

        public string Message { get; }

        [ExcludeFromCodeCoverage]
        [DebuggerBrowsable(DebuggerBrowsableState.Never)]
        [EditorBrowsable(EditorBrowsableState.Never)]
        private string DebuggerDisplay => $"IsNone = {IsNone}";

        public override string ToString()
            => $"Err({Message})";

        [Pure]
        public Err<TOther> WithType<TOther>()
            => IsNone ? Err<TOther>.NoValue : new Err<TOther>(Message);

        [Pure]
        public override Result<T> OrElse(Result<T> other)
            => other;
    }

    // Query Expression Pattern.
    public partial class Err<T>
    {
        [Pure]
        public override Result<TResult> Select<TResult>(Func<T, TResult> selector)
        {
            return WithType<TResult>();
        }

        [Pure]
        public override Result<T> Where(Func<T, bool> predicate)
            => this;

        [Pure]
        public override Result<TResult> SelectMany<TMiddle, TResult>(
            Func<T, Result<TMiddle>> selector,
            Func<T, TMiddle, TResult> resultSelector)
        {
            return WithType<TResult>();
        }

        [Pure]
        public override Result<TResult> Join<TInner, TKey, TResult>(
            Result<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector)
        {
            return WithType<TResult>();
        }

        [Pure]
        public override Result<TResult> Join<TInner, TKey, TResult>(
            Result<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector,
            IEqualityComparer<TKey>? comparer)
        {
            return WithType<TResult>();
        }
    }
}

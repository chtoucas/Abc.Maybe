// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;

    /// <summary>
    /// Represents the successful outcome of a computation.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    public sealed partial class Ok<T> : Result<T>
    {
        internal Ok([DisallowNull] T value)
        {
            Value = value;
        }

        public override bool IsError => false;

        [NotNull] public T Value { get; }

        [NotNull] internal override T ValueIntern => Value;

        [Pure]
        public override string ToString()
            => $"Ok({Value})";

        [Pure]
        public override Result<T> OrElse(Result<T> other)
            => this;
    }

    // Query Expression Pattern.
    public partial class Ok<T>
    {
        [Pure]
        public override Result<TResult> Select<TResult>(Func<T, TResult> selector)
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return Result.Of(selector(Value));
        }

        [Pure]
        public override Result<T> Where(Func<T, bool> predicate)
        {
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            return predicate(Value) ? this : None;
        }

        [Pure]
        public override Result<TResult> SelectMany<TMiddle, TResult>(
            Func<T, Result<TMiddle>> selector,
            Func<T, TMiddle, TResult> resultSelector)
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            Result<TMiddle> middle = selector(Value);
            if (middle is Err<TMiddle> err) { return err.WithType<TResult>(); }

            return Result.Of(resultSelector(Value, middle.ValueIntern));
        }

        [Pure]
        public override Result<TResult> Join<TInner, TKey, TResult>(
            Result<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector)
        {
            if (inner is null) { throw new Anexn(nameof(inner)); }
            if (outerKeySelector is null) { throw new Anexn(nameof(outerKeySelector)); }
            if (innerKeySelector is null) { throw new Anexn(nameof(innerKeySelector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            return JoinImpl(
                inner,
                outerKeySelector,
                innerKeySelector,
                resultSelector,
                EqualityComparer<TKey>.Default);
        }

        [Pure]
        public override Result<TResult> Join<TInner, TKey, TResult>(
            Result<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector,
            IEqualityComparer<TKey>? comparer)
        {
            if (inner is null) { throw new Anexn(nameof(inner)); }
            if (outerKeySelector is null) { throw new Anexn(nameof(outerKeySelector)); }
            if (innerKeySelector is null) { throw new Anexn(nameof(innerKeySelector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            return JoinImpl(
                inner,
                outerKeySelector,
                innerKeySelector,
                resultSelector,
                comparer ?? EqualityComparer<TKey>.Default);
        }

        [Pure]
        private Result<TResult> JoinImpl<TInner, TKey, TResult>(
            Result<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector,
            IEqualityComparer<TKey> comparer)
        {
            if (!inner.IsError)
            {
                TKey outerKey = outerKeySelector(Value);
                TKey innerKey = innerKeySelector(inner.ValueIntern);

                if (comparer.Equals(outerKey, innerKey))
                {
                    return Result.Of(resultSelector(Value, inner.ValueIntern));
                }
            }

            return Result<TResult>.None;
        }
    }
}

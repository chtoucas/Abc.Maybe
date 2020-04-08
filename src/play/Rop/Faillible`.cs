// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;

    // When the error is in fact an exception.
    // Warning, it is a really bad idea to try to replace the standard
    // exception system...
    // Not only is it antipattern but also I don't have practical use cases for
    // it; maybe when we have a collection of results and when we wish to filter
    // out the bad ones?

    public static class Faillible
    {
        public static readonly Faillible<Unit> Unit = Succeed(default(Unit));
        public static readonly Faillible<Unit> Zero = Faillible<Unit>.None;

        [Pure]
        public static Faillible<T> Succeed<T>([AllowNull] T value)
            => value is null ? Faillible<T>.None : new Faillible<T>.Success(value);

        [Pure]
        public static Faillible<T> Threw<T>(Exception exception)
            => new Faillible<T>.Exceptional(exception);
    }

    /// <summary>
    /// Represents the outcome of a computation, either a success or an exception.
    /// </summary>
    public abstract partial class Faillible<T>
    {
        public static readonly Faillible<T> None = new Success();

        public abstract bool Threw { get; }

        [MaybeNull] public abstract T Value { get; }

        // REVIEW: NRT?
        public abstract Exception InnerException { get; }

        [return: NotNull]
        public abstract T ValueOrRethrow();

        public abstract Maybe<T> ToMaybe();

        [Pure]
        [SuppressMessage("Naming", "CA1716:Identifiers should not match keywords", Justification = "Visual Basic: use an escaped name")]
        public abstract Faillible<T> OrElse(Faillible<T> other);
    }

    // Query Expression Pattern.
    public partial class Faillible<T>
    {
        [Pure]
        [SuppressMessage("Naming", "CA1716:Identifiers should not match keywords", Justification = "Query Expression Pattern")]
        public abstract Faillible<TResult> Select<TResult>(Func<T, TResult> selector);

        [Pure]
        public abstract Faillible<T> Where(Func<T, bool> predicate);

        [Pure]
        public abstract Faillible<TResult> SelectMany<TMiddle, TResult>(
            Func<T, Faillible<TMiddle>> selector,
            Func<T, TMiddle, TResult> resultSelector);

        [Pure]
        public abstract Faillible<TResult> Join<TInner, TKey, TResult>(
            Faillible<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector);

        [Pure]
        public abstract Faillible<TResult> Join<TInner, TKey, TResult>(
            Faillible<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector,
            IEqualityComparer<TKey>? comparer);
    }
}

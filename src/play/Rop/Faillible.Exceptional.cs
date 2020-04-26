// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.CodeAnalysis;
    using System.Runtime.ExceptionServices;

    using Anexn = System.ArgumentNullException;
    using EF = Abc.Utilities.ExceptionFactory;

    public abstract partial class Faillible<T>
    {
        internal sealed partial class Exceptional : Faillible<T>
        {
            public Exceptional(Exception exception)
            {
                InnerException = exception ?? throw new Anexn(nameof(exception));
            }

            public override bool Threw => true;

            public override T Value
            {
                [DoesNotReturn]
                get => throw EF.Faillible_NoValue;
            }

            public override Exception InnerException { get; }

            public Faillible<TOther> WithGenericType<TOther>()
                => new Faillible<TOther>.Exceptional(InnerException);

#if !(NETSTANDARD2_0 || NETFRAMEWORK) // Nullable attributes (DoesNotReturn)
            [DoesNotReturn]
            public override T ValueOrRethrow()
            {
                ExceptionDispatchInfo.Capture(InnerException).Throw();
                return default;
            }
#else
            public override T ValueOrRethrow()
            {
                ExceptionDispatchInfo.Capture(InnerException).Throw();
                // BONSANG! .NET Framework.
                return default!;
            }
#endif

            public override Maybe<T> ToMaybe()
                => Maybe<T>.None;

            public override Faillible<T> OrElse(Faillible<T> other)
                => other;
        }

        // Query Expression Pattern.
        internal partial class Exceptional
        {
            public override Faillible<TResult> Select<TResult>(Func<T, TResult> selector)
                => new Faillible<TResult>.Exceptional(InnerException);

            public override Faillible<T> Where(Func<T, bool> predicate)
                => this;

            public override Faillible<TResult> SelectMany<TMiddle, TResult>(
                Func<T, Faillible<TMiddle>> selector,
                Func<T, TMiddle, TResult> resultSelector)
            {
                return new Faillible<TResult>.Exceptional(InnerException);
            }

            public override Faillible<TResult> Join<TInner, TKey, TResult>(
                Faillible<TInner> inner,
                Func<T, TKey> outerKeySelector,
                Func<TInner, TKey> innerKeySelector,
                Func<T, TInner, TResult> resultSelector)
            {
                return new Faillible<TResult>.Exceptional(InnerException);
            }

            public override Faillible<TResult> Join<TInner, TKey, TResult>(
                Faillible<TInner> inner,
                Func<T, TKey> outerKeySelector,
                Func<TInner, TKey> innerKeySelector,
                Func<T, TInner, TResult> resultSelector,
                IEqualityComparer<TKey>? comparer)
            {
                return new Faillible<TResult>.Exceptional(InnerException);
            }
        }
    }
}

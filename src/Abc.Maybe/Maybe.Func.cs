// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;

    // Helpers for functions in the Kleisli category.
    public partial class Maybe
    {
        /// <seealso cref="Maybe{T}.Bind"/>
        [Pure]
        public static Maybe<TResult> Invoke<TSource, TResult>(
            this Func<TSource, Maybe<TResult>> @this,
            Maybe<TSource> maybe)
        {
            return maybe.Bind(@this);
        }

        [Pure]
        public static Maybe<TResult> Compose<TSource, TMiddle, TResult>(
            this Func<TSource, Maybe<TMiddle>> @this,
            Func<TMiddle, Maybe<TResult>> other,
            TSource value)
        {
            if (@this is null) { throw new Anexn(nameof(@this)); }

            return @this(value).Bind(other);
        }

        [Pure]
        public static Maybe<TResult> ComposeBack<TSource, TMiddle, TResult>(
            this Func<TMiddle, Maybe<TResult>> @this,
            Func<TSource, Maybe<TMiddle>> other,
            TSource value)
        {
            if (other is null) { throw new Anexn(nameof(other)); }

            return other(value).Bind(@this);
        }
    }

    // Lift, promote functions to maybe's.
    // Very much like lifted operators for nullables.
    // https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/nullable-value-types#lifted-operators
    public partial class Maybe
    {
        /// <seealso cref="Maybe{T}.Select"/>
        [Pure]
        public static Maybe<TResult> Lift<TSource, TResult>(
            this Func<TSource, TResult> @this,
            Maybe<TSource> maybe)
        {
            return maybe.Select(@this);
        }

        /// <seealso cref="Maybe{T}.ZipWith"/>
        [Pure]
        public static Maybe<TResult> Lift<T1, T2, TResult>(
            this Func<T1, T2, TResult> @this,
            Maybe<T1> first,
            Maybe<T2> second)
        {
            if (@this is null) { throw new Anexn(nameof(@this)); }

            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome
                ? Of(@this(first.Value!, second.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Lift<T1, T2, T3, TResult>(
            this Func<T1, T2, T3, TResult> @this,
            Maybe<T1> first,
            Maybe<T2> second,
            Maybe<T3> third)
        {
            if (@this is null) { throw new Anexn(nameof(@this)); }

            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && third.IsSome
                ? Of(@this(first.Value!, second.Value!, third.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Lift<T1, T2, T3, T4, TResult>(
            this Func<T1, T2, T3, T4, TResult> @this,
            Maybe<T1> first,
            Maybe<T2> second,
            Maybe<T3> third,
            Maybe<T4> fourth)
        {
            if (@this is null) { throw new Anexn(nameof(@this)); }

            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && third.IsSome && fourth.IsSome
                ? Of(@this(first.Value!, second.Value!, third.Value!, fourth.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Lift<T1, T2, T3, T4, T5, TResult>(
            this Func<T1, T2, T3, T4, T5, TResult> @this,
            Maybe<T1> first,
            Maybe<T2> second,
            Maybe<T3> third,
            Maybe<T4> fourth,
            Maybe<T5> fifth)
        {
            if (@this is null) { throw new Anexn(nameof(@this)); }

            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && third.IsSome && fourth.IsSome && fifth.IsSome
                ? Of(@this(first.Value!, second.Value!, third.Value!, fourth.Value!, fifth.Value!))
                : Maybe<TResult>.None;
        }
    }

    // Helpers for Maybe<T> where T is a function.
    public partial class Maybe
    {
        #region Invoke()

        [Pure]
        public static Maybe<TResult> Invoke<TSource, TResult>(
            this Maybe<Func<TSource, TResult>> @this,
            TSource value)
        {
            // return @this.Select(f => f(value));
            // BONSANG! When IsSome is true, Value is NOT null.
            return @this.IsSome ? Of(@this.Value!(value)) : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Invoke<T1, T2, TResult>(
            this Maybe<Func<T1, T2, TResult>> @this,
            T1 first,
            T2 second)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return @this.IsSome ? Of(@this.Value!(first, second)) : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Invoke<T1, T2, T3, TResult>(
            this Maybe<Func<T1, T2, T3, TResult>> @this,
            T1 first,
            T2 second,
            T3 third)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return @this.IsSome ? Of(@this.Value!(first, second, third))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Invoke<T1, T2, T3, T4, TResult>(
            this Maybe<Func<T1, T2, T3, T4, TResult>> @this,
            T1 first,
            T2 second,
            T3 third,
            T4 fourth)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return @this.IsSome ? Of(@this.Value!(first, second, third, fourth))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Invoke<T1, T2, T3, T4, T5, TResult>(
            this Maybe<Func<T1, T2, T3, T4, T5, TResult>> @this,
            T1 first,
            T2 second,
            T3 third,
            T4 fourth,
            T5 fifth)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return @this.IsSome ? Of(@this.Value!(first, second, third, fourth, fifth))
                : Maybe<TResult>.None;
        }

        #endregion

        #region Apply()

        [Pure]
        public static Maybe<TResult> Apply<TSource, TResult>(
            this Maybe<Func<TSource, TResult>> @this,
            Maybe<TSource> maybe)
        {
            // return @this.Bind(f => maybe.Select(f));
            // BONSANG! When IsSome is true, Value is NOT null.
            return @this.IsSome && maybe.IsSome ? Of(@this.Value!(maybe.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Apply<T1, T2, TResult>(
            this Maybe<Func<T1, T2, TResult>> @this,
            Maybe<T1> first,
            Maybe<T2> second)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && @this.IsSome
                ? Of(@this.Value!(first.Value!, second.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Apply<T1, T2, T3, TResult>(
            this Maybe<Func<T1, T2, T3, TResult>> @this,
            Maybe<T1> first,
            Maybe<T2> second,
            Maybe<T3> third)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && third.IsSome && @this.IsSome
                ? Of(@this.Value!(first.Value!, second.Value!, third.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Apply<T1, T2, T3, T4, TResult>(
            this Maybe<Func<T1, T2, T3, T4, TResult>> @this,
            Maybe<T1> first,
            Maybe<T2> second,
            Maybe<T3> third,
            Maybe<T4> fourth)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && third.IsSome && fourth.IsSome && @this.IsSome
                ? Of(@this.Value!(first.Value!, second.Value!, third.Value!, fourth.Value!))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Maybe<TResult> Apply<T1, T2, T3, T4, T5, TResult>(
            this Maybe<Func<T1, T2, T3, T4, T5, TResult>> @this,
            Maybe<T1> first,
            Maybe<T2> second,
            Maybe<T3> third,
            Maybe<T4> fourth,
            Maybe<T5> fifth)
        {
            // BONSANG! When IsSome is true, Value is NOT null.
            return first.IsSome && second.IsSome && third.IsSome && fourth.IsSome && fifth.IsSome && @this.IsSome
                ? Of(@this.Value!(first.Value!, second.Value!, third.Value!, fourth.Value!, fifth.Value!))
                : Maybe<TResult>.None;
        }

        #endregion
    }
}

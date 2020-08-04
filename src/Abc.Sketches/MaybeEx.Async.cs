// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Threading.Tasks;

    using Anexn = System.ArgumentNullException;

    // REVIEW: async vs async...
    // Maybe<Task<T>>, Task<Maybe<T>>, Func<Task<>> vs Task<>.

    // Async methods.
    public partial class MaybeEx
    {
        // Not an extension method: we already have an instance method with the
        // exact same signature, yet they differ, the instance method uses eager
        // validation, this one does not.
        [Pure]
        public static Task<Maybe<TResult>> BindAsync<T, TResult>(
            Maybe<T> maybe,
            Func<T, Task<Maybe<TResult>>> binder)
        {
            return BindAsync(maybe, binder, false);
        }

        [Pure]
        public static async Task<Maybe<TResult>> BindAsync<T, TResult>(
            this Maybe<T> @this,
            Func<T, Task<Maybe<TResult>>> binder,
            bool continueOnCapturedContext)
        {
            if (binder is null) { throw new Anexn(nameof(binder)); }

            return @this.TryGetValue(out T value)
                ? await binder(value).ConfigureAwait(continueOnCapturedContext)
                : Maybe<TResult>.None;
        }

        // Not an extension method: we already have an instance method with the
        // exact same signature, yet they differ, the instance method uses eager
        // validation, this one does not.
        [Pure]
        public static Task<Maybe<TResult>> SelectAsync<T, TResult>(
            Maybe<T> maybe,
            Func<T, Task<TResult>> selector)
        {
            return SelectAsync(maybe, selector, false);
        }

        [Pure]
        public static async Task<Maybe<TResult>> SelectAsync<T, TResult>(
            this Maybe<T> @this,
            Func<T, Task<TResult>> selector,
            bool continueOnCapturedContext)
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return @this.TryGetValue(out T value)
                ? Maybe.Of(await selector(value).ConfigureAwait(continueOnCapturedContext))
                : Maybe<TResult>.None;
        }

        // Not an extension method: we already have an instance method with the
        // exact same signature, yet they differ, the instance method uses eager
        // validation, this one does not.
        [Pure]
        public static Task<Maybe<T>> OrElseAsync<T>(
            Maybe<T> maybe,
            Func<Task<Maybe<T>>> other)
        {
            return OrElseAsync(maybe, other, false);
        }

        [Pure]
        public static async Task<Maybe<T>> OrElseAsync<T>(
            this Maybe<T> @this,
            Func<Task<Maybe<T>>> other,
            bool continueOnCapturedContext)
        {
            if (other is null) { throw new Anexn(nameof(other)); }

            return @this.IsNone ? await other().ConfigureAwait(continueOnCapturedContext)
                : @this;
        }

        //
        // More async methods.
        //

        [Pure]
        public static async Task<Maybe<T>> WhereAsync<T>(
            this Maybe<T> @this,
            Func<T, Task<bool>> predicate)
        {
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            return await @this.BindAsync(__).ConfigureAwait(false);

            async Task<Maybe<T>> __(T x)
                => await predicate(x).ConfigureAwait(false) ? @this : Maybe<T>.None;
        }
    }
}

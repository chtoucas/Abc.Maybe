// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Threading.Tasks;

    using Anexn = System.ArgumentNullException;

    // REVIEW: Async vs async...
    // Maybe<Task<T>>, Task<Maybe<T>>, Func<Task<>> vs Task<>.

    // Async methods.
    // Not extension methods: we already have instance methods with the same
    // names.
    public partial class MaybeEx
    {
        [Pure]
        public static Task<Maybe<TResult>> BindAsync<T, TResult>(
            Maybe<T> maybe,
            Func<T, Task<Maybe<TResult>>> binder)
        {
            return BindAsync(maybe, binder, false);
        }

        [Pure]
        public static async Task<Maybe<TResult>> BindAsync<T, TResult>(
            Maybe<T> maybe,
            Func<T, Task<Maybe<TResult>>> binder,
            bool continueOnCapturedContext)
        {
            if (binder is null) { throw new Anexn(nameof(binder)); }

            return maybe.TryGetValue(out T value)
                ? await binder(value).ConfigureAwait(continueOnCapturedContext)
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Task<Maybe<TResult>> SelectAsync<T, TResult>(
            Maybe<T> maybe,
            Func<T, Task<TResult>> selector)
        {
            return SelectAsync(maybe, selector, false);
        }

        [Pure]
        public static async Task<Maybe<TResult>> SelectAsync<T, TResult>(
            Maybe<T> maybe,
            Func<T, Task<TResult>> selector,
            bool continueOnCapturedContext)
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return maybe.TryGetValue(out T value)
                ? Maybe.Of(await selector(value).ConfigureAwait(continueOnCapturedContext))
                : Maybe<TResult>.None;
        }

        [Pure]
        public static Task<Maybe<T>> OrElseAsync<T>(
            Maybe<T> maybe,
            Func<Task<Maybe<T>>> other)
        {
            return OrElseAsync(maybe, other, false);
        }

        [Pure]
        public static async Task<Maybe<T>> OrElseAsync<T>(
            Maybe<T> maybe,
            Func<Task<Maybe<T>>> other,
            bool continueOnCapturedContext)
        {
            if (other is null) { throw new Anexn(nameof(other)); }

            return maybe.IsNone ? await other().ConfigureAwait(continueOnCapturedContext)
                : maybe;
        }

        //
        // More async methods.
        //

        [Pure]
        public static async Task<Maybe<T>> WhereAsync<T>(
            Maybe<T> maybe,
            Func<T, Task<bool>> predicate)
        {
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            return await maybe.BindAsync(__).ConfigureAwait(false);

            async Task<Maybe<T>> __(T x)
                => await predicate(x).ConfigureAwait(false) ? maybe : Maybe<T>.None;
        }
    }
}

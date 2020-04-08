// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Threading.Tasks;

    using Anexn = System.ArgumentNullException;

    // Async methods.
    // These async methods use eager validation and discard the context when
    // they resume.
    public partial struct Maybe<T>
    {
        [Pure]
        public Task<Maybe<TResult>> BindAsync<TResult>(
            Func<T, Task<Maybe<TResult>>> binder)
        {
            // Check arg eagerly.
            if (binder is null) { throw new Anexn(nameof(binder)); }

            return BindAsyncImpl(binder);
        }

        [Pure]
        private async Task<Maybe<TResult>> BindAsyncImpl<TResult>(
            Func<T, Task<Maybe<TResult>>> binder)
        {
            return _isSome ? await binder(_value).ConfigureAwait(false)
                : Maybe<TResult>.None;
        }

        [Pure]
        public Task<Maybe<TResult>> SelectAsync<TResult>(
            Func<T, Task<TResult>> selector)
        {
            // Check arg eagerly.
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return SelectAsyncImpl(selector);
        }

        [Pure]
        private async Task<Maybe<TResult>> SelectAsyncImpl<TResult>(
            Func<T, Task<TResult>> selector)
        {
            return _isSome ? Maybe.Of(await selector(_value).ConfigureAwait(false))
                : Maybe<TResult>.None;
        }

        [Pure]
        public Task<Maybe<T>> OrElseAsync(Func<Task<Maybe<T>>> other)
        {
            // Check arg eagerly.
            if (other is null) { throw new Anexn(nameof(other)); }

            return OrElseAsyncImpl(other);
        }

        [Pure]
        private async Task<Maybe<T>> OrElseAsyncImpl(Func<Task<Maybe<T>>> other)
        {
            return _isSome ? this : await other().ConfigureAwait(false);
        }
    }
}

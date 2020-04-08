// See LICENSE in the project root for license information.

namespace Abc.Edu.Fx
{
    using System;
    using System.Threading.Tasks;

    using Abc.Utilities;

    // Task<T> is both a monad and a comonad.
    //
    // Adapted/copied from:
    // - https://blogs.msdn.microsoft.com/pfxteam/2013/04/03/tasks-monads-and-linq/
    // - https://blogs.msdn.microsoft.com/pfxteam/2012/08/15/implementing-then-with-await/
    // See also:
    // - https://blogs.msdn.microsoft.com/pfxteam/2010/11/21/processing-sequences-of-asynchronous-operations-with-tasks/
    public static class TaskT
    {
        #region Monad

        internal static Task<T> Return<T>(T value)
            => Task.FromResult(value);

        public static Task<T> Flatten<T>(this Task<Task<T>> square)
        {
            Require.NotNull(square, nameof(square));

            return square.Result;
        }

        public static async Task<TResult> Bind<TSource, TResult>(
            this Task<TSource> @this,
            Func<TSource, Task<TResult>> binder)
        {
            Require.NotNull(@this, nameof(@this));
            Require.NotNull(binder, nameof(binder));

            return await binder(await @this.ConfigureAwait(false)).ConfigureAwait(false);
        }

        #endregion

        #region Comonad

        //public static Task<TResult> Extend<TSource, TResult>(
        //    this Task<TSource> @this,
        //    Func<Task<TSource>, TResult> func)
        //{
        //    Require.NotNull(@this, nameof(@this));

        //    return @this.ContinueWith(func);
        //}

        public static T Extract<T>(this Task<T> value)
        {
            Require.NotNull(value, nameof(value));

            return value.Result;
        }

        public static Task<Task<T>> Duplicate<T>(this Task<T> value)
            => Task.FromResult(value);

        #endregion

        public static async Task<TResult> ContinueWith<TSource, TResult>(
            this Task<TSource> @this,
            Task<TResult> other)
        {
            // > return await source.Bind(_ => other);

            Require.NotNull(@this, nameof(@this));
            Require.NotNull(other, nameof(other));

            await @this.ConfigureAwait(false);
            return await other.ConfigureAwait(false);
        }
    }
}

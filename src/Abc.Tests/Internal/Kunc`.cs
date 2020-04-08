// See LICENSE in the project root for license information.

using System;
using System.Threading.Tasks;

using Abc;

internal static class Kunc<T, TResult>
    where T : notnull
    where TResult : notnull
{
    // Kleisli null.
    public static readonly Func<T, Maybe<TResult>> Null = null!;

    public static readonly Func<T, Maybe<TResult>> Any = _ => throw new UnexpectedCallException();

    public static readonly Func<T, Task<Maybe<TResult>>> NullAsync = null!;

    public static readonly Func<T, Task<Maybe<TResult>>> AnySync = _ => throw new UnexpectedCallException();

    public static readonly Func<T, Task<Maybe<TResult>>> AnyAsync = async _ =>
    {
        await Task.Yield();
        throw new UnexpectedCallException();
    };
}

internal static class Kunc<T1, T2, TResult>
    where T1 : notnull
    where T2 : notnull
    where TResult : notnull
{
    public static readonly Func<T1, T2, Maybe<TResult>> Null = null!;

    public static readonly Func<T1, T2, Maybe<TResult>> Any = (x, y) => throw new UnexpectedCallException();
}

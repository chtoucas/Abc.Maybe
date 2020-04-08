// See LICENSE in the project root for license information.

using System;
using System.Diagnostics.Contracts;

internal static class Thunk<T>
    where T : notnull
{
    /// <summary>
    /// Obtains a function that ignores its parameters and always returns
    /// <paramref name="result"/>.
    /// </summary>
    [Pure]
    public static Func<T, TResult> Return<TResult>(TResult result)
        where TResult : notnull
        => _ => result;
}

internal static class Thunk<T1, T2>
    where T1 : notnull
    where T2 : notnull
{
    /// <summary>
    /// Obtains a function that ignores its parameters and always returns
    /// <paramref name="result"/>.
    /// </summary>
    [Pure]
    public static Func<T1, T2, TResult> Return<TResult>(TResult result)
        where TResult : notnull
        => (x, y) => result;
}

internal static class Thunk<T1, T2, T3>
    where T1 : notnull
    where T2 : notnull
    where T3 : notnull
{
    /// <summary>
    /// Obtains a function that ignores its parameters and always returns
    /// <paramref name="result"/>.
    /// </summary>
    [Pure]
    public static Func<T1, T2, T3, TResult> Return<TResult>(TResult result)
        where TResult : notnull
        => (x, y, z) => result;
}

internal static class Thunk<T1, T2, T3, T4>
    where T1 : notnull
    where T2 : notnull
    where T3 : notnull
    where T4 : notnull
{
    /// <summary>
    /// Obtains a function that ignores its parameters and always returns
    /// <paramref name="result"/>.
    /// </summary>
    [Pure]
    public static Func<T1, T2, T3, T4, TResult> Return<TResult>(TResult result)
        where TResult : notnull
        => (x, y, z, a) => result;
}

internal static class Thunk<T1, T2, T3, T4, T5>
    where T1 : notnull
    where T2 : notnull
    where T3 : notnull
    where T4 : notnull
    where T5 : notnull
{
    /// <summary>
    /// Obtains a function that ignores its parameters and always returns
    /// <paramref name="result"/>.
    /// </summary>
    [Pure]
    public static Func<T1, T2, T3, T4, T5, TResult> Return<TResult>(TResult result)
        where TResult : notnull
        => (x, y, z, a, b) => result;
}

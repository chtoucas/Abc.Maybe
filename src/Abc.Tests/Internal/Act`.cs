// See LICENSE in the project root for license information.

using System;

internal static class Act
{
    public static readonly Action Null = null!;

    public static readonly Action Noop = () => { };
}

internal static class Act<T>
    where T : notnull
{
    public static readonly Action<T> Null = null!;

    public static readonly Action<T> Noop = _ => { };
}

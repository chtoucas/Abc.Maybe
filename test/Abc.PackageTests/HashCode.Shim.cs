// See LICENSE in the project root for license information.

#if (NET45 || NET451 || NET452 || NET46) // System.HashCode

using System;
using System.Diagnostics.Contracts;

/// <summary>
/// Shim for System.HashCode.
/// </summary>
internal static class HashCode
{
    // The multiplier (31) is chosen because the multiplication 31 * h
    // can be replaced by: (h << 5) - h.
    // For more explanations, see "Effective Java" by Joshua Bloch.
    private const int Init = 17;
    private const int Hash0 = 31 * Init;

    [Pure]
    public static int Combine(int h1, int h2)
    {
        // int hash = 17;
        // hash = 31 * hash + h1;
        // hash = 31 * hash + h2;
        // return hash
        int hash = Hash0 + h1;
        return (hash << 5) - hash + h2;
    }

    [Pure]
    public static int Combine(int h1, int h2, int h3)
        => Combine(Combine(h1, h2), h3);

    [Pure]
    public static int Combine(int h1, int h2, int h3, int h4)
        => Combine(Combine(h1, h2), Combine(h3, h4));

    [Pure]
    public static int Combine<T1, T2>(T1 value1, T2 value2)
        where T1 : struct where T2 : struct
        => Combine(value1.GetHashCode(), value2.GetHashCode());

    [Pure]
    public static int Combine<T1, T2, T3>(T1 value1, T2 value2, T3 value3)
        where T1 : struct where T2 : struct where T3 : struct
        => Combine(
            Combine(value1.GetHashCode(), value2.GetHashCode()),
            value3.GetHashCode());

    [Pure]
    public static int Combine<T1, T2, T3, T4>(T1 value1, T2 value2, T3 value3, T4 value4)
        where T1 : struct where T2 : struct where T3 : struct where T4 : struct
        => Combine(
            Combine(value1.GetHashCode(), value2.GetHashCode()),
            Combine(value3.GetHashCode(), value4.GetHashCode()));
}

#endif
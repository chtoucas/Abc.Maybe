// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

public static class ArrayEx
{
    public static T[] Empty<T>() => EmptyArray_<T>.Value;

    private static class EmptyArray_<T>
    {
#pragma warning disable CA1825 // Avoid zero-length array allocations
        internal static readonly T[] Value = new T[0];
#pragma warning restore CA1825
    }

}

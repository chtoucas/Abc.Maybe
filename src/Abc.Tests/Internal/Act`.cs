// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

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

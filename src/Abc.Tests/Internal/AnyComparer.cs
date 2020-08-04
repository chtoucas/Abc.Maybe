// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

using System.Collections;

internal sealed class AnyComparer : IComparer
{
    public int Compare(object? x, object? y) => throw new UnexpectedCallException();
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

using System;

internal sealed class AnyDisposable : IDisposable
{
    public AnyDisposable() { }

    public bool WasDisposed { get; private set; }

    public void Dispose()
    {
        WasDisposed = true;
    }
}

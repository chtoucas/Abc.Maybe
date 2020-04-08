// See LICENSE in the project root for license information.

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

// See LICENSE in the project root for license information.

using System.Collections;

internal sealed class AnyComparer : IComparer
{
    public int Compare(object? x, object? y) => throw new UnexpectedCallException();
}

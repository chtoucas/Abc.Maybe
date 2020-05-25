﻿// See LICENSE in the project root for license information.

using System.Collections;
#if NETCOREAPP1_x
using System.Collections.Generic;
#endif

// Shorter strings come first.
internal sealed class ReversedLengthComparer : IComparer
{
    public int Compare(object? x, object? y)
    {
        if (x is string left && y is string right)
        {
            return -left.Length.CompareTo(right.Length);
        }

        // TODO: à revoir.
#if NETCOREAPP1_x
        return Comparer<object>.Default.Compare(x!, y!);
#else
        return Comparer.Default.Compare(x, y);
#endif
    }
}

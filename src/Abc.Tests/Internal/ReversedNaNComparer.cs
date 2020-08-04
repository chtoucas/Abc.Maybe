// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;

// Shorter strings come first.
internal sealed class ReversedNaNComparer : IComparer
{
    public int Compare(object? x, object? y)
    {
        if (x is float f0)
        {
            float right = Convert.ToSingle(y, CultureInfo.InvariantCulture);
            return Single.IsNaN(f0) ? 1
                : Single.IsNaN(right) ? -1
                : Comparer<float>.Default.Compare(f0, right);
        }

        if (x is double d0)
        {
            double right = Convert.ToDouble(y, CultureInfo.InvariantCulture);
            return Double.IsNaN(d0) ? 1
                : Double.IsNaN(right) ? -1
                : Comparer<double>.Default.Compare(d0, right);
        }

        // TODO: à revoir.
#if NETSTANDARD1_x
        return Comparer<object>.Default.Compare(x!, y!);
#else
        return Comparer.Default.Compare(x, y);
#endif
    }
}

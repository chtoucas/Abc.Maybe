// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

#if NETSTANDARD1_x || (NETFRAMEWORK && !(NET48 || NET472 || NET471)) // Enumerable.Append
#define NO_LINQ_APPEND_PREPEND
#endif

namespace Abc.Utilities
{
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;

    internal static class EnumerableX
    {
#if NO_LINQ_APPEND_PREPEND // Enumerable.Append
        [Pure]
        public static IEnumerable<TSource> Append<TSource>(
            IEnumerable<TSource> source,
            TSource element)
        {
            if (source is null) { throw new System.ArgumentNullException(nameof(source)); }

            return __();

            IEnumerable<TSource> __()
            {
                foreach (var item in source)
                {
                    yield return item;
                }

                yield return element;
            }
        }
#else
        [Pure]
        // Code size = 8 bytes.
        [System.Runtime.CompilerServices.MethodImpl(
            System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
        public static IEnumerable<TSource> Append<TSource>(
            IEnumerable<TSource> source,
            TSource element)
        {
            return System.Linq.Enumerable.Append(source, element);
        }
#endif
    }
}

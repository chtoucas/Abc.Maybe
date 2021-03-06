﻿// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Linq
{
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Anexn = System.ArgumentNullException;

    public static partial class Qperators
    {
        /// <summary>
        /// Returns the element at the specified index in a sequence or
        /// <see cref="Maybe{TSource}.None"/> if the index is out of range.
        /// </summary>
        /// <remarks>
        /// For <c>IEnumerable&lt;T?&gt;</c>, prefer
        /// <see cref="Enumerable.ElementAtOrDefault"/> over this method.
        /// </remarks>
        /// <exception cref="Anexn"><paramref name="source"/> is null.</exception>
        [Pure]
        public static Maybe<TSource> ElementAtOrNone<TSource>(
            this IEnumerable<TSource> source,
            int index)
        {
            if (source is null) { throw new Anexn(nameof(source)); }

            if (index < 0) { return Maybe<TSource>.None; }

            // Fast track.
            if (source is IList<TSource> list)
            {
                return index < list.Count ? Maybe.Of(list[index]) : Maybe<TSource>.None;
            }

            // Slow track.
            using var iter = source.GetEnumerator();

            while (iter.MoveNext())
            {
                if (index == 0)
                {
                    return Maybe.Of(iter.Current);
                }

                index--;
            }

            return Maybe<TSource>.None;
        }
    }
}

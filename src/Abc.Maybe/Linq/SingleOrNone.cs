// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Anexn = System.ArgumentNullException;

    // For IEnumerable<T?>, prefer SingleOrDefault() over SingleOrNone().
    public static partial class Qperators
    {
        /// <summary>
        /// Returns the only element of a sequence, or
        /// <see cref="Maybe{TSource}.None"/> if the sequence is empty or
        /// contains more than one element.
        /// <para>Here we differ in behaviour from the standard query
        /// <c>SingleOrDefault</c> which throws an exception if there is more
        /// than one element in the sequence.</para>
        /// </summary>
        /// <exception cref="Anexn"><paramref name="source"/> is null.</exception>
        [Pure]
        public static Maybe<TSource> SingleOrNone<TSource>(this IEnumerable<TSource> source)
        {
            if (source is null) { throw new Anexn(nameof(source)); }

            // Fast track.
            if (source is IList<TSource> list)
            {
                return list.Count == 1 ? Maybe.Of(list[0]) : Maybe<TSource>.None;
            }

            // Slow track.
            using var iter = source.GetEnumerator();

            // Return None if the sequence is empty.
            if (!iter.MoveNext()) { return Maybe<TSource>.None; }

            var item = iter.Current;

            // Return None if there is one more element.
            return iter.MoveNext() ? Maybe<TSource>.None : Maybe.Of(item);
        }

        /// <summary>
        /// Returns the only element of a sequence that satisfies
        /// a specified predicate, or <see cref="Maybe{TSource}.None"/>
        /// if no such element exists or there are more than one of them.
        /// <para>Here we differ in behaviour from the standard query
        /// <c>SingleOrDefault</c> which throws an exception if more than one
        /// element satisfying the predicate.</para>
        /// </summary>
        /// <exception cref="Anexn"><paramref name="source"/> or
        /// <paramref name="predicate"/> is null.</exception>
        [Pure]
        public static Maybe<TSource> SingleOrNone<TSource>(
            this IEnumerable<TSource> source,
            Func<TSource, bool> predicate)
        {
            if (source is null) { throw new Anexn(nameof(source)); }
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            var seq = source.Where(predicate);

            using var iter = seq.GetEnumerator();

            // Return None if the sequence is empty.
            if (!iter.MoveNext()) { return Maybe<TSource>.None; }

            var item = iter.Current;

            // Return None if there is one more element.
            return iter.MoveNext() ? Maybe<TSource>.None : Maybe.Of(item);
        }
    }
}

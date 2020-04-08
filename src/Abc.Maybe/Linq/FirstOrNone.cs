// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Anexn = System.ArgumentNullException;

    // For IEnumerable<T?>, prefer FirstOrDefault() over FirstOrNone().
    public static partial class Qperators
    {
        /// <summary>
        /// Returns the first element of a sequence, or
        /// <see cref="Maybe{TSource}.None"/> if the sequence contains no elements.
        /// </summary>
        [Pure]
        public static Maybe<TSource> FirstOrNone<TSource>(
            this IEnumerable<TSource> source)
        {
            if (source is null) { throw new Anexn(nameof(source)); }

            // Fast track.
            if (source is IList<TSource> list)
            {
                return list.Count > 0 ? Maybe.Of(list[0]) : Maybe<TSource>.None;
            }

            // Slow track.
            using var iter = source.GetEnumerator();

            return iter.MoveNext() ? Maybe.Of(iter.Current) : Maybe<TSource>.None;
        }

        /// <summary>
        /// Returns the first element of a sequence that satisfies the
        /// <paramref name="predicate"/>, or <see cref="Maybe{TSource}.None"/>
        /// if no such element is found.
        /// </summary>
        [Pure]
        public static Maybe<TSource> FirstOrNone<TSource>(
            this IEnumerable<TSource> source,
            Func<TSource, bool> predicate)
        {
            if (source is null) { throw new Anexn(nameof(source)); }
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            var seq = source.Where(predicate);

            using var iter = seq.GetEnumerator();

            return iter.MoveNext() ? Maybe.Of(iter.Current) : Maybe<TSource>.None;
        }
    }
}

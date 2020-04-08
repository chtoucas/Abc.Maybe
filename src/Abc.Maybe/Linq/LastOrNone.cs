// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;

    // For IEnumerable<T?>, prefer LastOrDefault() over LastOrNone().
    public static partial class Qperators
    {
        /// <summary>
        /// Returns the last element of a sequence, or
        /// <see cref="Maybe{TSource}.None"/> if the sequence contains no elements.
        /// </summary>
        [Pure]
        public static Maybe<TSource> LastOrNone<TSource>(
            this IEnumerable<TSource> source)
        {
            if (source is null) { throw new Anexn(nameof(source)); }

            // Fast track.
            if (source is IList<TSource> list)
            {
                return list.Count > 0 ? Maybe.Of(list[list.Count - 1]) : Maybe<TSource>.None;
            }

            // Slow track.
            using var iter = source.GetEnumerator();

            if (!iter.MoveNext()) { return Maybe<TSource>.None; }

            TSource item;
            do
            {
                item = iter.Current;
            }
            while (iter.MoveNext());

            return Maybe.Of(item);
        }

        /// <summary>
        /// Returns the last element of a sequence that satisfies the
        /// <paramref name="predicate"/>, or <see cref="Maybe{TSource}.None"/>
        /// if no such element is found.
        /// </summary>
        [Pure]
        public static Maybe<TSource> LastOrNone<TSource>(
            this IEnumerable<TSource> source,
            Func<TSource, bool> predicate)
        {
            if (source is null) { throw new Anexn(nameof(source)); }
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            // Fast track.
            if (source is IList<TSource> list)
            {
                for (int i = list.Count - 1; i >= 0; --i)
                {
                    TSource item = list[i];
                    if (predicate(item))
                    {
                        return Maybe.Of(item);
                    }
                }

                return Maybe<TSource>.None;
            }

            // Slow track.
            using (var iter = source.GetEnumerator())
            {
                while (iter.MoveNext())
                {
                    TSource item = iter.Current;
                    if (predicate(item))
                    {
                        while (iter.MoveNext())
                        {
                            TSource element = iter.Current;
                            if (predicate(element))
                            {
                                item = element;
                            }
                        }

                        return Maybe.Of(item);
                    }
                }
            }

            return Maybe<TSource>.None;
        }
    }
}

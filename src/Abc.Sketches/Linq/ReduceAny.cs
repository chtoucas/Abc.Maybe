// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;
    using EF = Abc.Utilities.ExceptionFactory;

    // Aggregation: Reduce.
    public partial class QperatorsEx
    {
        [Pure]
        public static Maybe<TSource> ReduceAny<TSource>(
            this IEnumerable<TSource> source,
            Func<TSource, TSource, Maybe<TSource>> accumulator)
        {
            if (source is null) { throw new Anexn(nameof(source)); }
            if (accumulator is null) { throw new Anexn(nameof(accumulator)); }

            using var iter = source.GetEnumerator();

            if (!iter.MoveNext()) { throw EF.EmptySequence; }

            var r = Maybe.Of(iter.Current);
            while (iter.MoveNext())
            {
                r = r.Bind(x => accumulator(x, iter.Current));
            }
            return r;
        }

        [Pure]
        public static Maybe<TSource> ReduceAny<TSource>(
            this IEnumerable<TSource> source,
            Func<TSource, TSource, Maybe<TSource>> accumulator,
            Func<Maybe<TSource>, bool> predicate)
        {
            if (source is null) { throw new Anexn(nameof(source)); }
            if (accumulator is null) { throw new Anexn(nameof(accumulator)); }
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            using var iter = source.GetEnumerator();

            if (!iter.MoveNext()) { throw EF.EmptySequence; }

            var r = Maybe.Of(iter.Current);
            while (predicate(r) && iter.MoveNext())
            {
                r = r.Bind(x => accumulator(x, iter.Current));
            }
            return r;
        }
    }
}

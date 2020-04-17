// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Anexn = System.ArgumentNullException;

    // Extension methods for Maybe<T> where T is enumerable.
    public partial class MaybeEx
    {
        [Pure]
        public static IEnumerable<T> ValueOrEmpty<T>(
            this Maybe<IEnumerable<T>> @this)
        {
            return @this.ValueOrElse(Enumerable.Empty<T>());
        }

        [Pure]
        public static Maybe<IEnumerable<T>> EmptyIfNone<T>(
            this Maybe<IEnumerable<T>> @this)
        {
            return @this.OrElse(Maybe.EmptyEnumerable<T>());
        }
    }

    // LINQ extensions for IEnumerable<Maybe<T>>.
    public partial class MaybeEx
    {
        // What it should do:
        // - If the input sequence is empty,
        //   returns Maybe.Of(empty sequence).
        // - If all maybe's in the input sequence are empty,
        //   returns Maybe<IEnumerable<T>>.None.
        // - Otherwise,
        //   returns Maybe.Of(sequence of values).
        // See also CollectAny().
        [Pure]
        public static Maybe<IEnumerable<T>> Collect<T>(IEnumerable<Maybe<T>> source)
        {
            return source.Aggregate(
                Maybe.EmptyEnumerable<T>(),
                (x, y) => x.ZipWith(y, Enumerable.Append));
        }

        // Aggregation: monadic sum.
        // For Maybe<T>, it amounts to returning the first non-empty item, or
        // an empty maybe if they are all empty.
        [Pure]
        public static Maybe<T> FirstOrNone<T>(IEnumerable<Maybe<T>> source)
        {
            return source.FirstOrDefault(x => !x.IsNone);
        }

        #region Aggregation Sum()

        [Pure]
        public static Maybe<T> Sum<T>(
            IEnumerable<Maybe<T>> source, Func<T, T, T> add, T zero)
        {
            if (add is null) { throw new Anexn(nameof(add)); }

            Maybe<IEnumerable<T>> aggr = Collect(source);

            return aggr.Select(__);

            T __(IEnumerable<T> seq)
            {
                T sum = zero;
                foreach (var item in seq)
                {
                    sum = add(sum, item);
                }
                return sum;
            }
        }

        // Add Sum() for all simple value types.

        [Pure]
        public static Maybe<int> Sum(IEnumerable<Maybe<int>> source)
        {
            Maybe<IEnumerable<int>> aggr = Collect(source);

            return aggr.Select(Enumerable.Sum);
        }

        #endregion
    }
}

// See LICENSE in the project root for license information.

namespace Abc.Linq.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    // Apply standard LINQ ops to an inner enumerable.
    // Maybe not a good idea. For instance Select() will be very confusing (to
    // say the least): is it the one from Maybe<T> or the LINQ op defined here?
    // Of course, it is OK when the signatures differ which is for instance the
    // case w/ SelectMany().
    public static partial class MaybeEnumerable { }

    public partial class MaybeEnumerable
    {
        [Pure]
        public static Maybe<IEnumerable<TResult>> Select<T, TResult>(
            this Maybe<IEnumerable<T>> source,
            Func<T, TResult> selector)
        {
            return source.Select(seq => seq.Select(selector));
        }

        [Pure]
        public static Maybe<IEnumerable<T>> Where<T>(
            this Maybe<IEnumerable<T>> source,
            Func<T, bool> predicate)
        {
            return source.Select(seq => seq.Where(predicate));
        }

        [Pure]
        public static Maybe<IEnumerable<TResult>> SelectMany<T, TMiddle, TResult>(
            this Maybe<IEnumerable<T>> source,
            Func<T, IEnumerable<TMiddle>> selector,
            Func<T, TMiddle, TResult> resultSelector)
        {
            return source.Select(seq => seq.SelectMany(selector, resultSelector));
        }
    }
}

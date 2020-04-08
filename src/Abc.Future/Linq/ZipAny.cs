// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    public partial class QperatorsEx
    {
        [Pure]
        public static IEnumerable<TResult> ZipAny<T1, T2, TResult>(
            this IEnumerable<T1> first,
            IEnumerable<T2> second,
            Func<T1, T2, Maybe<TResult>> resultSelector)
        {
#if true || PLAIN_LINQ
            return Maybe.CollectAny(first.Zip(second, resultSelector));
#else
            return from x in first.Zip(second, resultSelector)
                   where x.IsSome
                   select x.Value;
#endif
        }
    }
}

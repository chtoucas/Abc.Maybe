// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Anexn = System.ArgumentNullException;

    public static partial class Qperators
    {
        [Pure]
        public static IEnumerable<TSource> WhereAny<TSource>(
            this IEnumerable<TSource> source,
            Func<TSource, Maybe<bool>> predicate)
        {
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            return from x in source
                   let m = predicate(x)
                   where m.IsSome && m.Value
                   select x;
        }
    }
}

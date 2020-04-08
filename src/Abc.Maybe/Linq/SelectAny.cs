// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

#if !PLAIN_LINQ
    using Anexn = System.ArgumentNullException;
#endif

    public static partial class Qperators
    {
        [Pure]
        public static IEnumerable<TResult> SelectAny<TSource, TResult>(
            this IEnumerable<TSource> source,
            Func<TSource, Maybe<TResult>> selector)
        {
#if PLAIN_LINQ
            return Maybe.CollectAny(source.Select(selector));
#else
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return from x in source
                   let m = selector(x)
                   where m.IsSome
                   select m.Value;
#endif
        }
    }
}

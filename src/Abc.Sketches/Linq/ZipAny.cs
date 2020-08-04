// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    public partial class QperatorsEx
    {
        [Pure]
        [RejectedApi]
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

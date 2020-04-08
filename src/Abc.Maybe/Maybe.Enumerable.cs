// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    // Helpers for Maybe<IEnumerable<T>>.
    public partial class Maybe
    {
        // Obtains the maybe of the empty sequence.
        // Beware, this is not the same as the empty maybe of type
        // IEnumerable<T>.
        [Pure]
        public static Maybe<IEnumerable<T>> EmptyEnumerable<T>() =>
            MaybeEnumerable_<T>.Empty;

        private static class MaybeEnumerable_<T>
        {
            internal static readonly Maybe<IEnumerable<T>> Empty =
                Of(Enumerable.Empty<T>());
        }
    }

    // LINQ extensions for IEnumerable<Maybe<T>> but not extension methods since
    // they are not for IEnumerable<T>, also to avoid conflicts w/ the standard
    // LINQ ops.
    public partial class Maybe
    {
        // Filtering: CollectAny (deferred).
        // Behaviour:
        // - If the input sequence is empty
        //     or all maybe's in the input sequence are empty
        //   returns an empty sequence.
        // - Otherwise,
        //   returns the sequence of values.
        [Pure]
        public static IEnumerable<T> CollectAny<T>(IEnumerable<Maybe<T>> source)
        {
            return from x in source where x.IsSome select x.Value;
        }
    }
}

// See LICENSE in the project root for license information.

namespace Abc.Extensions
{
    using System;
    using System.Collections.Generic;
    using System.Collections.Specialized;
    using System.Diagnostics.Contracts;

    using Abc.Linq;

    // REVIEW: MayGetValues, Maybe<IEnumerable>?

    /// <summary>
    /// Provides extension methods for <see cref="NameValueCollection"/>.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    public static class NameValueCollectionX
    {
        [Pure]
        public static Maybe<string> MayGetSingle(this NameValueCollection @this, string name)
        {
            return from values in @this.MayGetValues(name)
                   where values.Length == 1
                   select values[0];
        }

        [Pure]
        public static Maybe<string[]> MayGetValues(
            this NameValueCollection @this, string name)
        {
            if (@this is null) { throw new ArgumentNullException(nameof(@this)); }

            return Maybe.Of(@this.GetValues(name));
        }

        [Pure]
        public static IEnumerable<T> ParseValues<T>(
            this NameValueCollection @this, string name, Func<string, Maybe<T>> parser)
        {
            var q = from values in @this.MayGetValues(name) select values.SelectAny(parser);
            return q.ValueOrEmpty();

            //// Check args eagerly.
            //if (@this is null) { throw new ArgumentNullException(nameof(@this)); }

            //return __();

            //IEnumerable<T> __()
            //{
            //    foreach (string item in @this.GetValues(name))
            //    {
            //        var result = parser(item);

            //        if (result.IsSome) { yield return result.Value; }
            //    }
            //}
        }
    }
}

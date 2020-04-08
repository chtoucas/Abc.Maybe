// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;

    // GroupJoin(), it is just a Join() with an unnecessary into clause.
    // We shall need compelling examples before seriously considering this for
    // inclusion in the main assembly.

    // GroupJoin()
    public partial class MaybeEx
    {
        /// <example>
        /// Query expression syntax:
        /// <code><![CDATA[
        ///   from x in outer
        ///   join y in inner
        ///   on outerKeySelector(x) equals innerKeySelector(y) into g
        ///   select resultSelector(x, g)
        /// ]]></code>
        /// </example>
        /// <remarks>
        /// The same can be achieved by using <see cref="Maybe{T}.SelectMany"/>
        /// and <see cref="Maybe{T}.Where"/>:
        /// <code><![CDATA[
        ///   from x in outer
        ///   from y in inner
        ///   where outerKeySelector(x) == innerKeySelector(y)
        ///   select resultSelector(x, inner)
        /// ]]></code>
        /// Furthermore, <see cref="Maybe{T}"/> being "flat", a group join is
        /// nothing but a join; the <c>into</c> clause is obviously unnecessary:
        /// <code><![CDATA[
        ///   from x in outer
        ///   join y in inner
        ///   on outerKeySelector(x) equals innerKeySelector(y)
        ///   select resultSelector(x, inner)
        /// ]]></code>
        /// </remarks>
        [Pure]
        public static Maybe<TResult> GroupJoin<TOuter, TInner, TKey, TResult>(
            this Maybe<TOuter> outer,
            Maybe<TInner> inner,
            Func<TOuter, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<TOuter, Maybe<TInner>, TResult> resultSelector)
        {
            if (outerKeySelector is null) { throw new Anexn(nameof(outerKeySelector)); }
            if (innerKeySelector is null) { throw new Anexn(nameof(innerKeySelector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            return GroupJoinImpl(
                outer,
                inner,
                outerKeySelector,
                innerKeySelector,
                resultSelector,
                EqualityComparer<TKey>.Default);
        }

        // No query expression syntax.
        // If comparer is null, the default equality comparer is used instead.
        [Pure]
        public static Maybe<TResult> GroupJoin<TOuter, TInner, TKey, TResult>(
            this Maybe<TOuter> outer,
            Maybe<TInner> inner,
            Func<TOuter, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<TOuter, Maybe<TInner>, TResult> resultSelector,
            IEqualityComparer<TKey>? comparer)
        {
            if (outerKeySelector is null) { throw new Anexn(nameof(outerKeySelector)); }
            if (innerKeySelector is null) { throw new Anexn(nameof(innerKeySelector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            return GroupJoinImpl(
                outer,
                inner,
                outerKeySelector,
                innerKeySelector,
                resultSelector,
                comparer ?? EqualityComparer<TKey>.Default);
        }

        [Pure]
        private static Maybe<TResult> GroupJoinImpl<TOuter, TInner, TKey, TResult>(
            Maybe<TOuter> outer,
            Maybe<TInner> inner,
            Func<TOuter, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<TOuter, Maybe<TInner>, TResult> resultSelector,
            IEqualityComparer<TKey> comparer)
        {
            if (outer.TryGetValue(out TOuter x) && inner.TryGetValue(out TInner y))
            {
                TKey outerKey = outerKeySelector(x);
                TKey innerKey = innerKeySelector(y);

                if (comparer.Equals(outerKey, innerKey))
                {
                    return Maybe.Of(resultSelector(x, inner));
                }
            }

            return Maybe<TResult>.None;
        }
    }
}

// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;

    using Anexn = System.ArgumentNullException;

    // Query Expression Pattern.
    public partial struct Maybe<T>
    {
        /// <example>
        /// Query expression syntax:
        /// <code><![CDATA[
        ///   from x in maybe
        ///   select selector(x)
        /// ]]></code>
        /// </example>
        [Pure]
        public Maybe<TResult> Select<TResult>(Func<T, TResult> selector)
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return _isSome ? Maybe.Of(selector(_value)) : Maybe<TResult>.None;
        }

        /// <example>
        /// Query expression syntax:
        /// <code><![CDATA[
        ///   from x in maybe
        ///   where predicate(x)
        ///   select x
        /// ]]></code>
        /// </example>
        [Pure]
        public Maybe<T> Where(Func<T, bool> predicate)
        {
            if (predicate is null) { throw new Anexn(nameof(predicate)); }

            return _isSome && predicate(_value) ? this : None;
        }

        /// <seealso cref="ZipWith"/>
        /// <example>
        /// Query expression syntax:
        /// <code><![CDATA[
        ///   from x in maybe
        ///   from y in selector(x)
        ///   select resultSelector(x, y)
        /// ]]></code>
        /// </example>
        /// <remarks>
        /// <see cref="SelectMany"/> generalizes both <see cref="ZipWith"/> and
        /// <see cref="Bind"/>. Namely, <see cref="ZipWith"/> is
        /// <see cref="SelectMany"/> with a constant selector <c>_ => other</c>:
        /// <code><![CDATA[
        ///   from x in maybe
        ///   from y in other
        ///   select zipper(x, y)
        /// ]]></code>
        /// Lesson: don't use <see cref="SelectMany"/> when <see cref="ZipWith"/>
        /// would do the job but without a (hidden) lambda function. As for
        /// <see cref="Bind"/>, it is <see cref="SelectMany"/> with a constant
        /// result selector <c>(_, y) => y</c>:
        /// <code><![CDATA[
        ///   from x in maybe
        ///   from y in binder(x)
        ///   select y
        /// ]]></code>
        /// Lesson: don't use <see cref="SelectMany"/> when <see cref="Bind"/>
        /// suffices.
        /// </remarks>
        [Pure]
        public Maybe<TResult> SelectMany<TMiddle, TResult>(
            Func<T, Maybe<TMiddle>> selector,
            Func<T, TMiddle, TResult> resultSelector)
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            if (!_isSome) { return Maybe<TResult>.None; }

            Maybe<TMiddle> middle = selector(_value);
            if (!middle._isSome) { return Maybe<TResult>.None; }

            return Maybe.Of(resultSelector(_value, middle._value));
        }

        /// <example>
        /// Query expression syntax (outer = this):
        /// <code><![CDATA[
        ///   from x in outer
        ///   join y in inner
        ///   on outerKeySelector(x) equals innerKeySelector(y)
        ///   select resultSelector(x, y)
        /// ]]></code>
        /// </example>
        /// <remarks>
        /// The same can be achieved by using <see cref="Maybe{T}.SelectMany"/>
        /// and <see cref="Maybe{T}.Where"/>:
        /// <code><![CDATA[
        ///   from x in outer
        ///   from y in inner
        ///   where outerKeySelector(x) == innerKeySelector(y)
        ///   select resultSelector(x, y)
        /// ]]></code>
        /// Even if <c>join</c> is a <c>select many</c> in disguise, it seems to
        /// be faster and more memory efficient (maybe because the later must be
        /// combined with a <c>where</c> clause).
        /// </remarks>
        [Pure]
        public Maybe<TResult> Join<TInner, TKey, TResult>(
            Maybe<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector)
        {
            if (outerKeySelector is null) { throw new Anexn(nameof(outerKeySelector)); }
            if (innerKeySelector is null) { throw new Anexn(nameof(innerKeySelector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            return JoinImpl(
                inner,
                outerKeySelector,
                innerKeySelector,
                resultSelector,
                EqualityComparer<TKey>.Default);
        }

        // No query expression syntax.
        // If "comparer" is null, the default equality comparer is used instead.
        [Pure]
        public Maybe<TResult> Join<TInner, TKey, TResult>(
            Maybe<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector,
            IEqualityComparer<TKey>? comparer)
        {
            if (outerKeySelector is null) { throw new Anexn(nameof(outerKeySelector)); }
            if (innerKeySelector is null) { throw new Anexn(nameof(innerKeySelector)); }
            if (resultSelector is null) { throw new Anexn(nameof(resultSelector)); }

            return JoinImpl(
                inner,
                outerKeySelector,
                innerKeySelector,
                resultSelector,
                comparer ?? EqualityComparer<TKey>.Default);
        }

        [Pure]
        private Maybe<TResult> JoinImpl<TInner, TKey, TResult>(
            Maybe<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector,
            IEqualityComparer<TKey> comparer)
        {
            if (_isSome && inner._isSome)
            {
                TKey outerKey = outerKeySelector(_value);
                TKey innerKey = innerKeySelector(inner._value);

                if (comparer.Equals(outerKey, innerKey))
                {
                    return Maybe.Of(resultSelector(_value, inner._value));
                }
            }

            return Maybe<TResult>.None;
        }
    }
}

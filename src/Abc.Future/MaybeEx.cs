// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Anexn = System.ArgumentNullException;

    // REVIEW: lazy extensions. Is there anything useful we can do w/
    // Lazy<Maybe<T>> or Maybe<Lazy<T>>?

    // NB: the code should be optimized if promoted to the main project.

    // Experimental helpers & extension methods for Maybe<T>.
    //
    // Only a handful of them are really considered for inclusion in the main
    // project as most of them are pretty straightforward.
    // Currently, the best candidates for promotion are:
    // - async methods
    // - ReplaceWith(), a specialization of Select()
    // - Filter(), a specialization of Where()
    //
    // NB: if we change our mind and decide to hide (or rather remove) the
    // property IsNone, we SHOULD add the methods using it to Maybe<T>.
    public static partial class MaybeEx { }

    // Side effects.
    public partial class MaybeEx
    {
        public static void OnNone<T>(this Maybe<T> @this, Action action)
        {
            if (@this.IsNone)
            {
                if (action is null) { throw new Anexn(nameof(action)); }
                action();
            }
        }

        // Reverse of When().
        public static void Unless<T>(
            this Maybe<T> @this, bool condition, Action<T>? onSome, Action? onNone)
        {
            if (!condition)
            {
                if (@this.TryGetValue(out T value))
                {
                    onSome?.Invoke(value);
                }
                else
                {
                    onNone?.Invoke();
                }
            }
        }

        // Fluent versions? They are easy to add locally. For instance,
        //   @this.Do(caseSome, caseNone);
        //   return @this;
        //
        // Might be worth including when the action only depends on an external
        // condition, not on the maybe. Purpose: debugging, logging.
        // By the way, the "non-fluent" versions of the methods below are
        // useless.
        //
        // Beware, do not throw for null actions.
        // No attr [Pure], even if fluent API, we should be able to write
        // maybe.(..anything..).When(...).ReplaceWith(...) BUT also
        // maybe.(..anything..).When(...) without gettting a warning.
        public static Maybe<T> When<T>(
            this Maybe<T> @this, bool condition, Action? action)
        {
            if (condition)
            {
                action?.Invoke();
            }
            return @this;
        }

        // Reverse of When().
        public static Maybe<T> Unless<T>(
            this Maybe<T> @this, bool condition, Action? action)
        {
            return When(@this, !condition, action);
        }
    }

    // Misc methods.
    public partial class MaybeEx
    {
        // Objectives: constraint TResult : notnull, prevent the creation of
        // Maybe<TResult?>, alternative to AndThen() to avoid the creation
        // of a Maybe when it is not strictly necessary.
        //
        // We should be able to write:
        //   maybe.ReplaceWith(1)
        //   maybe.ReplaceWith((TResult)obj)
        // We should NOT be able to write:
        //   maybe.ReplaceWith((int?)1)         // nullable value type
        //   maybe.ReplaceWith((TResult?)null)  // nullable reference type
        //
        // We want to offer two versions of ReplaceWith(), one for classes and
        // another for structs, to make sure that the method returns a
        // Maybe<TResult> not a Maybe<TResult?>, but it causes some API problems,
        // and since we already have AndThen(), it's better left off for now.
        // Moreover it is just a Select(_ => other); we only bother because we
        // would like to avoid the creation of an unnecessary lambda.
        // Of course, if we don't mind about Maybe<TResult?> the obvious
        // solution is to have only a single method to treat all cases.
        // NB: this looks a lot like the problem we have with Maybe.SomeOrNone()
        // and Maybe.Of().
        //
        // Other point: we should write "where TResult : notnull", since when
        // "other" is null we should rather use AndThen(), nervertheless,
        // whatever I try, I end up double-checking null's, in ReplaceWith()
        // and in the factory method --- that was another reason why we have
        // two versions of ReplaceWith().
        //
        // Simple solution: since IsNone is public, we do not really need to
        // bother w/ ReplaceWith(), same thing with AndThen() in fact.

        // REVIEW: OrElse(T other)? but under a diff name. I doubt it, it's so
        // easy to write...
        //   _isSome ? this : Maybe.Of(other)

#if true
        /// <remarks>
        /// <see cref="ReplaceWith"/> is a <see cref="Maybe{T}.Select"/> with a
        /// constant selector <c>_ => value</c>.
        /// <code><![CDATA[
        ///   Some(1) & 2L == Some(2L)
        ///   None    & 2L == None
        /// ]]></code>
        /// </remarks>
        // Compare to the nullable equiv w/ x an int? and y a long:
        //   (x.HasValue ? (long?)y : (long?)null).
        // It does work with null but then one should really use AndThen().
        [Pure]
        public static Maybe<TResult> ReplaceWith<T, TResult>(
            this Maybe<T> @this, TResult value)
            where TResult : notnull
        {
            // Drawback: double-null checks for structs.
            return !@this.IsNone ? Maybe.Of(value) : Maybe<TResult>.None;
        }
#else
        [Pure]
        public static Maybe<TResult> ReplaceWith<T, TResult>(
            this Maybe<T> @this, TResult? value)
            where TResult : class
        {
            return !@this.IsNone ? Maybe.SomeOrNone(value)
                : Maybe<TResult>.None;
        }

        // It works with null but then one should really use
        // AndThen(Maybe<TResult>.None). We can't remove the nullable
        // in the param otherwise we would have two methods with the same
        // name.
        [Pure]
        public static Maybe<TResult> ReplaceWith<T, TResult>(
            this Maybe<T> @this, TResult? value)
            where TResult : struct
        {
            return !@this.IsNone && value.HasValue ? Maybe.Some(value.Value)
                : Maybe<TResult>.None;
        }
#endif

        // Specialized version of Where() when the state of the maybe and the
        // value it encloses are not taken into account.
        [Pure]
        public static Maybe<T> Filter<T>(this Maybe<T> @this, bool condition)
            => condition ? @this : Maybe<T>.None;

        /// <seealso cref="Maybe{T}.Yield(int)"/>
        /// <remarks>
        /// The difference with <see cref="Maybe{T}.Yield(int)"/> is in the treatment of
        /// an empty maybe. <see cref="Maybe{T}.Yield(int)"/> for an empty maybe returns
        /// an empty sequence, whereas this method returns an empty maybe (no
        /// sequence at all).
        /// </remarks>
        [Pure]
        public static Maybe<IEnumerable<T>> Replicate<T>(this Maybe<T> @this, int count)
            //=> _isSome ? Maybe.Of(Enumerable.Repeat(_value, count))
            //    : Maybe<IEnumerable<T>>.None;
            => @this.Select(x => Enumerable.Repeat(x, count));

        // Beware, infinite loop!
        /// <seealso cref="Maybe{T}.Yield()"/>
        /// <remarks>
        /// The difference with <see cref="Maybe{T}.Yield()"/> is in the treatment of
        /// an empty maybe. <see cref="Maybe{T}.Yield()"/> for an empty maybe returns
        /// an empty sequence, whereas this method returns an empty maybe (no
        /// sequence at all).
        /// </remarks>
        [Pure]
        public static Maybe<IEnumerable<T>> Replicate<T>(this Maybe<T> @this)
        {
            return @this.Select(__);

            static IEnumerable<T> __(T value)
            {
                //// BONSANG! Select() guarantees that "value" won't be null.
                //=> new NeverEndingIterator<T>(value!);
                while (true)
                {
                    yield return value;
                }
            }
        }
    }
}

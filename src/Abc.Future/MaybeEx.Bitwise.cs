// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Diagnostics.Contracts;

    // TODO: change names LeftAnd() and RightAnd().

    // "Bitwise" logical operations.
    // Gates, bools and bits.
    public partial class MaybeEx
    {
        // Possible combinations:
        //   Some(1)  Some(2L)  -> None, Some(1), Some(2L)
        //   Some(1)  None      -> None, Some(1)
        //   None     Some(2L)  -> None, Some(2L)
        //   None     None      -> None
        // Below 0 = None, 1 = Some(1) and 2 = Some(2).
        // 0 is "false", 1 and 2 are "true".
        //
        // Compare to the truth table at https://en.wikipedia.org/wiki/Bitwise_operation
        //   0000 -
        //   0020 UnlessRTL()           NOT(<-)
        //   0100 Unless()              NOT(->) aka NIMPLY
        //   0120 XorElse()             XOR
        //
        //   1000 AndThenRTL()          AND
        //   1020 LeftAnd()             right projection
        //   1100 Ignore()              left projection
        //   1120 OrElse()              OR
        //
        //   2000 AndThen()             AND
        //   2020 ContinueWith()        right projection
        //   2100 RightAnd()            left projection
        //   2120 OrElseRTL()           OR
        //
        // Overview: op / return type / pseudo-code
        //   x.OrElse(y)                same types      x is some ? x : y
        //   x.AndThen(y)               type y          x is some ? y : none(y)
        //   x.XorElse(y)               same types      x is some ? (y is some ? none : x) : y
        //   x.UnlessRTL(y)             type y          x is some ? none(y) : y
        //
        //   x.OrElseRTL(y)             same types      y is some ? y : x
        //   x.AndThenRTL(y)            type x          y is some ? x : none(x)
        //   x.Unless(y)                type x          y is some ? none(x) : x
        //
        //   x.Ignore(y)                type x          x
        //   x.ContinueWith(y)          type y          y
        //
        //   LeftAnd(x, y)              same types      x is some && y is some ? x : y
        //   RightAnd(x, y)             same types      x is some && y is some ? y : x
        //
        // Method / flipped method
        //               x.OrElse(y) == y.OrElseRTL(x)
        //              x.AndThen(y) == y.AndThenRTL(x)
        //              x.XorElse(y) == y.XorElse(x)
        // methods not in main:
        //               x.Unless(y) == y.UnlessRTL(x)
        //               x.Ignore(y) == y.ContinueWith(x)
        //             LeftAnd(x, y) == RightAnd(y, x)
        //
        // References: Knuth vol. 4A, chap. 7.1

        // Conjunction. RTL = right-to-left.
        /// <code><![CDATA[
        ///   Some(1) OrElseRTL Some(2) == Some(2)
        ///   Some(1) OrElseRTL None    == Some(1)
        ///   None    OrElseRTL Some(2) == Some(2)
        ///   None    OrElseRTL None    == None
        /// ]]></code>
        [Pure]
        public static Maybe<T> OrElseRTL<T>(
            this Maybe<T> @this, Maybe<T> other)
        {
            return @this.IsNone ? other
                : other.IsNone ? @this
                : other;
        }

        // Conjunction; mnemotechnic "P if Q".
        // "@this" pass through when "other" is some.
        /// <summary>
        /// Returns the current instance if <paramref name="other"/> is not
        /// empty; otherwise returns the empty maybe of type
        /// <typeparamref name="TOther"/>.
        /// </summary>
        /// <remarks>
        /// <code><![CDATA[
        ///   Some(1) AndThenRTL Some(2L) == Some(1)
        ///   Some(1) AndThenRTL None     == None
        ///   None    AndThenRTL Some(2L) == None
        ///   None    AndThenRTL None     == None
        /// ]]></code>
        /// </remarks>
        // Compare to the nullable equiv w/ x an int? and y a long?:
        //   (y.HasValue ? x : (int?)null).
        [Pure]
        public static Maybe<T> AndThenRTL<T, TOther>(
            this Maybe<T> @this, Maybe<TOther> other)
        {
            // Using Bind():
            //   other.Bind(_ => @this);
            return other.IsNone ? Maybe<T>.None : @this;
        }

        // Nonimplication or abjunction; mnemotechnic "P but not Q",
        // "@this" pass through unless "other" is some.
        // Like AndThenRTL() (from play) but when "other" is the empty maybe.
        // Unless() is is always confusing, I would have preferred a more
        // affirmative adverb.
        // Other name considered: ZeroedWhen(), Zeroiz(s)eWhen(), ClearWhen().
        // ClearWhen() could be a good name; see Array.Clear().
        /// <summary>
        /// Removes the enclosed value if <paramref name="other"/> is not empty;
        /// otherwise returns the current instance as it.
        /// </summary>
        /// <code><![CDATA[
        ///   Some(1) Unless Some(2L) == None
        ///   Some(1) Unless None     == Some(1)
        ///   None    Unless Some(2L) == None
        ///   None    Unless None     == None
        /// ]]></code>
        [Pure]
        public static Maybe<T> Unless<T, TOther>(
            this Maybe<T> @this, Maybe<TOther> other)
        {
            return other.IsNone ? @this : Maybe<T>.None;
        }

        // Converse nonimplication; mnemotechnic "not P but Q".
        // Like AndThen() but when @this is the empty maybe.
        // Whereas AndThen() maps
        //   some(X) to some(Y), and none(X) to none(Y)
        // UnlessRTL() maps
        //   some(X) to none(Y), and none(X) to some(Y)
        /// <code><![CDATA[
        ///   Some(1) UnlessRTL Some(2L) == None
        ///   Some(1) UnlessRTL None     == None
        ///   None    UnlessRTL Some(2L) == Some(2L)
        ///   None    UnlessRTL None     == None
        /// ]]></code>
        [Pure]
        public static Maybe<TResult> UnlessRTL<T, TResult>(
           this Maybe<T> @this, Maybe<TResult> other)
        {
            return @this.IsNone ? other : Maybe<TResult>.None;
        }

        // If left or right is empty, returns right; otherwise returns left.
        // LeftAnd() = flip RightAnd():
        //   LeftAnd(left, right) == RightAnd(right, left).
        /// <code><![CDATA[
        ///   Some(1) LeftAnd Some(2) == Some(1)
        ///   Some(1) LeftAnd None    == None
        ///   None    LeftAnd Some(2) == Some(2)
        ///   None    LeftAnd None    == None
        /// ]]></code>
        [Pure]
        public static Maybe<T> LeftAnd<T>(Maybe<T> left, Maybe<T> right)
        {
            return !left.IsNone && !right.IsNone ? left : right;
        }

        // If left or right is empty, returns left; otherwise returns right.
        // RightAnd() = flip LeftAnd():
        //   RightAnd(left, right) == LeftAnd(right, left).
        /// <code><![CDATA[
        ///   Some(1) RightAnd Some(2) == Some(2)
        ///   Some(1) RightAnd None    == Some(1)
        ///   None    RightAnd Some(2) == None
        ///   None    RightAnd None    == None
        /// ]]></code>
        [Pure]
        public static Maybe<T> RightAnd<T>(Maybe<T> left, Maybe<T> right)
        {
            return !left.IsNone && !right.IsNone ? right : left;
        }

#pragma warning disable CA1801 // -Review unused parameters
        // Ignore() = flip ContinueWith():
        //   this.Ignore(other) = other.ContinueWith(this)
        /// <code><![CDATA[
        ///   Some(1) Ignore Some(2L) == Some(1)
        ///   Some(1) Ignore None     == Some(1)
        ///   None    Ignore Some(2L) == None
        ///   None    Ignore None     == None
        /// ]]></code>
        [Pure]
        public static Maybe<T> Ignore<T, TOther>(
            this Maybe<T> @this, Maybe<TOther> other)
        {
            return @this;
        }
#pragma warning restore CA1801

        // ContinueWith() = flip Ignore():
        //   this.ContinueWith(other) = other.Ignore(this)
        /// <code><![CDATA[
        ///   Some(1) ContinueWith Some(2L) == Some(2L)
        ///   Some(1) ContinueWith None     == None
        ///   None    ContinueWith Some(2L) == Some(2L)
        ///   None    ContinueWith None     == None
        /// ]]></code>
        [Pure]
        public static Maybe<TResult> ContinueWith<T, TResult>(
            this Maybe<T> @this, Maybe<TResult> other)
        {
            return other;
        }
    }
}

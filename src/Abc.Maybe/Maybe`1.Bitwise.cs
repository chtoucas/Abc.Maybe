// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;

    using Abc.Utilities;

    // "Bitwise" logical operations.
    // We have OrElse() & co, so it seems reasonnable to have the operators too.
    // It is not particulary recommended to have all the ops we can, it is even
    // considered to be bad practice, but I wish to keep them for two reasons:
    // - even if they are not true logical ops, we named the corresponding
    //   methods in a way that emphasizes the proximity w/ logical operations.
    // - most people won't even realize that they exist...
    //
    // We don't offer boolean logical operations. This would be confusing,
    // moreover don't have the expected properties. For instance, they are
    // non-abelian, and I haven't even check associativity.
    // There is only one case where it could make sense, Maybe<bool>, but
    // then it would be odd to have:
    //   Some(false) && Some(true) -> Some(true)
    // instead of Some(false). The solution is 3VL (see Maybe).
    //
    // The methods are independent of Select()/Bind(). Maybe this can be done in
    // conjunction w/ OrElse(), but I haven't check this out.
    // References:
    // - https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/operators/boolean-logical-operators
    public partial struct Maybe<T>
    {
        // Overloading true and false is necessary if we wish to support the
        // boolean logical AND (&&) and OR (||),
        //   x && y is evaluated as false(x) ? x : (x & y)
        //   x || y is evaluated as  true(x) ? x : (x | y)
        // but we don't really want to do it, don't we?
        // https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/expressions#user-defined-conditional-logical-operators
        // See also the internal method ToBoolean() below.
        // True boolean operations ony make sense with Maybe<bool>; see Maybe.
#if false // Only kept to be sure that I won't try it again... do NOT enable.

        public static bool operator true(Maybe<T> value) =>
            value._isSome;

        public static bool operator false(Maybe<T> value) =>
            !value._isSome;

#endif

        // Bitwise logical OR.
        [SuppressMessage("Usage", "CA2225:Operator overloads have named alternates", Justification = "OrElse()")]
        public static Maybe<T> operator |(Maybe<T> left, Maybe<T> right) =>
            left.OrElse(right);

        // Bitwise logical AND.
        [SuppressMessage("Usage", "CA2225:Operator overloads have named alternates", Justification = "AndThen()")]
        public static Maybe<T> operator &(Maybe<T> left, Maybe<T> right) =>
            left.AndThen(right);

        // Bitwise logical XOR.
        [SuppressMessage("Usage", "CA2225:Operator overloads have named alternates", Justification = "XorElse()")]
        public static Maybe<T> operator ^(Maybe<T> left, Maybe<T> right) =>
            left.XorElse(right);

        // I know, this is just IsSome, but I wish to emphasize a boolean context.
        [InternalForTesting]
        internal bool ToBoolean() =>
            _isSome;

        /// <remarks>
        /// Generalizes the null-coalescing operator (??) to maybe's, it returns
        /// the first non-empty value (if any).
        /// <code><![CDATA[
        ///   Some(1) OrElse Some(2) == Some(1)
        ///   Some(1) OrElse None    == Some(1)
        ///   None    OrElse Some(2) == Some(2)
        ///   None    OrElse None    == None
        ///
        ///   Some(1) ?? Some(2) == Some(1)
        ///   Some(1) ?? None    == Some(1)
        ///   None    ?? Some(2) == Some(2)
        ///   None    ?? None    == None
        /// ]]></code>
        /// This method can be though as an inclusive OR for maybe's, provided
        /// that an empty maybe is said to be false.
        /// </remarks>
        //
        // Inclusive disjunction; mnemotechnic: "P otherwise Q".
        // "Plus" operation for maybe's.
        [Pure]
        public Maybe<T> OrElse(Maybe<T> other) =>
            _isSome ? this : other;

        /// <summary>
        /// Continues with <paramref name="other"/> if the current instance is
        /// not empty; otherwise returns the empty maybe of type
        /// <typeparamref name="TResult"/>.
        /// </summary>
        /// <remarks>
        /// <code><![CDATA[
        ///   Some(1) AndThen Some(2L) == Some(2L)
        ///   Some(1) AndThen None     == None
        ///   None    AndThen Some(2L) == None
        ///   None    AndThen None     == None
        /// ]]></code>
        /// This method can be though as an AND for maybe's, provided that an
        /// empty maybe is said to be false.
        /// </remarks>
        //
        // Conjunction; mnemotechnic "Q if P", "P and then Q".
        // Compare to the nullable equiv w/ x an int? and y a long?:
        //   (x.HasValue ? y : (long?)null).
        [Pure]
        public Maybe<TResult> AndThen<TResult>(Maybe<TResult> other) =>
            _isSome ? other : Maybe<TResult>.None;

        // Exclusive disjunction; mnemotechnic: "either P or Q, but not both".
        // XorElse() = flip XorElse():
        //   this.XorElse(other) = other.XorElse(this)
        /// <remarks>
        /// <code><![CDATA[
        ///   Some(1) XorElse Some(2) == None
        ///   Some(1) XorElse None    == Some(1)
        ///   None    XorElse Some(2) == Some(2)
        ///   None    XorElse None    == None
        /// ]]></code>
        /// This method can be though as an exclusive OR for maybe's, provided
        /// that an empty maybe is said to be false.
        /// </remarks>
        [Pure]
        public Maybe<T> XorElse(Maybe<T> other) =>
            _isSome ? other._isSome ? None : this
                : other;
    }
}

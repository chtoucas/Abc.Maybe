// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.ComponentModel;
    using System.Diagnostics;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;
    using System.Linq;
    using System.Runtime.CompilerServices;

    using Abc.Utilities;

    using Anexn = System.ArgumentNullException;
    using EF = Abc.Utilities.ExceptionFactory;

    // REVIEW: Maybe type
    // - nullable attrs, notnull constraint.
    //   It would make a lot of sense to add a notnull constraint on the T of
    //   Maybe<T>, but it worries me a bit (I need to gain more experience with
    //   the new NRT). It would allow to warn a user trying to create a
    //   Maybe<int?> or a Maybe<string?>, maybe I managed to entirely avoid the
    //   ability to do so, but I am not sure.
    //   https://docs.microsoft.com/en-us/dotnet/csharp/nullable-attributes
    //   https://devblogs.microsoft.com/dotnet/try-out-nullable-reference-types/
    //   https://devblogs.microsoft.com/dotnet/nullable-reference-types-in-csharp/
    //   https://devblogs.microsoft.com/dotnet/embracing-nullable-reference-types/
    // - IEquatable<T> (T == Maybe<T>), IComparable<T> but a bit missleading?
    //   Overloads w/ IEqualityComparer<T>.
    // - Serializable? Binary serialization only.
    //   https://docs.microsoft.com/en-us/dotnet/standard/serialization/binary-serialization
    // - Set ops POV.
    // - naming Skip() -> Void(), Unit(), Discard(), Erase(), Forget()?
    // - Struct really? Explain and compare to ValueTuple
    //   https://docs.microsoft.com/en-gb/dotnet/csharp/tuples
    //   http://mustoverride.com/tuples_structs/
    //   https://docs.microsoft.com/en-us/archive/msdn-magazine/2018/june/csharp-tuple-trouble-why-csharp-tuples-get-to-break-the-guidelines
    //   https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/value-options
    //   https://github.com/fsharp/fslang-design/blob/master/FSharp.Core-4.5.0.0/FS-1057-valueoption.md

    /// <summary>
    /// Represents an object that is either a single value of type
    /// <typeparamref name="T"/>, or no value at all.
    /// <para><see cref="Maybe{T}"/> is an immutable struct (but see caveats
    /// in the section remarks).</para>
    /// </summary>
    ///
    /// <_text><![CDATA[
    /// Overview.
    ///
    /// Maybe<T> is an option type for C#.
    ///
    /// The intended usage is when T is a value type, a string, a (read-only?)
    /// record, or a function. For other reference types, it should be fine as
    /// long as T is an **immutable** reference type.
    ///
    /// Static properties.
    /// - Maybe<T>.None         the empty maybe of type T
    /// - Maybe.Zero            the empty maybe of type Unit
    /// - Maybe.Unit            the unit for Maybe<T>
    /// - Maybe.Unknown         the empty maybe of type bool
    /// - Maybe.True
    /// - Maybe.False
    ///
    /// Instance properties.
    /// - IsNone                is this the empty maybe?
    ///
    /// Static factories (no public ctor).
    /// - Maybe.None<T>()       the empty maybe of type T
    /// - Maybe.Some()          factory method for value types
    /// - Maybe.SomeOrNone()    factory method for nullable value or reference types
    /// - Maybe.Of()            unconstrained factory method
    /// - Maybe.Square()
    /// - Maybe.SquareOrNone()
    /// - Maybe.Guard()
    ///
    /// Operators:
    /// - equality == and !=
    /// - comparison <, >, <=, and >=
    /// - bitwise logical |, & and ^ (and compound assignment |=, &= and ^=)
    /// - explicit conversion from and to the underlying type T
    ///
    /// Instance methods where the result is another maybe.
    /// - Bind()                unwrap then map to another maybe
    /// - Select()              LINQ select
    /// - SelectMany()          LINQ select many
    /// - Join()                LINQ join
    /// - Where()               LINQ filter
    /// - ZipWith()             cross join
    /// - OrElse()              logical OR; "none"-coalescing
    /// - AndThen()             logical AND
    /// - XorElse()             logical XOR
    /// - Skip()                discard the value
    ///
    /// Escape the maybe (no public access to the enclosed value if any,
    /// ie no property Value).
    /// - Switch()              pattern matching
    /// - TryGetValue()         try unwrap
    /// - ValueOrDefault()      unwrap
    /// - ValueOrElse()         unwrap if possible, otherwise use a replacement
    /// - ValueOrthrow()        unwrap if possible, otherwise throw
    ///
    /// Set and enumerable related methods.
    /// - GetEnumerator()       iterable (implicit)
    /// - ToEnumerable()        convert to an enumerable
    /// - Yield()               enumerable (explicit)
    /// - Contains()            singleton or empty set?
    ///
    /// Side effects.
    /// - Do()
    /// - OnSome()
    /// - When()
    ///
    /// Async versions of the core methods.
    /// - BindAsync()           async binding
    /// - SelectAsync()         async mapping
    /// - OrElseAsync()         async coalescing
    ///
    /// We also have several extension methods for specific types of T, eg
    /// structs, functions or enumerables; see the static class Maybe.
    /// ]]></_text>
    [DebuggerDisplay("{" + nameof(DebuggerDisplay) + ",nq}")]
    [DebuggerTypeProxy(typeof(Maybe<>.DebugView_))]
    public readonly partial struct Maybe<T>
        : IEquatable<Maybe<T>>, IComparable<Maybe<T>>, IComparable,
            IStructuralEquatable, IStructuralComparable
    {
        // We use explicit backing fields to be able to quickly find outside the
        // struct all occurences of the corresponding properties .

        private readonly bool _isSome;

        /// <summary>
        /// Represents the enclosed value.
        /// <para>This field is read-only.</para>
        /// </summary>
        [MaybeNull] [AllowNull] private readonly T _value;

        /// <summary>
        /// Initializes a new instance of the <see cref="Maybe{T}" /> struct
        /// from the specified value.
        /// </summary>
        internal Maybe([DisallowNull] T value)
        {
            Debug.Assert(value != null);

            _isSome = true;
            _value = value;
        }

        /// <summary>
        /// Checks whether the current instance is empty or not.
        /// </summary>
        // We expose this property to ease extensibility, see MaybeEx in "play",
        // but this not mandatory, in fact everything should work fine without
        // it.
        public bool IsNone => !_isSome;

        /// <summary>
        /// Checks whether the current instance does hold a value or not.
        /// </summary>
        /// <remarks>
        /// Most of the time, we don't need to access this property. We are
        /// better off using the rich API that this struct has to offer.
        /// </remarks>
        [DebuggerBrowsable(DebuggerBrowsableState.Never)]
        internal bool IsSome => _isSome;

        /// <summary>
        /// Gets the enclosed value.
        /// <para>You MUST check IsSome before calling this property.</para>
        /// </summary>
        [MaybeNull]
        [DebuggerBrowsable(DebuggerBrowsableState.Never)]
        internal T Value { get { Debug.Assert(_isSome); return _value; } }

        [ExcludeFromCodeCoverage]
        [DebuggerBrowsable(DebuggerBrowsableState.Never)]
        [EditorBrowsable(EditorBrowsableState.Never)]
        private string DebuggerDisplay => $"IsSome = {_isSome}";

        /// <summary>
        /// Returns a string representation of the current instance.
        /// </summary>
        [Pure]
        public override string ToString() => _isSome ? $"Maybe({_value})" : "Maybe(None)";

        // REVIEW: implicit conversion.
        // Implicit conversion: test ImplicitToMaybe, see Square() and
        // SquareOrNone() too.
        //
        // Implicit conversion to Maybe<T> for equality comparison, very much
        // like what we have will nullable values: (int?)1 == 1 works.
        // NB: maybe (= Some(x)) == y is equivalent to maybe.Contains(y).
        //[SuppressMessage("Usage", "CA2225:Operator overloads have named alternates", Justification = "Maybe.Of()")]
        //public static implicit operator Maybe<T>([AllowNull] T value) => Maybe.Of(value);

        // TODO: explicit conversion.
        // ??? exception or null ???
        // with null, we can write maybe == null, which is odd for a struct
        // but at the same time we can write Maybe<string> maybe = s where s is
        // in fact "null".
        [SuppressMessage("Usage", "CA2225:Operator overloads have named alternates", Justification = "ValueOrThrow()")]
        public static explicit operator T(Maybe<T> value) =>
            value._isSome ? value._value : throw EF.FromMaybe_NoValue;

        /// <summary>
        /// Represents a debugger type proxy for <see cref="Maybe{T}"/>.
        /// </summary>
        [ExcludeFromCodeCoverage]
        private sealed class DebugView_
        {
            private readonly Maybe<T> _inner;

            // REVIEW: currently coverlet does not apply the attr
            // ExcludeFromCodeCoverage to the enclosed methods.

            [ExcludeFromCodeCoverage]
            public DebugView_(Maybe<T> inner) { _inner = inner; }

            [ExcludeFromCodeCoverage]
            public bool IsSome => _inner._isSome;

            [ExcludeFromCodeCoverage]
            [MaybeNull] public T Value => _inner._value;
        }
    }

    // Core monadic methods.
    // - Maybe.Of() aka "return"
    // - Bind()
    // We could have chosen Select() and Maybe.Flatten(), aka "map" and "join",
    // instead. Maybe is a MonadPlus (or better a MonadOr) too, so OrElse() is
    // also part of the monadic methods.
    public partial struct Maybe<T>
    {
        /// <summary>
        /// Represents the empty <see cref="Maybe{T}" />, it does not enclose
        /// any value.
        /// <para>This field is read-only.</para>
        /// </summary>
        /// <seealso cref="Maybe.None{T}"/>
        public static readonly Maybe<T> None = default;

        [Pure]
        public Maybe<TResult> Bind<TResult>(Func<T, Maybe<TResult>> binder)
        {
            if (binder is null) { throw new Anexn(nameof(binder)); }

            return _isSome ? binder(_value) : Maybe<TResult>.None;
        }
    }

    // Safe escapes.
    // Actually, only ValueOrThrow() is truely safe, the other can only be
    // verified by the compiler and under special conditions (C# 8.0 and
    // .NET Core 3.0 or above).
    // We do not throw ArgumentNullException right away, we delay arg check
    // until it is strictly necessary.
    public partial struct Maybe<T>
    {
        /// <summary>
        /// If the current instance encloses a value, it unwraps it using
        /// <paramref name="caseSome"/>, otherwise it executes
        /// <paramref name="caseNone"/>.
        /// </summary>
        [Pure]
        public TResult Switch<TResult>(Func<T, TResult> caseSome, Func<TResult> caseNone)
            where TResult : notnull
        {
            if (_isSome)
            {
                if (caseSome is null) { throw new Anexn(nameof(caseSome)); }
                return caseSome(_value);
            }
            else
            {
                if (caseNone is null) { throw new Anexn(nameof(caseNone)); }
                return caseNone();
            }
        }

        /// <summary>
        /// If the current instance encloses a value, it unwraps it using
        /// <paramref name="caseSome"/>, otherwise it returns
        /// <paramref name="caseNone"/>.
        /// </summary>
        [Pure]
        public TResult Switch<TResult>(Func<T, TResult> caseSome, TResult caseNone)
            where TResult : notnull
        {
            if (_isSome)
            {
                if (caseSome is null) { throw new Anexn(nameof(caseSome)); }
                return caseSome(_value);
            }
            else
            {
                return caseNone;
            }
        }

        [Pure]
        // Code size = 31 bytes.
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public bool TryGetValue([MaybeNullWhen(false)] out T value)
        {
            if (_isSome)
            {
                value = _value;
                return true;
            }
            else
            {
                value = default;
                return false;
            }
        }

        /// <summary>
        /// Obtains the enclosed value if any; otherwise this method returns the
        /// default value of type <typeparamref name="T"/>.
        /// </summary>
        /// <seealso cref="TryGetValue"/>
        [Pure]
        [return: MaybeNull]
        public T ValueOrDefault() => _isSome ? _value : default;

        /// <summary>
        /// Obtains the enclosed value if any; otherwise this method returns
        /// <paramref name="other"/>.
        /// </summary>
        /// <seealso cref="TryGetValue"/>
        [Pure]
        // It does work with null but then one should really use ValueOrDefault().
        public T ValueOrElse([DisallowNull] T other) => _isSome ? _value : other;

        [Pure]
        public T ValueOrElse(Func<T> valueFactory)
        {
            if (_isSome)
            {
                return _value;
            }
            else
            {
                if (valueFactory is null) { throw new Anexn(nameof(valueFactory)); }
                return valueFactory();
            }
        }

        [Pure]
        public T ValueOrThrow() => _isSome ? _value : throw EF.Maybe_NoValue;

        [Pure]
        public T ValueOrThrow(Exception exception)
        {
            if (_isSome)
            {
                return _value;
            }
            else
            {
                if (exception is null) { throw new Anexn(nameof(exception)); }
                throw exception;
            }
        }
    }

    // Side effects.
    // Do() and Some() are specialized forms of Switch(), they do not return
    // anything (a Unit in fact). They could return "this" but I prefer not
    // to, this way it's clear that they are supposed to produce side effects.
    // We do not provide OnNone(action), since it is much simpler to write:
    //   if (maybe.IsNone) { action(); }
    // We do not throw ArgumentNullException right away, we delay arg check
    // until it is strictly necessary.
    public partial struct Maybe<T>
    {
        /// <summary>
        /// If the current instance encloses a value, it executes
        /// <paramref name="onSome"/>, otherwise it executes
        /// <paramref name="onNone"/>.
        /// </summary>
        /// <seealso cref="When"/>
        public void Do(Action<T> onSome, Action onNone)
        {
            if (_isSome)
            {
                if (onSome is null) { throw new Anexn(nameof(onSome)); }
                onSome(_value);
            }
            else
            {
                if (onNone is null) { throw new Anexn(nameof(onNone)); }
                onNone();
            }
        }

        /// <summary>
        /// If the current instance encloses a value, it executes
        /// <paramref name="action"/>.
        /// </summary>
        /// <seealso cref="GetEnumerator"/>
        public void OnSome(Action<T> action)
        {
            if (_isSome)
            {
                if (action is null) { throw new Anexn(nameof(action)); }
                action(_value);
            }
        }

        // Enhanced versions of Do().
        // Beware, contrary to Do(), they do not throw for null actions.
        public void When(bool condition, Action<T>? onSome, Action? onNone)
        {
            if (condition)
            {
                if (_isSome)
                {
                    onSome?.Invoke(_value);
                }
                else
                {
                    onNone?.Invoke();
                }
            }
        }
    }

    // Misc methods.
    // They can be built from Select() or Bind(), but we prefer not to since
    // this forces us to use (unnecessary) lambda functions.
    public partial struct Maybe<T>
    {
        /// <remarks>
        /// <para>
        /// <see cref="ZipWith"/> is <see cref="Select"/> with two maybe's,
        /// it is also a special case of <see cref="SelectMany"/>; see the
        /// comments there. Roughly, <see cref="ZipWith"/> unwraps two maybe's,
        /// then applies a zipper, and eventually wraps the result.
        /// </para>
        /// <para>
        /// Compare to the F# computation expressions for an hypothetical maybe
        /// workflow:
        /// <code><![CDATA[
        ///   maybe {
        ///     let! x = this;          // Unwrap this
        ///     let! y = other;         // Unwrap other
        ///     return zipper(x, y);    // Zip then wrap (return = wrap)
        ///   }
        /// ]]></code>
        /// F# users are lucky, the special syntax even extends to more than two
        /// maybe's. Nothing similar in C#. Adding ZipWith's with more parameters
        /// is a possibility but it looks artificial; for a better(?) solution
        /// see the Lift methods in <see cref="Maybe"/>.
        /// </para>
        /// </remarks>
        // F# Workflow: let!.
        [Pure]
        public Maybe<TResult> ZipWith<TOther, TResult>(
            Maybe<TOther> other,
            Func<T, TOther, TResult> zipper)
        {
            if (zipper is null) { throw new Anexn(nameof(zipper)); }

            return _isSome && other._isSome
                ? Maybe.Of(zipper(_value, other._value))
                : Maybe<TResult>.None;
        }

        /// <summary>
        /// Discards the enclosed value while retaining the value of the property
        /// <see cref="IsNone"/>.
        /// </summary>
        [Pure]
        public Maybe<Unit> Skip() => _isSome ? Maybe.Unit : Maybe.Zero;
    }

    // Iterable but **not** IEnumerable<>.
    // 1) A maybe is indeed a collection but a rather trivial one.
    // 2) Maybe<T> being a struct, I worry about hidden casts.
    // 3) Source of confusion (conflicts?) if we import System.Linq too.
    // Furthermore, this type does NOT implement the whole Query Expression
    // Pattern.
    //
    // Supporting "foreach" is a bit odd but it is not if we realize that
    // a maybe is just a set (singleton or empty).
    // Four ways of doing the "same" thing:
    // - Using an implicit iterator (no opportunity for "onNone"):
    //     foreach (var x in maybe) { action(x); }
    // - Using an explicit iterator:
    //     var iter = maybe.GetEnumerator();
    //     if (iter.MoveNext()) { action(iter.Current); } else { onNone(); }
    // - Using Do() or OnSome():
    //     maybe.Do(action, onNone);
    //     maybe.OnSome(action);
    // - Using TryGetValue():
    //     if (maybe.TryGetValue(out T value)) { action(value); } else { onNone(); }
    public partial struct Maybe<T>
    {
        [Pure]
        public IEnumerator<T> GetEnumerator() =>
            // BONSANG! When _isSome is true, _value is NOT null.
            _isSome ? new SingletonList<T>.Iterator(_value!)
                : EmptyIterator<T>.Instance;

        /// <summary>
        /// Converts the current instance to <see cref="IEnumerable{T}"/>.
        /// </summary>
        // Really useful if we wish to manipulate a maybe together with another
        // sequence.
        [Pure]
        public IEnumerable<T> ToEnumerable() =>
            // BONSANG! When _isSome is true, _value is NOT null.
            _isSome ? new SingletonList<T>(_value!) : Enumerable.Empty<T>();

        // Beware, Yield() doesn't match the yield from F# computation expressions.

        // Yield break or yield return "count" times.
        ///// See also <seealso cref="Replicate(int)"/> and the comments there.
        [Pure]
        public IEnumerable<T> Yield(int count) =>
            _isSome ? Enumerable.Repeat(_value, count) : Enumerable.Empty<T>();

        // Beware, may create an infinite loop!
        ///// See also <seealso cref="Replicate()"/> and the comments there.
        [Pure]
        public IEnumerable<T> Yield() =>
            // BONSANG! When _isSome is true, _value is NOT null.
            _isSome ? new NeverEndingSequence<T>(_value!) : Enumerable.Empty<T>();

        // See also Replicate() and the comments there.
        // Maybe<T> being a struct it is never equal to null, therefore
        // Contains(null) always returns false.
        [Pure]
        public bool Contains(T value) =>
            _isSome && EqualityComparer<T>.Default.Equals(_value, value);

        [Pure]
        public bool Contains(T value, IEqualityComparer<T> comparer)
        {
            if (comparer is null) { throw new Anexn(nameof(comparer)); }

            return _isSome && comparer.Equals(_value, value);
        }
    }

    // Interface IComparable<> and alike.
    // The comparison operators behave like the ones for nullable value types:
    // if one of the operand is empty, return false, otherwise compare the
    // values.
    public partial struct Maybe<T>
    {
        /// <summary>
        /// Compares the two specified instances to see if the left one is
        /// strictly less than the right one.
        /// <para>Beware, if either operand is empty, this operator will return
        /// false.</para>
        /// </summary>
        /// <remarks>
        /// <para>The weird behaviour with empty maybe's is the same one
        /// implemented by nullables.</para>
        /// <para>For proper sorting, one MUST use
        /// <see cref="CompareTo(Maybe{T})"/> or <see cref="MaybeComparer{T}"/>
        /// as they produce a consistent total ordering.</para>
        /// </remarks>
        public static bool operator <(Maybe<T> left, Maybe<T> right) =>
            // Beware, this is NOT the same as
            //   left.CompareTo(right) < 0;
            left._isSome && right._isSome
                ? Comparer<T>.Default.Compare(left._value, right._value) < 0
                : false;

        /// <summary>
        /// Compares the two specified instances to see if the left one is
        /// less than or equal to the right one.
        /// <para>Beware, if either operand is empty, this operator will return
        /// false.</para>
        /// </summary>
        /// <remarks>
        /// <para>The weird behaviour with empty maybe's is the same one
        /// implemented by nullables.</para>
        /// <para>For proper sorting, one MUST use
        /// <see cref="CompareTo(Maybe{T})"/> or <see cref="MaybeComparer{T}"/>
        /// as they produce a consistent total ordering.</para>
        /// </remarks>
        public static bool operator <=(Maybe<T> left, Maybe<T> right) =>
            // Beware, this is NOT the same as
            //   left.CompareTo(right) <= 0;
            left._isSome && right._isSome
                ? Comparer<T>.Default.Compare(left._value, right._value) <= 0
                : false;

        /// <summary>
        /// Compares the two specified instances to see if the left one is
        /// strictly greater than the right one.
        /// <para>Beware, if either operand is empty, this operator will return
        /// false.</para>
        /// </summary>
        /// <remarks>
        /// <para>The weird behaviour with empty maybe's is the same one
        /// implemented by nullables.</para>
        /// <para>For proper sorting, one MUST use
        /// <see cref="CompareTo(Maybe{T})"/> or <see cref="MaybeComparer{T}"/>
        /// as they produce a consistent total ordering.</para>
        /// </remarks>
        public static bool operator >(Maybe<T> left, Maybe<T> right) =>
            // Beware, this is NOT the same as
            //   left.CompareTo(right) > 0;
            left._isSome && right._isSome
                ? Comparer<T>.Default.Compare(left._value, right._value) > 0
                : false;

        /// <summary>
        /// Compares the two specified instances to see if the left one is
        /// greater than or equal to the right one.
        /// <para>Beware, if either operand is empty, this operator will return
        /// false.</para>
        /// </summary>
        /// <remarks>
        /// <para>The weird behaviour with empty maybe's is the same one
        /// implemented by nullables.</para>
        /// <para>For proper sorting, one MUST use
        /// <see cref="CompareTo(Maybe{T})"/> or <see cref="MaybeComparer{T}"/>
        /// as they produce a consistent total ordering.</para>
        /// </remarks>
        public static bool operator >=(Maybe<T> left, Maybe<T> right) =>
            // Beware, this is NOT the same as
            //   left.CompareTo(right) >= 0;
            left._isSome && right._isSome
                ? Comparer<T>.Default.Compare(left._value, right._value) >= 0
                : false;

        /// <summary>
        /// Compares this instance to a specified <see cref="Maybe{T}"/> object.
        /// </summary>
        /// <remarks>
        /// The convention is that the empty maybe is strictly less than any
        /// other maybe.
        /// </remarks>
        public int CompareTo(Maybe<T> other) =>
            _isSome
                ? other._isSome ? Comparer<T>.Default.Compare(_value, other._value) : 1
                : other._isSome ? -1 : 0;

        /// <inheritdoc />
        int IComparable.CompareTo(object? obj)
        {
            if (obj is null) { return 1; }
            if (!(obj is Maybe<T> maybe))
            {
                throw EF.InvalidType(nameof(obj), typeof(Maybe<>), obj);
            }

            return CompareTo(maybe);
        }

        /// <inheritdoc />
        int IStructuralComparable.CompareTo(object? other, IComparer comparer)
        {
            if (comparer is null) { throw new Anexn(nameof(comparer)); }

            if (other is null) { return 1; }
            if (!(other is Maybe<T> maybe))
            {
                throw EF.InvalidType(nameof(other), typeof(Maybe<>), other);
            }

            // NB: structural comparison means that the comparer is expected to
            // be for T not for Maybe<T>, in particular it is not meant to work
            // with MaybeComparer<T>.Default.
            return _isSome
                ? maybe._isSome ? comparer.Compare(_value, maybe._value) : 1
                : maybe._isSome ? -1 : 0;
        }
    }

    // Interface IEquatable<> and alike.
    public partial struct Maybe<T>
    {
        /// <summary>
        /// Determines whether two specified instances of <see cref="Maybe{T}"/>
        /// are equal.
        /// </summary>
        public static bool operator ==(Maybe<T> left, Maybe<T> right) => left.Equals(right);

        /// <summary>
        /// Determines whether two specified instances of <see cref="Maybe{T}"/>
        /// are not equal.
        /// </summary>
        public static bool operator !=(Maybe<T> left, Maybe<T> right) => !left.Equals(right);

        /// <summary>
        /// Determines whether this instance is equal to the specified
        /// <see cref="Maybe{T}"/>.
        /// </summary>
        [Pure]
        public bool Equals(Maybe<T> other) =>
            _isSome
                ? other._isSome && EqualityComparer<T>.Default.Equals(_value, other._value)
                : !other._isSome;

        /// <inheritdoc />
        [Pure]
        public override bool Equals(object? obj) => obj is Maybe<T> maybe && Equals(maybe);

        /// <inheritdoc />
        [Pure]
        bool IStructuralEquatable.Equals(object? other, IEqualityComparer comparer)
        {
            if (comparer is null) { throw new Anexn(nameof(comparer)); }

            if (other is null || !(other is Maybe<T> maybe)) { return false; }

            // NB: structural comparison means that the comparer is expected to
            // be for T not for Maybe<T>.
            return _isSome ? maybe._isSome && comparer.Equals(_value, maybe._value)
                : !maybe._isSome;
        }

        /// <inheritdoc />
        [Pure]
        public override int GetHashCode() => _value?.GetHashCode() ?? 0;

        /// <inheritdoc />
        [Pure]
        int IStructuralEquatable.GetHashCode(IEqualityComparer comparer)
        {
            if (comparer is null) { throw new Anexn(nameof(comparer)); }

            // BONSANG! When _isSome is true, _value is NOT null.
            return _isSome ? comparer.GetHashCode(_value!) : 0;
        }
    }
}

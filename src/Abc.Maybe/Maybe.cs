// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;
    using System.ComponentModel;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;
    using System.Runtime.CompilerServices;

    using Anexn = System.ArgumentNullException;

    // REVIEW: playing with the in parameter modifier.
    //   Currently we stay conservative and only add it to selected ext methods
    //   for Maybe<T> where T is a struct.
    // REVIEW: unconstrained version of Square()?

    /// <summary>
    /// Provides static helpers and extension methods for <see cref="Maybe{T}"/>.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    public static partial class Maybe { }

    // Core methods: Of(), Flatten().
    public partial class Maybe
    {
        // I used to disallow an output of type Maybe<T?> for Of() and Flatten()
        // but there is actually no real reason to do that and it keeps things
        // homogeneous (Of() and Flatten() always behave the same way).
#if false // Only kept to be sure that I won't try it again... do NOT enable.

        /// <summary>
        /// Creates a new instance of the <see cref="Maybe{T}"/> struct from the
        /// specified nullable value.
        /// <para>DO NOT USE, only here to prevent the creation of maybe's for
        /// a nullable value type; see <see cref="SomeOrNone{T}(T?)"/> for a
        /// better alternative.</para>
        /// </summary>
        [Pure]
        // Not actually obsolete, but clearly states that we shouldn't use it.
        // Still, Select() allows the creation of a Maybe<T?>. For instance,
        //   Maybe.Some(1).Select(x => (int?)x);
        [Obsolete("Use SomeOrNone() instead.")]
        [EditorBrowsable(EditorBrowsableState.Never)]
        public static Maybe<T> Of<T>(T? value) where T : struct
            => value.HasValue ? new Maybe<T>(value.Value) : Maybe<T>.None;

        /// <summary>
        /// Removes one level of structure, projecting the bound value into the
        /// outer level.
        /// </summary>
        /// <para>DO NOT USE, only here to prevent the creation of maybe's for
        /// a nullable value type; see
        /// <see cref="Squash{T}(in Maybe{Maybe{T?}})"/> for a better
        /// alternative.</para>
        [Pure]
        [Obsolete("Use Squash() instead.")]
        [EditorBrowsable(EditorBrowsableState.Advanced)]
        public static Maybe<T> Flatten<T>(this in Maybe<Maybe<T?>> @this) where T : struct
            => @this.IsSome ? @this.Value.Squash() : Maybe<T>.None;

#endif

        /// <summary>
        /// Creates a new instance of the <see cref="Maybe{T}"/> struct from the
        /// specified nullable value.
        /// <para>RECOMMENDATION: for concrete types, <c>Some()</c> or
        /// <c>SomeOrNone()</c> should be preferred.</para>
        /// </summary>
        // Unconstrained version of SomeOrNone() and Some().
        // F# Workflow: return.
        [Pure]
        [EditorBrowsable(EditorBrowsableState.Advanced)]
        public static Maybe<T> Of<T>([AllowNull] T value)
            => value is null ? Maybe<T>.None : new Maybe<T>(value);

        /// <summary>
        /// Removes one level of structure, projecting the bound value into the
        /// outer level.
        /// <para>RECOMMENDATION: for concrete nullable types, <c>Squash()</c>
        /// is in general more appropriate.
        /// </para>
        /// </summary>
        // Unconstrained version of Squash().
        [Pure]
        public static Maybe<T> Flatten<T>(this Maybe<Maybe<T>> @this)
            => @this.IsSome ? @this.Value : Maybe<T>.None;
    }

    // Factory methods: None(), Some(), SomeOrNone(), Square(), SquareOrNone().
    public partial class Maybe
    {
        /// <summary>
        /// Obtains an instance of the empty <see cref="Maybe{T}" />.
        /// </summary>
        /// <remarks>
        /// To obtain the empty maybe for an unconstrained generic type paramater,
        /// use <see cref="Maybe{T}.None"/> instead.
        /// </remarks>
        [Pure]
        // Code size = 6 bytes.
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Maybe<T> None<T>() where T : notnull
            => Maybe<T>.None;

        /// <summary>
        /// Creates a new instance of the <see cref="Maybe{T}"/> struct from the
        /// specified value.
        /// </summary>
        [Pure]
        // Code size = 7 bytes.
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Maybe<T> Some<T>(T value) where T : struct
            => new(value);

        /// <summary>
        /// Creates a new instance of the <see cref="Maybe{T}"/> struct from the
        /// specified nullable value.
        /// </summary>
        /// <remarks>
        /// To create a maybe for an unconstrained generic type parameter, use
        /// <see cref="Of{T}(T)"/> instead.
        /// </remarks>
        [Pure]
        public static Maybe<T> SomeOrNone<T>(T? value) where T : struct
            // DO NOT REMOVE THIS METHOD.
            // Prevents the creation of a Maybe<T?> **directly**.
            => value.HasValue ? new Maybe<T>(value.Value) : Maybe<T>.None;

        /// <summary>
        /// Creates a new instance of the <see cref="Maybe{T}"/> struct from the
        /// specified nullable value.
        /// </summary>
        /// <remarks>
        /// To create a maybe for an unconstrained generic type parameter, use
        /// <see cref="Of{T}(T)"/> instead.
        /// </remarks>
        [Pure]
        public static Maybe<T> SomeOrNone<T>(T? value) where T : class
            => value is null ? Maybe<T>.None : new Maybe<T>(value);

        // Most of the time we believe that we have to create a "double" maybe
        // it's because we want to make it work with another "double", whereas
        // the proper solution is to Squash()/Flatten() the later.

        // Identical to Maybe.Some(Maybe.Some()).
        [Pure]
        public static Maybe<Maybe<T>> Square<T>(T value) where T : struct
            => new(new Maybe<T>(value));

        // Beware, not identical to Maybe.Some(Maybe.SomeOrNone()).
        // They only match when value is NOT null.
        [Pure]
        public static Maybe<Maybe<T>> SquareOrNone<T>(T? value) where T : struct
            => value.HasValue ? new Maybe<Maybe<T>>(new Maybe<T>(value.Value)) : Maybe<Maybe<T>>.None;

        // Beware, not identical to Maybe.Some(Maybe.SomeOrNone()).
        // They only match when value is NOT null.
        [Pure]
        public static Maybe<Maybe<T>> SquareOrNone<T>(T? value) where T : class
            => value is null ? Maybe<Maybe<T>>.None : new Maybe<Maybe<T>>(new Maybe<T>(value));
    }

    // Normalization: Squash().
    public partial class Maybe
    {
        [Pure]
        public static Maybe<T> Squash<T>(this in Maybe<T?> @this) where T : struct
            // BONSANG! when IsSome is true, Value.HasValue is also true,
            // therefore we can safely access Value.Value.
            => @this.IsSome ? Some(@this.Value!.Value) : Maybe<T>.None;

        // Beware, this method just returns its input.
        // Instead, the caller could disable nullable warnings locally.
        [Pure]
        [EditorBrowsable(EditorBrowsableState.Advanced)]
        // Code size = 2 bytes.
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static Maybe<T> Squash<T>(this Maybe<T?> @this) where T : class
            // We disable NRT, otherwise we would have to write:
            //   @this.IsSome ? new Maybe<T>(@this.Value!) : Maybe<T>.None;
#nullable disable warnings
            => @this;
#nullable restore warnings

        // Unconstrained version: Flatten().
        [Pure]
        public static Maybe<T> Squash<T>(this in Maybe<Maybe<T?>> @this) where T : struct
            => @this.IsSome ? @this.Value.Squash() : Maybe<T>.None;

        // Unconstrained version: Flatten().
        [Pure]
        public static Maybe<T> Squash<T>(this Maybe<Maybe<T?>> @this) where T : class
            // We disable nullable warnings, otherwise we would have to write:
            //   @this.IsSome ? @this.Value.Squash() : Maybe<T>.None;
            // but Squash() does actually nothing.
#nullable disable warnings
            => @this.IsSome ? @this.Value : Maybe<T>.None;
#nullable restore warnings
    }

    // Helpers for Maybe<T> where T is a struct.
    public partial class Maybe
    {
        // Conversion from Maybe<T?> to T?.
        [Pure]
        public static T? ToNullable<T>(this in Maybe<T?> @this) where T : struct
#if DEBUG
            // We have to be careful in Debug mode since the access to Value is
            // protected by a Debug.Assert.
            => @this.IsSome ? @this.Value : null;
#else
            // If the object is "none", Value is default(T?) ie null.
            => @this.Value;
#endif

        // Conversion from Maybe<T> to T?.
        [Pure]
        public static T? ToNullable<T>(this in Maybe<T> @this) where T : struct
            => @this.IsSome ? @this.Value : (T?)null;
    }

    // Helpers for Maybe<Unit>.
    public partial class Maybe
    {
        /// <summary>
        /// Represents the unit for the type <see cref="Maybe{T}"/> where
        /// <c>T</c> is the <see cref="Abc.Unit"/> type.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Maybe<Unit> Unit = Some(default(Unit));

        /// <summary>
        /// Represents the zero for <see cref="Maybe{T}.Bind"/>where
        /// <c>T</c> is the <see cref="Abc.Unit"/> type.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Maybe<Unit> Zero = Maybe<Unit>.None;

        [Pure]
        public static Maybe<Unit> Guard(bool condition)
            => condition ? Unit : Zero;
    }

    // Helpers for Maybe<bool>.
    // 3VL (three-valued logic) logical operations.
    // It makes Maybe<bool>.None and SQL NULL very similar but only for boolean
    // logical operations, otherwise they may exhibit different behaviours.
    // For instance, with SQL-92 (NULL = NULL) evaluates to false, whereas
    // (Maybe<bool>.None == Maybe<bool>.None) evaluates to true.
    public partial class Maybe
    {
        /// <summary>
        /// Represents the unknown for the type <see cref="Maybe{T}"/> where
        /// <c>T</c> is the <see cref="Boolean"/> type.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Maybe<bool> Unknown = Maybe<bool>.None;

        /// <summary>
        /// Represents the true for the type <see cref="Maybe{T}"/> where
        /// <c>T</c> is the <see cref="Boolean"/> type.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Maybe<bool> True = Some(true);

        /// <summary>
        /// Represents the false for the type <see cref="Maybe{T}"/> where
        /// <c>T</c> is the <see cref="Boolean"/> type.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Maybe<bool> False = Some(false);

        [Pure]
        public static Maybe<bool> Negate(this in Maybe<bool> @this)
        {
            return @this.IsSome ? Some(!@this.Value) : Unknown;
        }

        // Compare to OrElse().
        [Pure]
        public static Maybe<bool> Or(this in Maybe<bool> @this, Maybe<bool> other)
        {
            // true  || _     = true
            // false || true  = true
            //       || false = false
            //       || None  = None
            // None  || true  = true
            //       || false = None
            //       || None  = None

            // If one of the two values is "true", return True.
            return (@this.IsSome && @this.Value) || (other.IsSome && other.Value) ? True
                : @this.IsSome && other.IsSome ? False
                : Unknown;
        }

        // Compare to AndElse().
        [Pure]
        public static Maybe<bool> And(this in Maybe<bool> @this, Maybe<bool> other)
        {
            // true  && true  = true
            //       && false = false
            //       && None  = None
            // false && _     = false
            // None  && true  = None
            //       && false = false
            //       && None  = None

            // If one of the two values is "false", return False.
            return (@this.IsSome && !@this.Value) || (other.IsSome && !other.Value) ? False
                : @this.IsSome && other.IsSome ? True
                : Unknown;
        }
    }

    // Helpers for Maybe<T> where T is disposable.
    public partial class Maybe
    {
        // Bind() with automatic resource cleanup.
        // F# Workflow: use.
        [Pure]
        public static Maybe<TResult> Use<TDisposable, TResult>(
            this Maybe<TDisposable> @this,
            Func<TDisposable, Maybe<TResult>> binder)
            where TDisposable : IDisposable
        {
            if (binder is null) { throw new Anexn(nameof(binder)); }

            return @this.Bind(x => { using (x) { return binder(x); } });
        }

        // Select() with automatic resource cleanup.
        [Pure]
        public static Maybe<TResult> Use<TDisposable, TResult>(
            this Maybe<TDisposable> @this,
            Func<TDisposable, TResult> selector)
            where TDisposable : IDisposable
        {
            if (selector is null) { throw new Anexn(nameof(selector)); }

            return @this.Select(x => { using (x) { return selector(x); } });
        }
    }
}

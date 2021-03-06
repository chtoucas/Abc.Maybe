﻿// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System.Collections;
    using System.Collections.Generic;
    using System.Diagnostics.CodeAnalysis;
    using System.Diagnostics.Contracts;
    using System.Runtime.CompilerServices;
    using System.Threading;

    using Anexn = System.ArgumentNullException;
    using EF = Abc.Utilities.ExceptionFactory;

    // Pluggable comparison for both order and equality.
    public abstract class MaybeComparer<T>
        : IEqualityComparer<Maybe<T>>, IEqualityComparer, IComparer<Maybe<T>>, IComparer
    {
        protected MaybeComparer() { }

        [SuppressMessage("Design", "CA1000:Do not declare static members on generic types")]
        public static MaybeComparer<T> Default => s_Default ??= InitialiseDefault();

        private static MaybeComparer<T>? s_Default;
        [Pure]
        private static MaybeComparer<T> InitialiseDefault()
        {
            var cmp = new DefaultMaybeComparer<T>();
            Interlocked.CompareExchange(ref s_Default, cmp, null);
            // BONSANG!
            return s_Default!;
        }

        [SuppressMessage("Design", "CA1000:Do not declare static members on generic types")]
        public static MaybeComparer<T> Structural => s_Structural ??= InitialiseStructural();

        private static MaybeComparer<T>? s_Structural;
        [Pure]
        private static MaybeComparer<T> InitialiseStructural()
        {
            var cmp = new StructuralMaybeComparer<T>();
            Interlocked.CompareExchange(ref s_Structural, cmp, null);
            // BONSANG!
            return s_Structural!;
        }

        [Pure] public abstract bool Equals(Maybe<T> x, Maybe<T> y);

        [Pure] public abstract int GetHashCode(Maybe<T> obj);

        [Pure] public abstract int Compare(Maybe<T> x, Maybe<T> y);

        /// <inheritdoc />
        [Pure]
        bool IEqualityComparer.Equals(object? x, object? y)
        {
            // REVIEW: x == y?
            if (ReferenceEquals(x, y)) { return true; }
            if (x is null || y is null) { return false; }
            if (x is Maybe<T> left && y is Maybe<T> right) { return Equals(left, right); }
            throw EF.MaybeComparer_InvalidType;
        }

        /// <inheritdoc />
        [Pure]
        int IEqualityComparer.GetHashCode(object obj)
        {
            if (obj is null) { throw new Anexn(nameof(obj)); }

            if (obj is Maybe<T> maybe) { return GetHashCode(maybe); }
            throw EF.MaybeComparer_InvalidType;
        }

        /// <inheritdoc />
        [Pure]
        int IComparer.Compare(object? x, object? y)
        {
            if (x is null) { return y is null ? 0 : -1; }
            if (y is null) { return 1; }
            if (x is Maybe<T> left && y is Maybe<T> right) { return Compare(left, right); }
            throw EF.MaybeComparer_InvalidType;
        }
    }

    // Identical to what Maybe<T> does, but made available separately.
    internal sealed class DefaultMaybeComparer<T> : MaybeComparer<T>
    {
        public DefaultMaybeComparer() { }

        [Pure]
        // Code size = 56 bytes, way to high (> 32 bytes).
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override bool Equals(Maybe<T> x, Maybe<T> y) =>
#if WITHIN_ABC_MAYBE
            // BONSANG! When IsSome is true, Value is NOT null.
            x.IsSome ? y.IsSome && EqualityComparer<T>.Default.Equals(x.Value!, y.Value!)
                : !y.IsSome;
#else
            x.TryGetValue(out T? left)
                ? y.TryGetValue(out T? right) && EqualityComparer<T>.Default.Equals(left, right)
                : y.IsNone;
#endif

        [Pure]
        // Code size = 29 bytes.
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int GetHashCode(Maybe<T> obj) =>
            // BONSANG! When IsSome is true, Value is NOT null.
#if WITHIN_ABC_MAYBE
            obj.IsSome ? EqualityComparer<T>.Default.GetHashCode(obj.Value!) : 0;
#else
            obj.TryGetValue(out T? value) ? EqualityComparer<T>.Default.GetHashCode(value!) : 0;
#endif

        // A total order for maybe's. The convention is that the empty maybe is
        // strictly less than any other maybe.
        [Pure]
        // Code size = 58 bytes, way to high (> 32 bytes).
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int Compare(Maybe<T> x, Maybe<T> y) =>
#if WITHIN_ABC_MAYBE
            // BONSANG! When IsSome is true, Value is NOT null.
            x.IsSome ? y.IsSome ? Comparer<T>.Default.Compare(x.Value!, y.Value!) : 1
                : y.IsSome ? -1 : 0;
#else
            x.TryGetValue(out T? left) ? y.TryGetValue(out T? right)
                ? Comparer<T>.Default.Compare(left, right) : 1
                : y.IsNone ? 0 : -1;
#endif

        //
        // Equals() & GetHashCode() for the comparer itself.
        //

        [Pure]
        public override bool Equals(object? obj) =>
            obj != null && GetType() == obj.GetType();

        [Pure]
        public override int GetHashCode() => GetType().GetHashCode();
    }

    internal sealed class StructuralMaybeComparer<T> : MaybeComparer<T>
    {
        public StructuralMaybeComparer() { }

        [Pure]
        // Code size = 66 bytes, way to high (> 32 bytes).
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override bool Equals(Maybe<T> x, Maybe<T> y) =>
#if WITHIN_ABC_MAYBE
            x.IsSome
                ? y.IsSome && StructuralComparisons.StructuralEqualityComparer.Equals(x.Value, y.Value)
                : !y.IsSome;
#else
            x.TryGetValue(out T? left)
                ? y.TryGetValue(out T? right) && StructuralComparisons.StructuralEqualityComparer.Equals(left, right)
                : y.IsNone;
#endif

        [Pure]
        // Code size = 34 bytes.
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int GetHashCode(Maybe<T> obj) =>
#if WITHIN_ABC_MAYBE
            // BONSANG! When IsSome is true, Value is NOT null.
            obj.IsSome ? StructuralComparisons.StructuralEqualityComparer.GetHashCode(obj.Value!) : 0;
#else
            obj.TryGetValue(out T? value) ? StructuralComparisons.StructuralEqualityComparer.GetHashCode(value!) : 0;
#endif

        [Pure]
        // Code size = 68 bytes, way to high (> 32 bytes).
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int Compare(Maybe<T> x, Maybe<T> y) =>
#if WITHIN_ABC_MAYBE
            x.IsSome
                ? y.IsSome ? StructuralComparisons.StructuralComparer.Compare(x.Value, y.Value) : 1
                : y.IsSome ? -1 : 0;
#else
            x.TryGetValue(out T? left) ? y.TryGetValue(out T? right)
                ? StructuralComparisons.StructuralComparer.Compare(left, right) : 1
                : y.IsNone ? 0 : -1;
#endif

        //
        // Equals() & GetHashCode() for the comparer itself.
        //

        [Pure]
        public override bool Equals(object? obj) =>
            obj != null && GetType() == obj.GetType();

        [Pure]
        public override int GetHashCode() => GetType().GetHashCode();
    }
}

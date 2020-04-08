// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Collections;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Runtime.CompilerServices;
    using System.Threading;

    using EF = Abc.Utilities.ExceptionFactory;

    // TODO: should we make it work with a comparer w/ Maybe<T>.
    //   return comparer.Compare(this, maybe);
    // Split equality and order?
    // "Lifted" comparison T / Maybe<T>?

    // Pluggable comparison.
    public abstract class MaybeComparer<T>
        : IEqualityComparer<Maybe<T>>, IEqualityComparer, IComparer<Maybe<T>>, IComparer
    {
        protected MaybeComparer() { }

#pragma warning disable CA1000 // Do not declare static members on generic types

        public static MaybeComparer<T> Default => s_Default ??= InitialiseDefault();

        private static MaybeComparer<T>? s_Default;
        [Pure]
        private static MaybeComparer<T> InitialiseDefault()
        {
            var cmp = new DefaultMaybeComparer<T>();
            Interlocked.CompareExchange(ref s_Default, cmp, null);
            return s_Default!;
        }

        public static MaybeComparer<T> Structural => s_Structural ??= InitialiseStructural();

        private static MaybeComparer<T>? s_Structural;
        [Pure]
        private static MaybeComparer<T> InitialiseStructural()
        {
            var cmp = new StructuralMaybeComparer<T>();
            Interlocked.CompareExchange(ref s_Structural, cmp, null);
            return s_Structural!;
        }

#pragma warning restore CA1000

        [Pure] public abstract bool Equals(Maybe<T> x, Maybe<T> y);

        [Pure] public abstract int GetHashCode(Maybe<T> obj);

        [Pure] public abstract int Compare(Maybe<T> x, Maybe<T> y);

        /// <inheritdoc />
        [Pure]
        bool IEqualityComparer.Equals(object? x, object? y)
        {
            if (x == y) { return true; }
            if (x is null || y is null) { return false; }
            if (x is Maybe<T> left && y is Maybe<T> right) { return Equals(left, right); }
            throw EF.MaybeComparer_InvalidType;
        }

        /// <inheritdoc />
        [Pure]
        int IEqualityComparer.GetHashCode(object? obj)
        {
            if (obj is null) { return 0; }
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
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override bool Equals(Maybe<T> x, Maybe<T> y) =>
            // BONSANG! When IsSome is true, Value is NOT null.
            x.IsSome ? y.IsSome && EqualityComparer<T>.Default.Equals(x.Value!, y.Value!)
                : !y.IsSome;

        [Pure]
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int GetHashCode(Maybe<T> obj) =>
            // BONSANG! When IsSome is true, Value is NOT null.
            obj.IsSome ? EqualityComparer<T>.Default.GetHashCode(obj.Value!) : 0;

        // A total order for maybe's. The convention is that the empty maybe is
        // strictly less than any other maybe.
        [Pure]
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int Compare(Maybe<T> x, Maybe<T> y) =>
            // BONSANG! When IsSome is true, Value is NOT null.
            x.IsSome ? y.IsSome ? Comparer<T>.Default.Compare(x.Value!, y.Value!) : 1
                : y.IsSome ? -1 : 0;

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
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override bool Equals(Maybe<T> x, Maybe<T> y) =>
            x.IsSome
                ? y.IsSome && StructuralComparisons.StructuralEqualityComparer.Equals(x.Value, y.Value)
                : !y.IsSome;

        [Pure]
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int GetHashCode(Maybe<T> obj) =>
            // BONSANG! When IsSome is true, Value is NOT null.
            obj.IsSome ? StructuralComparisons.StructuralEqualityComparer.GetHashCode(obj.Value!) : 0;

        [Pure]
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public override int Compare(Maybe<T> x, Maybe<T> y) =>
            x.IsSome
                ? y.IsSome ? StructuralComparisons.StructuralComparer.Compare(x.Value, y.Value) : 1
                : y.IsSome ? -1 : 0;

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

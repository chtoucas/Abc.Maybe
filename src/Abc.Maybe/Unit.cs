// See LICENSE in the project root for license information.

#pragma warning disable CA1801 // -Review unused parameters

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;

    // See https://en.wikipedia.org/wiki/Unit_type

    /// <summary>
    /// Defines a Unit type.
    /// <para><see cref="Unit"/> is an immutable struct.</para>
    /// </summary>
    [Serializable]
    public readonly struct Unit : IEquatable<Unit>
#if !NETFRAMEWORK // ValueTuple
        , IEquatable<ValueTuple>
#endif
    {
        /// <summary>
        /// Represents the singleton instance of the <see cref="Unit"/> struct.
        /// <para>This field is read-only.</para>
        /// </summary>
        public static readonly Unit Default = default;

        /// <summary>
        /// Returns a string representation of the current instance.
        /// </summary>
        [Pure]
        public override string ToString() => "()";

        /// <summary>
        /// Always returns true.
        /// </summary>
        public static bool operator ==(Unit left, Unit right) => true;

        /// <summary>
        /// Always returns false.
        /// </summary>
        public static bool operator !=(Unit left, Unit right) => false;

#if !NETFRAMEWORK // ValueTuple
        /// <summary>
        /// Always returns true.
        /// </summary>
        public static bool operator ==(Unit left, ValueTuple right) => true;

        /// <summary>
        /// Always returns true.
        /// </summary>
        public static bool operator ==(ValueTuple left, Unit right) => true;

        /// <summary>
        /// Always returns false.
        /// </summary>
        public static bool operator !=(Unit left, ValueTuple right) => false;

        /// <summary>
        /// Always returns false.
        /// </summary>
        public static bool operator !=(ValueTuple left, Unit right) => false;
#endif

        /// <summary>
        /// Always returns true.
        /// </summary>
        [Pure]
        public bool Equals(Unit other) => true;

#if !NETFRAMEWORK // ValueTuple
        /// <summary>
        /// Always returns true.
        /// </summary>
        [Pure]
        public bool Equals(ValueTuple other) => true;

        /// <inheritdoc />
        [Pure]
        public override bool Equals(object? obj) => obj is Unit || obj is ValueTuple;
#else
        /// <inheritdoc />
        [Pure]
        public override bool Equals(object? obj) => obj is Unit;
#endif

        /// <inheritdoc />
        [Pure]
        public override int GetHashCode() => 0;
    }
}

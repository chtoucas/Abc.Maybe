// See LICENSE in the project root for license information.

namespace Abc.Extensions
{
    using System;
    using System.Data.SqlTypes;

    using MaybeT = Maybe;

    /// <summary>
    /// Provides extension methods to convert native SQL server data types to
    /// CLR types.
    /// </summary>
    public static partial class SqlTypesX { }

    // TODO: warn that a SQL null is not the same as a CLR null.
    // Check that 3VL for Maybe<bool> matches the behaviour of SqlBoolean.

    // CLR value types.
    public partial class SqlTypesX
    {
        public static Maybe<bool> Maybe(this SqlBoolean @this)
            => @this.IsNull ? Maybe<bool>.None : MaybeT.Some(@this.Value);

        public static Maybe<byte> Maybe(this SqlByte @this)
            => @this.IsNull ? Maybe<byte>.None : MaybeT.Some(@this.Value);

        public static Maybe<DateTime> Maybe(this SqlDateTime @this)
            => @this.IsNull ? Maybe<DateTime>.None : MaybeT.Some(@this.Value);

        public static Maybe<decimal> Maybe(this SqlDecimal @this)
            => @this.IsNull ? Maybe<decimal>.None : MaybeT.Some(@this.Value);

        public static Maybe<double> Maybe(this SqlDouble @this)
            => @this.IsNull ? Maybe<double>.None : MaybeT.Some(@this.Value);

        public static Maybe<Guid> Maybe(this SqlGuid @this)
            => @this.IsNull ? Maybe<Guid>.None : MaybeT.Some(@this.Value);

        public static Maybe<short> Maybe(this SqlInt16 @this)
            => @this.IsNull ? Maybe<short>.None : MaybeT.Some(@this.Value);

        public static Maybe<int> Maybe(this SqlInt32 @this)
            => @this.IsNull ? Maybe<int>.None : MaybeT.Some(@this.Value);

        public static Maybe<long> Maybe(this SqlInt64 @this)
            => @this.IsNull ? Maybe<long>.None : MaybeT.Some(@this.Value);

        public static Maybe<decimal> Maybe(this SqlMoney @this)
            => @this.IsNull ? Maybe<decimal>.None : MaybeT.Some(@this.Value);

        public static Maybe<float> Maybe(this SqlSingle @this)
            => @this.IsNull ? Maybe<float>.None : MaybeT.Some(@this.Value);
    }

    // CLR reference types.
    public partial class SqlTypesX
    {
        public static Maybe<byte[]> Maybe(this SqlBinary @this)
            // With Guard():
            //   MaybeT.Guard(!@this.IsNull).ReplaceWith(@this.Value);
            => @this.IsNull ? Maybe<byte[]>.None : MaybeT.SomeOrNone(@this.Value);

        public static Maybe<string> Maybe(this SqlString @this)
            => @this.IsNull ? Maybe<string>.None : MaybeT.SomeOrNone(@this.Value);

        /// <remarks>
        /// Beware, this extension method does NOT throw when the object is null
        /// but rather returns an empty maybe.
        /// </remarks>
        public static Maybe<byte[]> Maybe(this SqlBytes? @this)
            => from x in MaybeT.SomeOrNone(@this) where !x.IsNull select x.Value;

        /// <remarks>
        /// Beware, this extension method does NOT throw when the object is null
        /// but rather returns an empty maybe.
        /// </remarks>
        public static Maybe<char[]> Maybe(this SqlChars? @this)
            => from x in MaybeT.SomeOrNone(@this) where !x.IsNull select x.Value;

        /// <remarks>
        /// Beware, this extension method does NOT throw when the object is null
        /// but rather returns an empty maybe.
        /// </remarks>
        public static Maybe<string> Maybe(this SqlXml? @this)
            => from x in MaybeT.SomeOrNone(@this) where !x.IsNull select x.Value;
    }
}

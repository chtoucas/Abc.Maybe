// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Globalization;

    // More May-Parse methods. Mostly wraps Try-Parse methods that are not
    // available in .NET Standard 2.0.
    public sealed partial class MayEx : May
    {
        private MayEx() { }
    }

    public partial class MayEx
    {
        public static Maybe<bool> ParseBoolean(string? value, BooleanStyles style)
        {
            if (value is null) { return Maybe<bool>.None; }

            string trimmed = value.Trim();

            if (trimmed.Length == 0)
            {
                return style.Contains(BooleanStyles.EmptyOrWhiteSpaceIsFalse)
                    ? Maybe.Some(false) : Maybe<bool>.None;
            }
            else if (style.Contains(BooleanStyles.Literal))
            {
                // NB: this method is case-insensitive.
                return Boolean.TryParse(trimmed, out bool retval)
                    ? Maybe.Some(retval) : Maybe<bool>.None;
            }
            else if (style.Contains(BooleanStyles.ZeroOrOne)
                && (trimmed == "0" || trimmed == "1"))
            {
                return Maybe.Some(trimmed == "1");
            }
            else if (style.Contains(BooleanStyles.HtmlInput) && value == "on")
            {
                return Maybe.Some(true);
            }
            else
            {
                return Maybe<bool>.None;
            }
        }
    }

    // Parsers for simple value types.
    public partial class MayEx
    {
#if !NETSTANDARD2_0
        [Pure]
        public static Maybe<bool> ParseBoolean(ReadOnlySpan<char> span)
        {
            return Boolean.TryParse(span, out bool result)
                ? Maybe.Some(result) : Maybe<bool>.None;
        }

        [Pure]
        public static Maybe<decimal> ParseDecimal(ReadOnlySpan<char> span)
        {
            return Decimal.TryParse(span, out decimal result)
                ? Maybe.Some(result) : Maybe<decimal>.None;
        }

        [Pure]
        public static Maybe<decimal> ParseDecimal(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Decimal.TryParse(span, style, provider, out decimal result)
                ? Maybe.Some(result) : Maybe<decimal>.None;
        }

        [Pure]
        public static Maybe<double> ParseDouble(ReadOnlySpan<char> span)
        {
            return Double.TryParse(span, out double result)
                ? Maybe.Some(result) : Maybe<double>.None;
        }

        [Pure]
        public static Maybe<double> ParseDouble(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Double.TryParse(span, style, provider, out double result)
                ? Maybe.Some(result) : Maybe<double>.None;
        }

        [Pure]
        public static Maybe<short> ParseInt16(ReadOnlySpan<char> span)
        {
            return Int16.TryParse(span, out short result)
                ? Maybe.Some(result) : Maybe<short>.None;
        }

        [Pure]
        public static Maybe<short> ParseInt16(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Int16.TryParse(span, style, provider, out short result)
                ? Maybe.Some(result) : Maybe<short>.None;
        }

        [Pure]
        public static Maybe<int> ParseInt32(ReadOnlySpan<char> span)
        {
            return Int32.TryParse(span, out int result)
                ? Maybe.Some(result) : Maybe<int>.None;
        }

        [Pure]
        public static Maybe<int> ParseInt32(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Int32.TryParse(span, style, provider, out int result)
                ? Maybe.Some(result) : Maybe<int>.None;
        }

        [Pure]
        public static Maybe<long> ParseInt64(ReadOnlySpan<char> span)
        {
            return Int64.TryParse(span, out long result)
                ? Maybe.Some(result) : Maybe<long>.None;
        }

        [Pure]
        public static Maybe<long> ParseInt64(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Int64.TryParse(span, style, provider, out long result)
                ? Maybe.Some(result) : Maybe<long>.None;
        }

        [Pure]
        public static Maybe<float> ParseSingle(ReadOnlySpan<char> span)
        {
            return Single.TryParse(span, out float result)
                ? Maybe.Some(result) : Maybe<float>.None;
        }

        [Pure]
        public static Maybe<float> ParseSingle(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Single.TryParse(span, style, provider, out float result)
                ? Maybe.Some(result) : Maybe<float>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<sbyte> ParseSByte(ReadOnlySpan<char> span)
        {
            return SByte.TryParse(span, out sbyte result)
                ? Maybe.Some(result) : Maybe<sbyte>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<sbyte> ParseSByte(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return SByte.TryParse(span, style, provider, out sbyte result)
                ? Maybe.Some(result) : Maybe<sbyte>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<byte> ParseByte(ReadOnlySpan<char> span)
        {
            return Byte.TryParse(span, out byte result)
                ? Maybe.Some(result) : Maybe<byte>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<byte> ParseByte(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return Byte.TryParse(span, style, provider, out byte result)
                ? Maybe.Some(result) : Maybe<byte>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<ushort> ParseUInt16(ReadOnlySpan<char> span)
        {
            return UInt16.TryParse(span, out ushort result)
                ? Maybe.Some(result) : Maybe<ushort>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<ushort> ParseUInt16(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return UInt16.TryParse(span, style, provider, out ushort result)
                ? Maybe.Some(result) : Maybe<ushort>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<uint> ParseUInt32(ReadOnlySpan<char> span)
        {
            return UInt32.TryParse(span, out uint result)
                ? Maybe.Some(result) : Maybe<uint>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<uint> ParseUInt32(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return UInt32.TryParse(span, style, provider, out uint result)
                ? Maybe.Some(result) : Maybe<uint>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<ulong> ParseUInt64(ReadOnlySpan<char> span)
        {
            return UInt64.TryParse(span, out ulong result)
                ? Maybe.Some(result) : Maybe<ulong>.None;
        }

        [Pure]
        [CLSCompliant(false)]
        public static Maybe<ulong> ParseUInt64(
            ReadOnlySpan<char> span, NumberStyles style, IFormatProvider? provider)
        {
            return UInt64.TryParse(span, style, provider, out ulong result)
                ? Maybe.Some(result) : Maybe<ulong>.None;
        }
#endif
    }

    // Parsers for value types that are not simple types.
    public partial class MayEx
    {
#if !NETSTANDARD2_0
        [Pure]
        public static Maybe<object> ParseEnum(Type enumType, string? value)
            => Enum.TryParse(enumType, value, out object? result)
                ? Maybe.SomeOrNone(result) : Maybe<object>.None;

        [Pure]
        public static Maybe<object> ParseEnum(
            Type enumType, string? value, bool ignoreCase)
            => Enum.TryParse(enumType, value, ignoreCase, out object? result)
                ? Maybe.SomeOrNone(result) : Maybe<object>.None;

        [Pure]
        public static Maybe<DateTime> ParseDateTime(ReadOnlySpan<char> span)
        {
            return DateTime.TryParse(span, out DateTime result)
                ? Maybe.Some(result) : Maybe<DateTime>.None;
        }

        [Pure]
        public static Maybe<DateTime> ParseDateTime(
            ReadOnlySpan<char> span, IFormatProvider? provider, DateTimeStyles style)
        {
            return DateTime.TryParse(span, provider, style, out DateTime result)
                ? Maybe.Some(result) : Maybe<DateTime>.None;
        }

        [Pure]
        public static Maybe<DateTime> ParseDateTimeExact(
            ReadOnlySpan<char> span,
            string? format,
            IFormatProvider? provider,
            DateTimeStyles style)
        {
            return DateTime.TryParseExact(span, format, provider, style, out DateTime result)
                ? Maybe.Some(result) : Maybe<DateTime>.None;
        }

        [Pure]
        public static Maybe<DateTime> ParseDateTimeExact(
            ReadOnlySpan<char> span,
            string?[]? formats,
            IFormatProvider? provider,
            DateTimeStyles style)
        {
            return DateTime.TryParseExact(span, formats, provider, style, out DateTime result)
                ? Maybe.Some(result) : Maybe<DateTime>.None;
        }
#endif
    }
}

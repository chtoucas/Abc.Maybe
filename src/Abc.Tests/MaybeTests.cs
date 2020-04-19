﻿// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.IO;
    using System.Linq;
    using System.Runtime.Serialization;
    using System.Runtime.Serialization.Formatters.Binary;
    using System.Threading.Tasks;

    using Xunit;

    using Assert = AssertEx;

    // For the core methods (factories, simple conversions), we do testing with
    // many different types even if this is rather unnecessary but, among other
    // things, we wish to see Maybe at work in all kind of situation (in
    // particular with NRTs).
    // - Unit
    // - int
    // - long
    // - string
    // - Uri
    // - AnyT
    // - object
    // and their nullable counterparts.
    // For the other methods, we don't really bother and, in general, we write
    // tests only with
    // - int
    // - string
    // - Uri
    // - AnyT
    // In general, we do not hesitate to test the obvious and to write redundant
    // tests.

    public static partial class MaybeTests
    {
        private const string Anagram = "chicane";
        private const string Margana = "caniche";

        // Defined only to simplify the access to Unit.Default (a test method
        // has exactly the same name).
        private static readonly Unit UNIT = Abc.Unit.Default;

        private static readonly Maybe<int> Ø = Maybe<int>.None;
        private static readonly Maybe<long> ØL = Maybe<long>.None;

        private static readonly Maybe<int> One = Maybe.Some(1);
        private static readonly Maybe<int> Two = Maybe.Some(2);
        private static readonly Maybe<long> TwoL = Maybe.Some(2L);

        private const string MyText = "text";
        private static readonly Maybe<string> NoText = Maybe<string>.None;
        private static readonly Maybe<string> SomeText = Maybe.SomeOrNone(MyText);

        private static readonly Uri MyUri;
        private static readonly Maybe<Uri> NoUri = Maybe<Uri>.None;
        private static readonly Maybe<Uri> SomeUri;

#pragma warning disable CA1810 // Initialize reference type static fields inline
        static MaybeTests()
        {
            MyUri = new Uri("http://www.narvalo.org");
            SomeUri = Maybe.SomeOrNone(MyUri);
        }
#pragma warning restore CA1810

        [Pure]
        public static Func<Task<Maybe<T>>> ReturnSync_<T>(T result) where T : notnull
            => () => Task.FromResult(Maybe.Of(result));

        [Pure]
        public static Func<Task<Maybe<T>>> ReturnAsync_<T>(T result) where T : notnull
            => async () => { await Task.Yield(); return Maybe.Of(result); };

        [Pure] private static T Ident<T>(T x) where T : notnull => x;

        [Pure] private static int Times3(int x) => 3 * x;
        [Pure] private static Task<int> Times3Sync(int x) => Task.FromResult(3 * x);
        [Pure] private static async Task<int> Times3Async(int x) { await Task.Yield(); return 3 * x; }

        [Pure] private static Maybe<int> Times3_(int x) => Maybe.Some(3 * x);
        [Pure] private static Task<Maybe<int>> Times3Sync_(int x) => Task.FromResult(Maybe.Some(3 * x));
        [Pure] private static async Task<Maybe<int>> Times3Async_(int x) { await Task.Yield(); return Maybe.Some(3 * x); }

        [Pure] private static long Times4(long x) => 4L * x;
        [Pure] private static Task<long> Times4Sync(long x) => Task.FromResult(4L * x);
        [Pure] private static async Task<long> Times4Async(long x) { await Task.Yield(); return 4L * x; }

        [Pure] private static Maybe<long> Times4_(long x) => Maybe.Some(4L * x);
        [Pure] private static Task<Maybe<long>> Times4Sync_(long x) => Task.FromResult(Maybe.Some(4L * x));
        [Pure] private static async Task<Maybe<long>> Times4Async_(long x) { await Task.Yield(); return Maybe.Some(4L * x); }

        [Pure] private static string GetAbsoluteUri(Uri x) => x.AbsoluteUri;
        [Pure] private static Task<string> GetAbsoluteUriSync(Uri x) => Task.FromResult(x.AbsoluteUri);
        [Pure] private static async Task<string> GetAbsoluteUriAsync(Uri x) { await Task.Yield(); return x.AbsoluteUri; }

        [Pure] private static Maybe<string> GetAbsoluteUri_(Uri x) => Maybe.SomeOrNone(x.AbsoluteUri);
        [Pure] private static Task<Maybe<string>> GetAbsoluteUriSync_(Uri x) => Task.FromResult(Maybe.SomeOrNone(x.AbsoluteUri));
        [Pure] private static async Task<Maybe<string>> GetAbsoluteUriAsync_(Uri x) { await Task.Yield(); return Maybe.SomeOrNone(x.AbsoluteUri); }

        [Pure] private static Maybe<AnyResult> ReturnNone<T>(T _) => AnyResult.None;
        [Pure] private static Task<Maybe<AnyResult>> ReturnNoneSync<T>(T _) => Task.FromResult(AnyResult.None);
        [Pure] private static async Task<Maybe<AnyResult>> ReturnNoneAsync<T>(T _) { await Task.Yield(); return AnyResult.None; }

        [Pure] private static Maybe<AnyResult> ReturnSome<T>(T _) => AnyResult.Some;
        [Pure] private static Task<Maybe<AnyResult>> ReturnSomeSync<T>(T _) => Task.FromResult(AnyResult.Some);
        [Pure] private static async Task<Maybe<AnyResult>> ReturnSomeAsync<T>(T _) { await Task.Yield(); return AnyResult.Some; }
    }

    // Factories.
    public partial class MaybeTests
    {
        #region None & None<T>()

        [Fact]
        public static void None_IsDefault_ForValueT()
        {
            Assert.Equal(default, Maybe<Unit>.None);
            Assert.Equal(default, Maybe<int>.None);
            Assert.Equal(default, Maybe<long>.None);
        }

        [Fact]
        public static void None_IsDefault_ForValueT_NullableT()
        {
            Assert.Equal(default, Maybe<Unit?>.None);
            Assert.Equal(default, Maybe<int?>.None);
            Assert.Equal(default, Maybe<long?>.None);
        }

        [Fact]
        public static void None_IsDefault_ForReferenceT()
        {
            Assert.Equal(default, Maybe<string>.None);
            Assert.Equal(default, Maybe<Uri>.None);
            Assert.Equal(default, Maybe<AnyT>.None);
            Assert.Equal(default, Maybe<object>.None);
        }

        [Fact]
        public static void None_IsDefault_ForReferenceT_NullableT()
        {
            Assert.Equal(default, Maybe<string?>.None);
            Assert.Equal(default, Maybe<Uri?>.None);
            Assert.Equal(default, Maybe<AnyT?>.None);
            Assert.Equal(default, Maybe<object?>.None);
        }

        [Fact]
        public static void None_IsNone_ForValueT()
        {
            Assert.None(Maybe<Unit>.None);
            Assert.None(Maybe<int>.None);
            Assert.None(Maybe<long>.None);
        }

        [Fact]
        public static void None_IsNone_ForValueT_NullableT()
        {
            Assert.None(Maybe<Unit?>.None);
            Assert.None(Maybe<int?>.None);
            Assert.None(Maybe<long?>.None);
        }

        [Fact]
        public static void None_IsNone_ForReferenceT()
        {
            Assert.None(Maybe<string>.None);
            Assert.None(Maybe<Uri>.None);
            Assert.None(Maybe<AnyT>.None);
            Assert.None(Maybe<object>.None);
        }

        [Fact]
        public static void None_IsNone_ForReferenceT_NullableT()
        {
            Assert.None(Maybe<string?>.None);
            Assert.None(Maybe<Uri?>.None);
            Assert.None(Maybe<AnyT?>.None);
            Assert.None(Maybe<object?>.None);
        }

        [Fact]
        public static void NoneT_IsNone_ForValueT()
        {
            Assert.None(Maybe.None<Unit>());
            Assert.None(Maybe.None<int>());
            Assert.None(Maybe.None<long>());
        }

        [Fact]
        public static void NoneT_IsNone_ForReferenceT()
        {
            Assert.None(Maybe.None<string>());
            Assert.None(Maybe.None<Uri>());
            Assert.None(Maybe.None<AnyT>());
            Assert.None(Maybe.None<object>());
        }

        [Fact]
        public static void NoneT_ReturnsNone_ForValueT()
        {
            Assert.Equal(Maybe<Unit>.None, Maybe.None<Unit>());
            Assert.Equal(Maybe<int>.None, Maybe.None<int>());
            Assert.Equal(Maybe<long>.None, Maybe.None<long>());
        }

        [Fact]
        public static void NoneT_ReturnsNone_ForReferenceT()
        {
            Assert.Equal(Maybe<string>.None, Maybe.None<string>());
            Assert.Equal(Maybe<Uri>.None, Maybe.None<Uri>());
            Assert.Equal(Maybe<AnyT>.None, Maybe.None<AnyT>());
            Assert.Equal(Maybe<object>.None, Maybe.None<object>());
        }

        #endregion

        #region Of(), Some() & SomeOrNone()

        [Fact]
        public static void Of_WithValueT()
        {
            Assert.Some(UNIT, Maybe.Of(UNIT));
            Assert.Some(314, Maybe.Of(314));
            Assert.Some(413L, Maybe.Of(413L));
        }

        [Fact]
        public static void Of_WithValueT_NullableT()
        {
            Assert.None(Maybe.Of((Unit?)null));
            Assert.Some(UNIT, Maybe.Of((Unit?)UNIT));

            Assert.None(Maybe.Of((int?)null));
            Assert.Some(314, Maybe.Of((int?)314));

            Assert.None(Maybe.Of((long?)null));
            Assert.Some(413L, Maybe.Of((long?)413L));
        }

        [Fact]
        public static void Of_WithReferenceT()
        {
            Assert.Some(MyText, Maybe.Of(MyText));
            Assert.Some(MyUri, Maybe.Of(MyUri));

            var anyT = AnyT.Value;
            Assert.Some(anyT, Maybe.Of(anyT));

            var obj = new object();
            Assert.Some(obj, Maybe.Of(obj));
        }

        [Fact]
        public static void Of_WithReferenceT_NullableT()
        {
            Assert.None(Maybe.Of((string?)null));
            Assert.Some(MyText, Maybe.Of((string?)MyText));

            Assert.None(Maybe.Of((Uri?)null));
            Assert.Some(MyUri, Maybe.Of((Uri?)MyUri));

            var anyT = AnyT.Value;
            Assert.None(Maybe.Of((AnyT?)null));
            Assert.Some(anyT, Maybe.Of((AnyT?)anyT));

            var obj = new object();
            Assert.None(Maybe.Of((object?)null));
            Assert.Some(obj, Maybe.Of((object?)obj));
        }

        [Fact]
        public static void Some()
        {
            Assert.Some(UNIT, Maybe.Some(UNIT));
            Assert.Some(314, Maybe.Some(314));
            Assert.Some(413L, Maybe.Some(413L));
        }

        [Fact]
        public static void SomeOrNone_WithValueT()
        {
            Assert.None(Maybe.SomeOrNone((Unit?)null));
            Assert.Some(UNIT, Maybe.SomeOrNone((Unit?)UNIT));

            Assert.None(Maybe.SomeOrNone((int?)null));
            Assert.Some(314, Maybe.SomeOrNone((int?)314));

            Assert.None(Maybe.SomeOrNone((long?)null));
            Assert.Some(413, Maybe.SomeOrNone((long?)413));
        }

        [Fact]
        public static void SomeOrNone_WithReferenceT()
        {
            Assert.None(Maybe.SomeOrNone((string?)null));
            Assert.Some(MyText, Maybe.SomeOrNone(MyText));

            Assert.None(Maybe.SomeOrNone((Uri?)null));
            Assert.Some(MyUri, Maybe.SomeOrNone(MyUri));

            var anyT = AnyT.Value;
            Assert.None(Maybe.SomeOrNone((AnyT?)null));
            Assert.Some(anyT, Maybe.SomeOrNone(anyT));

            var obj = new object();
            Assert.None(Maybe.SomeOrNone((object?)null));
            Assert.Some(obj, Maybe.SomeOrNone(obj));
        }

        #endregion

        #region Square() & SquareOrNone()

        [Fact]
        public static void Square()
        {
            Assert.Some(Maybe.Some(UNIT), Maybe.Square(UNIT));
            Assert.Some(Maybe.Some(314), Maybe.Square(314));
            Assert.Some(Maybe.Some(314L), Maybe.Square(314L));
        }

        [Fact]
        public static void Square_IsSomeOfSome()
        {
            Assert.Equal(__(UNIT), Maybe.Square(UNIT));
            Assert.Equal(__(314), Maybe.Square(314));
            Assert.Equal(__(413L), Maybe.Square(413L));

            static Maybe<Maybe<T>> __<T>(T x) where T : struct => Maybe.Some(Maybe.Some(x));
        }

        [Fact]
        public static void SquareOrNone_WithValueT()
        {
            Assert.None(Maybe.SquareOrNone((Unit?)null));
            Assert.Some(Maybe.Some(UNIT), Maybe.SquareOrNone((Unit?)UNIT));

            Assert.None(Maybe.SquareOrNone((int?)null));
            Assert.Some(Maybe.Some(314), Maybe.SquareOrNone((int?)314));

            Assert.None(Maybe.SquareOrNone((long?)null));
            Assert.Some(Maybe.Some(413L), Maybe.SquareOrNone((long?)413));
        }

        [Fact]
        public static void SquareOrNone_WithValueT_IsNotSomeOfSomeOrNone_WhenNone()
        {
            Assert.NotEqual(__<Unit>(), Maybe.SquareOrNone((Unit?)null));
            Assert.NotEqual(__<int>(), Maybe.SquareOrNone((int?)null));
            Assert.NotEqual(__<long>(), Maybe.SquareOrNone((long?)null));

            static Maybe<Maybe<T>> __<T>() where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)null));
        }

        [Fact]
        public static void SquareOrNone_WithValueT_IsSomeOfSomeOrNone_WhenSome()
        {
            Assert.Equal(__(UNIT), Maybe.SquareOrNone((Unit?)UNIT));
            Assert.Equal(__(314), Maybe.SquareOrNone((int?)314));
            Assert.Equal(__(413L), Maybe.SquareOrNone((long?)413));

            static Maybe<Maybe<T>> __<T>(T x) where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)x));
        }

        [Fact]
        public static void SquareOrNone_WithReferenceT()
        {
            Assert.None(Maybe.SquareOrNone((string?)null));
            Assert.Some(Maybe.SomeOrNone(MyText), Maybe.SquareOrNone(MyText));

            Assert.None(Maybe.SquareOrNone((Uri?)null));
            Assert.Some(Maybe.SomeOrNone(MyUri), Maybe.SquareOrNone(MyUri));

            var anyT = AnyT.Value;
            Assert.None(Maybe.SquareOrNone((AnyT?)null));
            Assert.Some(Maybe.SomeOrNone(anyT), Maybe.SquareOrNone(anyT));

            var obj = new object();
            Assert.None(Maybe.SquareOrNone((object?)null));
            Assert.Some(Maybe.SomeOrNone(obj), Maybe.SquareOrNone(obj));
        }

        [Fact]
        public static void SquareOrNone_WithReferenceT_IsNotSomeOfSomeOrNone_WhenNone()
        {
            Assert.NotEqual(__<string>(), Maybe.SquareOrNone((string?)null));
            Assert.NotEqual(__<Uri>(), Maybe.SquareOrNone((Uri?)null));
            Assert.NotEqual(__<AnyT>(), Maybe.SquareOrNone((AnyT?)null));
            Assert.NotEqual(__<object>(), Maybe.SquareOrNone((object?)null));

            static Maybe<Maybe<T>> __<T>() where T : class => Maybe.Some(Maybe.SomeOrNone((T?)null));
        }

        [Fact]
        public static void SquareOrNone_WithReferenceT_IsSomeOfSomeOrNone_WhenSome()
        {
            Assert.Equal(__(MyText), Maybe.SquareOrNone(MyText));
            Assert.Equal(__(MyUri), Maybe.SquareOrNone(MyUri));

            var anyT = AnyT.Value;
            Assert.Equal(__(anyT), Maybe.SquareOrNone(anyT));

            var obj = new object();
            Assert.Equal(__(obj), Maybe.SquareOrNone(obj));

            static Maybe<Maybe<T>> __<T>(T x) where T : class => Maybe.Some(Maybe.SomeOrNone(x));
        }

        #endregion
    }

    // Simple conversions.
    public partial class MaybeTests
    {
        #region ToString()

        [Fact]
        public static void ToString_OnNone_ForValueT()
        {
            Assert.Equal("Maybe(None)", Maybe<Unit>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<int>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<long>.None.ToString());
        }

        [Fact]
        public static void ToString_OnNone_ForValueT_ForNullableT()
        {
            Assert.Equal("Maybe(None)", Maybe<Unit?>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<int?>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<long?>.None.ToString());
        }

        [Fact]
        public static void ToString_OnNone_ForReferenceT()
        {
            Assert.Equal("Maybe(None)", Maybe<string>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<Uri>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<AnyT>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<object>.None.ToString());
        }

        [Fact]
        public static void ToString_OnNone_ForReferenceT_ForNullableT()
        {
            Assert.Equal("Maybe(None)", Maybe<string?>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<Uri?>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<AnyT?>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<object?>.None.ToString());
        }

        [Fact]
        public static void ToString_OnSome()
        {
            // Arrange
            string text = "My Text";
            var some = Maybe.SomeOrNone(text);
            // Act & Assert
            Assert.Contains(text, some.ToString(), StringComparison.Ordinal);
        }

        [Fact]
        public static void ToString_OnSome_ForNullableT()
        {
            // Arrange
            string text = "My Text";
            var some = Maybe.Of((string?)text);
            // Act & Assert
            Assert.Contains(text, some.ToString(), StringComparison.Ordinal);
        }

        #endregion

        #region op_Explicit

        // NB: explicit cast to object or object? is meaningless.

        [Fact]
        public static void Explicit_OnNone_ForValueT()
        {
            Assert.Throws<InvalidCastException>(() => (Unit)Maybe<Unit>.None);
            Assert.Throws<InvalidCastException>(() => (int)Maybe<int>.None);
            Assert.Throws<InvalidCastException>(() => (long)Maybe<long>.None);
        }

        [Fact]
        public static void Explicit_OnNone_ForValueT_ForNullableT()
        {
            Assert.Throws<InvalidCastException>(() => (Unit?)Maybe<Unit?>.None);
            Assert.Throws<InvalidCastException>(() => (int?)Maybe<int?>.None);
            Assert.Throws<InvalidCastException>(() => (long?)Maybe<long?>.None);
        }

        [Fact]
        public static void Explicit_OnNone_ForReferenceT()
        {
            Assert.Throws<InvalidCastException>(() => (string)Maybe<string>.None);
            Assert.Throws<InvalidCastException>(() => (Uri)Maybe<Uri>.None);
            Assert.Throws<InvalidCastException>(() => (AnyT)Maybe<AnyT>.None);
        }

        [Fact]
        public static void Explicit_OnNone_ForReferenceT_ForNullableT()
        {
            Assert.Throws<InvalidCastException>(() => (string?)Maybe<string?>.None);
            Assert.Throws<InvalidCastException>(() => (Uri?)Maybe<Uri?>.None);
            Assert.Throws<InvalidCastException>(() => (AnyT?)Maybe<AnyT?>.None);
        }

        [Fact]
        public static void Explicit_OnSome_ForValueT()
        {
            Assert.Equal(UNIT, (Unit)Maybe.Some(UNIT));
            Assert.Equal(314, (int)Maybe.Some(314));
            Assert.Equal(413L, (long)Maybe.Some(413L));
        }

        [Fact]
        public static void Explicit_OnSome_ForValueT_ForNullableT()
        {
            Assert.Equal(UNIT, (Unit?)Maybe.Of((Unit?)UNIT));
            Assert.Equal(314, (int?)Maybe.Of((int?)314));
            Assert.Equal(413L, (long?)Maybe.Of((long?)413L));
        }

        [Fact]
        public static void Explicit_OnSome_ForReferenceT()
        {
            Assert.Equal(MyText, (string)Maybe.SomeOrNone(MyText));
            Assert.Equal(MyUri, (Uri)Maybe.SomeOrNone(MyUri));

            var anyT = AnyT.Value;
            Assert.Equal(anyT, (AnyT)Maybe.SomeOrNone(anyT));
        }

        [Fact]
        public static void Explicit_OnSome_ForReferenceT_ForNullableT()
        {
            Assert.Equal(MyText, (string?)Maybe.Of((string?)MyText));
            Assert.Equal(MyUri, (Uri?)Maybe.Of((Uri?)MyUri));

            var anyT = AnyT.Value;
            Assert.Equal(anyT, (AnyT?)Maybe.Of((AnyT?)anyT));
        }

        //
        // Implicit and explicit numeric conversions.
        // See https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/numeric-conversions
        //

        [Fact]
        public static void Explicit_OnSome_ImplicitNumericConversion()
        {
            // short -> int
            Assert.Equal(314, (int)Maybe.Some((short)314));
            Assert.Equal(Int16.MaxValue, (int)Maybe.Some(Int16.MaxValue));

            // int -> long
            Assert.Equal(314, (long)Maybe.Some(314));
            Assert.Equal(Int32.MaxValue, (long)Maybe.Some(Int32.MaxValue));
        }

        [Fact]
        public static void Explicit_OnSome_ExplicitNumericConversion()
        {
            // int -> short
            Assert.Equal(413, (short)Maybe.Some(413));
            Assert.Equal(Int16.MaxValue, (short)Maybe.Some((int)Int16.MaxValue));

            // long -> int
            Assert.Equal(413, (int)Maybe.Some(413L));
            Assert.Equal(Int32.MaxValue, (int)Maybe.Some((long)Int32.MaxValue));
        }

        [Fact]
        public static void Explicit_OnSome_ExplicitNumericConversion_Overflows()
        {
            Assert.Throws<OverflowException>(() => (short)Maybe.Some(Int32.MaxValue));
            Assert.Throws<OverflowException>(() => (int)Maybe.Some(Int64.MaxValue));
        }

        //
        // Upcasting & downcasting.
        //

        [Fact]
        public static void Explicit_OnSome_Downcasting_WhenNotUpcasted()
        {
            // Arrange
            var obj = new MyBaseClass_ { };
            var m = Maybe.SomeOrNone(obj);
            // Act & Assert
            Assert.Throws<InvalidCastException>(() => (MyDerivedClass_)m);
        }

        [Fact]
        public static void Explicit_OnSome_Downcasting_WhenUpcasted()
        {
            // Arrange
            MyBaseClass_ obj = new MyDerivedClass_ { };    // upcast
            var m = Maybe.SomeOrNone(obj);
            // Act & Assert
            Assert.Equal(obj, (MyDerivedClass_)m);
        }

        [Fact]
        public static void Explicit_OnSome_Upcasting()
        {
            // Arrange
            var obj = new MyDerivedClass_ { };
            var m = Maybe.SomeOrNone(obj);
            // Act & Assert
            Assert.Equal(obj, (MyBaseClass_)m);
        }

        private class MyBaseClass_ { }

        private class MyDerivedClass_ : MyBaseClass_ { }

        #endregion
    }

    // Binding.
    public partial class MaybeTests
    {
        [Fact]
        public static void Bind_OnNone_WithNullBinder()
        {
            Assert.ThrowsAnexn("binder", () => Ø.Bind(Kunc<int, AnyResult>.Null));
            Assert.ThrowsAnexn("binder", () => AnyT.None.Bind(Kunc<AnyT, AnyResult>.Null));
        }

        [Fact]
        public static void Bind_OnSome_WithNullBinder()
        {
            Assert.ThrowsAnexn("binder", () => One.Bind(Kunc<int, AnyResult>.Null));
            Assert.ThrowsAnexn("binder", () => AnyT.Some.Bind(Kunc<AnyT, AnyResult>.Null));
        }

        [Fact]
        public static void Bind_OnNone()
        {
            Assert.None(Ø.Bind(ReturnSome));
            Assert.None(NoText.Bind(ReturnSome));
            Assert.None(NoUri.Bind(ReturnSome));
            Assert.None(AnyT.None.Bind(ReturnSome));
        }

        [Fact]
        public static void Bind_OnSome_ReturnsNone()
        {
            Assert.None(One.Bind(ReturnNone));
            Assert.None(SomeText.Bind(ReturnNone));
            Assert.None(SomeUri.Bind(ReturnNone));
            Assert.None(AnyT.Some.Bind(ReturnNone));
        }

        [Fact]
        public static void Bind_OnSome_ReturnsSome()
        {
            Assert.Some(AnyResult.Value, One.Bind(ReturnSome));
            Assert.Some(AnyResult.Value, SomeText.Bind(ReturnSome));
            Assert.Some(AnyResult.Value, SomeUri.Bind(ReturnSome));
            Assert.Some(AnyResult.Value, AnyT.Some.Bind(ReturnSome));
        }

        [Fact]
        public static void Bind_OnSomeInt32() =>
            Assert.Some(6, Two.Bind(Times3_));

        [Fact]
        public static void Bind_OnSomeInt64() =>
            Assert.Some(8L, TwoL.Bind(Times4_));

        [Fact]
        public static void Bind_OnSomeUri() =>
            Assert.Some(MyUri.AbsoluteUri, SomeUri.Bind(GetAbsoluteUri_));
    }

    // Safe escapes.
    public partial class MaybeTests
    {
        #region Switch()

        [Fact]
        public static void Switch_OnNone_WithNullCaseNone_Throws()
        {
            Assert.ThrowsAnexn("caseNone", () => Ø.Switch(Funk<int, AnyResult>.Any, Funk<AnyResult>.Null));
            Assert.ThrowsAnexn("caseNone", () => AnyT.None.Switch(Funk<AnyT, AnyResult>.Any, Funk<AnyResult>.Null));
        }

        [Fact]
        public static void Switch_OnNone_WithNullCaseSome_DoesNotThrow()
        {
            // Act
            AnyResult v = Ø.Switch(Funk<int, AnyResult>.Null, () => AnyResult.Value);
            // Assert
            Assert.Same(AnyResult.Value, v);
        }

        [Fact]
        public static void Switch_OnSome_WithNullCaseSome_Throws()
        {
            Assert.ThrowsAnexn("caseSome", () => One.Switch(Funk<int, AnyResult>.Null, Funk<AnyResult>.Any));
            Assert.ThrowsAnexn("caseSome", () => AnyT.Some.Switch(Funk<AnyT, AnyResult>.Null, Funk<AnyResult>.Any));

            Assert.ThrowsAnexn("caseSome", () => One.Switch(Funk<int, AnyResult>.Null, AnyResult.Value));
            Assert.ThrowsAnexn("caseSome", () => AnyT.Some.Switch(Funk<AnyT, AnyResult>.Null, AnyResult.Value));
        }

        [Fact]
        public static void Switch_OnSome_WithNullCaseNone_DoesNotThrow()
        {
            // Act
            AnyResult v = One.Switch(
                caseSome: x => AnyResult.Value,
                caseNone: Funk<AnyResult>.Null);
            // Assert
            Assert.Same(AnyResult.Value, v);
        }

        [Fact]
        public static void Switch_OnNone()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;
            // Act
            int v = NoText.Switch(
                caseSome: x => { onSomeCalled = true; return x.Length; },
                caseNone: () => { onNoneCalled = true; return 0; });
            // Assert
            Assert.False(onSomeCalled);
            Assert.True(onNoneCalled);
            Assert.Equal(0, v);
        }

        [Fact]
        public static void Switch_OnNone_WithConstCaseNone()
        {
            // Arrange
            bool onSomeCalled = false;
            // Act
            int v = NoText.Switch(
                caseSome: x => { onSomeCalled = true; return x.Length; },
                caseNone: 0);
            // Assert
            Assert.False(onSomeCalled);
            Assert.Equal(0, v);
        }

        [Fact]
        public static void Switch_OnSome()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;
            // Act
            int v = SomeText.Switch(
                caseSome: x => { onSomeCalled = true; return x.Length; },
                caseNone: () => { onNoneCalled = true; return 0; });
            // Assert
            Assert.True(onSomeCalled);
            Assert.False(onNoneCalled);
            Assert.Equal(4, v);
        }

        [Fact]
        public static void Switch_OnSome_WithConstCaseNone()
        {
            // Arrange
            bool onSomeCalled = false;
            // Act
            int v = SomeText.Switch(
                caseSome: x => { onSomeCalled = true; return x.Length; },
                caseNone: 0);
            // Assert
            Assert.True(onSomeCalled);
            Assert.Equal(4, v);
        }

        #endregion

        #region TryGetValue()

        [Fact]
        public static void TryGetValue_OnNone()
        {
            Assert.False(Ø.TryGetValue(out int _));
            Assert.False(NoText.TryGetValue(out string _));
            Assert.False(NoUri.TryGetValue(out Uri _));
            Assert.False(AnyT.None.TryGetValue(out AnyT _));
        }

        [Fact]
        public static void TryGetValue_OnSome()
        {
            Assert.True(One.TryGetValue(out int one));
            Assert.Equal(1, one);

            Assert.True(SomeText.TryGetValue(out string? text));
            Assert.Equal(MyText, text);

            Assert.True(SomeUri.TryGetValue(out Uri? uri));
            Assert.Equal(MyUri, uri);

            var anyT = AnyT.New();
            Assert.True(anyT.Some.TryGetValue(out AnyT? value));
            Assert.Equal(anyT.Value, value);
        }

        #endregion

        #region ValueOrDefault()

        [Fact]
        public static void ValueOrDefault_OnNone()
        {
            Assert.Equal(0, Ø.ValueOrDefault());
            Assert.Null(NoText.ValueOrDefault());
            Assert.Null(NoUri.ValueOrDefault());
            Assert.Null(AnyT.None.ValueOrDefault());
        }

        [Fact]
        public static void ValueOrDefault_OnSome()
        {
            Assert.Equal(1, One.ValueOrDefault());
            Assert.Equal(MyText, SomeText.ValueOrDefault());
            Assert.Equal(MyUri, SomeUri.ValueOrDefault());

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrDefault());
        }

        #endregion

        #region ValueOrElse()

        [Fact]
        public static void ValueOrElse_OnNone_WithNullFactory_Throws()
        {
            Assert.ThrowsAnexn("valueFactory", () => Ø.ValueOrElse(Funk<int>.Null));
            Assert.ThrowsAnexn("valueFactory", () => AnyT.None.ValueOrElse(Funk<AnyT>.Null));
        }

        [Fact]
        public static void ValueOrElse_OnSome_WithNullFactory_DoesNotThrow()
        {
            Assert.Equal(1, One.ValueOrElse(Funk<int>.Null));
            Assert.Equal(MyText, SomeText.ValueOrElse(Funk<string>.Null));
            Assert.Equal(MyUri, SomeUri.ValueOrElse(Funk<Uri>.Null));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrElse(Funk<AnyT>.Null));
        }

        [Fact]
        public static void ValueOrElse_OnNone()
        {
            Assert.Equal(3, Ø.ValueOrElse(3));
            Assert.Equal("other", NoText.ValueOrElse("other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(otherUri, NoUri.ValueOrElse(otherUri));

            var otherAnyT = AnyT.Value;
            Assert.Equal(otherAnyT, AnyT.None.ValueOrElse(otherAnyT));
        }

        [Fact]
        public static void ValueOrElse_OnNone_WithFactory()
        {
            Assert.Equal(3, Ø.ValueOrElse(() => 3));
            Assert.Equal("other", NoText.ValueOrElse(() => "other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(otherUri, NoUri.ValueOrElse(() => otherUri));

            var otherAnyT = AnyT.Value;
            Assert.Equal(otherAnyT, AnyT.None.ValueOrElse(() => otherAnyT));
        }

        [Fact]
        public static void ValueOrElse_OnSome()
        {
            Assert.Equal(1, One.ValueOrElse(3));
            Assert.Equal(MyText, SomeText.ValueOrElse("other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(MyUri, SomeUri.ValueOrElse(otherUri));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrElse(AnyT.Value));
        }

        [Fact]
        public static void ValueOrElse_OnSome_WithFactory()
        {
            Assert.Equal(1, One.ValueOrElse(() => 3));
            Assert.Equal(MyText, SomeText.ValueOrElse(() => "other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(MyUri, SomeUri.ValueOrElse(() => otherUri));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrElse(() => AnyT.Value));
        }

        #endregion

        #region ValueOrThrow()

        [Fact]
        public static void ValueOrThrow_WithNullException()
        {
            Assert.ThrowsAnexn("exception", () => Ø.ValueOrThrow(null!));
            Assert.ThrowsAnexn("exception", () => AnyT.None.ValueOrThrow(null!));
        }

        [Fact]
        public static void ValueOrThrow_OnNone()
        {
            Assert.Throws<InvalidOperationException>(() => Ø.ValueOrThrow());
            Assert.Throws<InvalidOperationException>(() => NoText.ValueOrThrow());
            Assert.Throws<InvalidOperationException>(() => NoUri.ValueOrThrow());
            Assert.Throws<InvalidOperationException>(() => AnyT.None.ValueOrThrow());
        }

        [Fact]
        public static void ValueOrThrow_OnNone_WithCustomException()
        {
            Assert.Throws<NotSupportedException>(() => Ø.ValueOrThrow(new NotSupportedException()));
            Assert.Throws<NotSupportedException>(() => NoText.ValueOrThrow(new NotSupportedException()));
            Assert.Throws<NotSupportedException>(() => NoUri.ValueOrThrow(new NotSupportedException()));
            Assert.Throws<NotSupportedException>(() => AnyT.None.ValueOrThrow(new NotSupportedException()));
        }

        [Fact]
        public static void ValueOrThrow_OnSome()
        {
            Assert.Equal(1, One.ValueOrThrow());
            Assert.Equal(MyText, SomeText.ValueOrThrow());
            Assert.Equal(MyUri, SomeUri.ValueOrThrow());

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrThrow());
        }

        [Fact]
        public static void ValueOrThrow_OnSome_WithCustomException()
        {
            Assert.Equal(1, One.ValueOrThrow(new NotSupportedException()));
            Assert.Equal(MyText, SomeText.ValueOrThrow(new NotSupportedException()));
            Assert.Equal(MyUri, SomeUri.ValueOrThrow(new NotSupportedException()));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrThrow(new NotSupportedException()));
        }

        #endregion
    }

    // Side effects.
    public partial class MaybeTests
    {
        #region Do()

        [Fact]
        public static void Do_OnNone_WithNullOnNone_Throws()
        {
            Assert.ThrowsAnexn("onNone", () => Ø.Do(Act<int>.Noop, Act.Null));
            Assert.ThrowsAnexn("onNone", () => AnyT.None.Do(Act<AnyT>.Noop, Act.Null));
        }

        [Fact]
        public static void Do_OnNone_WithNullOnSome_DoesNotThrow()
        {
            // Act
            var ex = Record.Exception(() => Ø.Do(Act<int>.Null, Act.Noop));
            // Assert
            Assert.Null(ex);
        }

        [Fact]
        public static void Do_OnSome_WithNullOnSome_Throws()
        {
            Assert.ThrowsAnexn("onSome", () => One.Do(Act<int>.Null, Act.Noop));
            Assert.ThrowsAnexn("onSome", () => AnyT.Some.Do(Act<AnyT>.Null, Act.Noop));
        }

        [Fact]
        public static void Do_OnSome_WithNullOnNone_DoesNotThrow()
        {
            // Act
            var ex = Record.Exception(() => One.Do(Act<int>.Noop, Act.Null));
            // Assert
            Assert.Null(ex);
        }

        [Fact]
        public static void Do_OnNone()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;
            // Act
            NoText.Do(_ => { onSomeCalled = true; }, () => { onNoneCalled = true; });
            // Assert
            Assert.False(onSomeCalled);
            Assert.True(onNoneCalled);
        }

        [Fact]
        public static void Do_OnSome()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;
            // Act
            SomeText.Do(_ => { onSomeCalled = true; }, () => { onNoneCalled = true; });
            // Assert
            Assert.True(onSomeCalled);
            Assert.False(onNoneCalled);
        }

        #endregion

        #region OnSome()

        [Fact]
        public static void OnSome_OnNone_WithNullAction_DoesNotThrow()
        {
            // Act
            var ex = Record.Exception(() => Ø.OnSome(Act<int>.Null));
            // Assert
            Assert.Null(ex);
        }

        [Fact]
        public static void OnSome_OnSome_WithNullAction_Throws()
        {
            Assert.ThrowsAnexn("action", () => One.OnSome(Act<int>.Null));
            Assert.ThrowsAnexn("action", () => AnyT.Some.OnSome(Act<AnyT>.Null));
        }

        [Fact]
        public static void OnSome_OnNone()
        {
            // Arrange
            bool wasCalled = false;
            // Act
            NoText.OnSome(_ => { wasCalled = true; });
            // Assert
            Assert.False(wasCalled);
        }

        [Fact]
        public static void OnSome_OnSome()
        {
            // Arrange
            bool wasCalled = false;
            // Act
            SomeText.OnSome(_ => { wasCalled = true; });
            // Assert
            Assert.True(wasCalled);
        }

        #endregion

        #region When()

        [Fact]
        public static void When_OnNone_WithFalse()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;
            // Act
            NoText.When(false, _ => { onSomeCalled = true; }, () => { onNoneCalled = true; });
            NoText.When(false, null, () => { onNoneCalled = true; });
            NoText.When(false, _ => { onSomeCalled = true; }, null);
            NoText.When(false, null, null);
            // Assert
            Assert.False(onSomeCalled);
            Assert.False(onNoneCalled);
        }

        [Fact]
        public static void When_OnSome_WithFalse()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;
            // Act
            SomeText.When(false, _ => { onSomeCalled = true; }, () => { onNoneCalled = true; });
            SomeText.When(false, null, () => { onNoneCalled = true; });
            SomeText.When(false, _ => { onSomeCalled = true; }, null);
            SomeText.When(false, null, null);
            // Assert
            Assert.False(onSomeCalled);
            Assert.False(onNoneCalled);
        }

        [Fact]
        public static void When_OnNone_WithTrue()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;

            // Act & Assert
            NoText.When(true, _ => { onSomeCalled = true; }, () => { onNoneCalled = true; });
            Assert.False(onSomeCalled);
            Assert.True(onNoneCalled);

            onSomeCalled = false;
            NoText.When(true, _ => { onSomeCalled = true; }, null);
            Assert.False(onSomeCalled);

            onNoneCalled = false;
            NoText.When(true, null, () => { onNoneCalled = true; });
            Assert.True(onNoneCalled);

            // Does not throw.
            var ex = Record.Exception(() => NoText.When(true, null, null));
            Assert.Null(ex);
        }

        [Fact]
        public static void When_OnSome_WithTrue()
        {
            // Arrange
            bool onSomeCalled = false;
            bool onNoneCalled = false;

            // Act & Assert
            SomeText.When(true, _ => { onSomeCalled = true; }, () => { onNoneCalled = true; });
            Assert.True(onSomeCalled);
            Assert.False(onNoneCalled);

            onSomeCalled = false;
            SomeText.When(true, _ => { onSomeCalled = true; }, null);
            Assert.True(onSomeCalled);

            onNoneCalled = false;
            SomeText.When(true, null, () => { onNoneCalled = true; });
            Assert.False(onNoneCalled);

            // Does not throw.
            var ex = Record.Exception(() => SomeText.When(true, null, null));
            Assert.Null(ex);
        }

        #endregion
    }

    // Iterable.
    public partial class MaybeTests
    {
        #region ToEnumerable()

        [Fact]
        public static void ToEnumerable()
        {
            Assert.Equal(Enumerable.Repeat(MyText, 1), SomeText.ToEnumerable());
            Assert.Empty(NoText.ToEnumerable());
        }

        #endregion

        #region GetEnumerator()

        [Fact]
        public static void GetEnumerator_OnNone_ForEach()
        {
            foreach (string _ in NoText)
            {
                Assert.Fails("An empty maybe should create an empty iterator.");
            }
        }

        [Fact]
        public static void GetEnumerator_OnNone_ExplicitIterator()
        {
            var iter = NoText.GetEnumerator();

            Assert.False(iter.MoveNext());
            iter.Reset();
            Assert.False(iter.MoveNext());
        }

        [Fact]
        public static void GetEnumerator_OnSome_ForEach()
        {
            // Arrange
            int count = 0;

            // Act & Assert
            // First loop.
            foreach (string x in SomeText) { count++; Assert.Equal(MyText, x); }
            Assert.Equal(1, count);
            // Second loop (new iterator).
            count = 0;
            foreach (string x in SomeText) { count++; Assert.Equal(MyText, x); }
            Assert.Equal(1, count);
        }

        [Fact]
        public static void GetEnumerator_OnSome_ExplicitIterator()
        {
            var iter = SomeText.GetEnumerator();

            Assert.True(iter.MoveNext());
            Assert.Same(MyText, iter.Current);
            Assert.False(iter.MoveNext());

            iter.Reset();

            Assert.True(iter.MoveNext());
            Assert.Same(MyText, iter.Current);
            Assert.False(iter.MoveNext());
        }

        #endregion

        #region Yield()

        [Fact]
        public static void Yield_OnNone() =>
            Assert.Empty(NoText.Yield());

        [Fact]
        public static void Yield_OnNone_WithCount()
        {
            Assert.Empty(NoText.Yield(0));
            Assert.Empty(NoText.Yield(10));
            Assert.Empty(NoText.Yield(100));
            Assert.Empty(NoText.Yield(1000));
        }

        [Fact]
        public static void Yield_OnSome()
        {
            Assert.Equal(Enumerable.Repeat(MyText, 0), SomeText.Yield().Take(0));
            Assert.Equal(Enumerable.Repeat(MyText, 1), SomeText.Yield().Take(1));
            Assert.Equal(Enumerable.Repeat(MyText, 10), SomeText.Yield().Take(10));
            Assert.Equal(Enumerable.Repeat(MyText, 100), SomeText.Yield().Take(100));
            Assert.Equal(Enumerable.Repeat(MyText, 1000), SomeText.Yield().Take(1000));
        }

        [Fact]
        public static void Yield_OnSome_WithCount()
        {
            Assert.Equal(Enumerable.Repeat(MyText, 0), SomeText.Yield(0));
            Assert.Equal(Enumerable.Repeat(MyText, 1), SomeText.Yield(1));
            Assert.Equal(Enumerable.Repeat(MyText, 10), SomeText.Yield(10));
            Assert.Equal(Enumerable.Repeat(MyText, 100), SomeText.Yield(100));
            Assert.Equal(Enumerable.Repeat(MyText, 1000), SomeText.Yield(1000));
        }

        #endregion

        #region Contains()

        [Fact]
        public static void Contains_OnNone_WithNullComparer()
        {
            Assert.ThrowsAnexn("comparer", () => Ø.Contains(1, null!));
            Assert.ThrowsAnexn("comparer", () => AnyT.None.Contains(AnyT.Value, null!));
        }

        [Fact]
        public static void Contains_OnSome_WithNullComparer()
        {
            Assert.ThrowsAnexn("comparer", () => One.Contains(1, null!));
            Assert.ThrowsAnexn("comparer", () => AnyT.Some.Contains(AnyT.Value, null!));
        }

        [Fact]
        public static void Contains_OnNone_Int32()
        {
            Assert.False(Ø.Contains(0));
            Assert.False(Ø.Contains(1));
            Assert.False(Ø.Contains(2));
        }

        [Fact]
        public static void Contains_OnNone_Text()
        {
            Assert.False(NoText.Contains("XXX"));
            Assert.False(NoText.Contains("XXX", StringComparer.Ordinal));
            Assert.False(NoText.Contains("XXX", StringComparer.OrdinalIgnoreCase));
        }

        [Fact]
        public static void Contains_OnSomeInt32()
        {
            Assert.False(One.Contains(0));
            Assert.True(One.Contains(1));
            Assert.False(One.Contains(2));
        }

        [Fact]
        public static void Contains_OnSomeText()
        {
            Assert.True(Maybe.SomeOrNone("XXX").Contains("XXX"));
            // Default comparison does NOT ignore case.
            Assert.False(Maybe.SomeOrNone("XXX").Contains("xxx"));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("yyy"));
        }

        [Fact]
        public static void Contains_OnSomeText_WithComparer()
        {
            Assert.True(Maybe.SomeOrNone("XXX").Contains("XXX", StringComparer.Ordinal));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("xxx", StringComparer.Ordinal));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("yyy", StringComparer.Ordinal));

            Assert.True(Maybe.SomeOrNone("XXX").Contains("XXX", StringComparer.OrdinalIgnoreCase));
            Assert.True(Maybe.SomeOrNone("XXX").Contains("xxx", StringComparer.OrdinalIgnoreCase));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("yyy", StringComparer.OrdinalIgnoreCase));
        }

        [Fact]
        public static void Contains_OnSomeText_Anagram()
        {
            // Arrange
            var cmp = new AnagramEqualityComparer();
            // Act & Assert
            Assert.False(Maybe.SomeOrNone(Anagram).Contains(Margana));
            Assert.False(Maybe.SomeOrNone(Anagram).Contains(Margana, StringComparer.Ordinal));
            Assert.False(Maybe.SomeOrNone(Anagram).Contains(Margana, StringComparer.OrdinalIgnoreCase));

            Assert.True(Maybe.SomeOrNone(Anagram).Contains(Margana, cmp));
            Assert.True(Maybe.SomeOrNone(Margana).Contains(Anagram, cmp));
        }

        #endregion
    }

    // Serialization.
    public partial class MaybeTests
    {
        [Fact]
        public static void IsSerializable() =>
            // Not strictly necessary since the other tests will fail too if we
            // remove the Serializable attr, but this test is more explicit, it
            // only fails in that specific case.
            Assert.True(typeof(Maybe<>).IsSerializable);

        [Fact]
        public static void Serialization_OnNone_ForValueType()
        {
            // Arrange
            var formatter = new BinaryFormatter();
            Maybe<int> none;
            // Act (serialize then deserialize)
            using (var stream = new MemoryStream())
            {
                formatter.Serialize(stream, Maybe<int>.None);

                stream.Seek(0, SeekOrigin.Begin);
                none = (Maybe<int>)formatter.Deserialize(stream);
            }
            // Assert
            Assert.None(none);
        }

        [Fact]
        public static void Serialization_OnNone_ForReferenceType()
        {
            // Arrange
            var formatter = new BinaryFormatter();
            Maybe<AnySerializable> none;
            // Act (serialize then deserialize)
            using (var stream = new MemoryStream())
            {
                formatter.Serialize(stream, Maybe<AnySerializable>.None);

                stream.Seek(0, SeekOrigin.Begin);
                none = (Maybe<AnySerializable>)formatter.Deserialize(stream);
            }
            // Assert
            Assert.None(none);
        }

        [Fact]
        public static void Serialization_OnSome_ForValueType()
        {
            // Arrange
            var formatter = new BinaryFormatter();
            Maybe<int> some;
            // Act (serialize then deserialize)
            using (var stream = new MemoryStream())
            {
                formatter.Serialize(stream, Maybe.Some(314));

                stream.Seek(0, SeekOrigin.Begin);
                some = (Maybe<int>)formatter.Deserialize(stream);
            }
            // Assert
            Assert.Some(314, some);
        }

        [Fact]
        public static void Serialization_OnSome_ForReferenceType()
        {
            // Arrange
            var formatter = new BinaryFormatter();
            var any = new AnySerializable
            {
                Item1 = Int16.MaxValue,
                Item2 = Int32.MaxValue,
                Item3 = Int64.MaxValue
            };
            Maybe<AnySerializable> some;
            // Act (serialize then deserialize)
            using (var stream = new MemoryStream())
            {
                formatter.Serialize(stream, Maybe.SomeOrNone(any));

                stream.Seek(0, SeekOrigin.Begin);
                some = (Maybe<AnySerializable>)formatter.Deserialize(stream);
            }
            // Assert
            // The equality test only works because AnySerializable follows
            // structural equality rules.
            Assert.Some(any, some);
        }

        [Fact]
        public static void Serialization_OnNone_ForNotSerializable()
        {
            // Arrange
            var formatter = new BinaryFormatter();
            // Act & Assert
            using var stream = new MemoryStream();
            Assert.Throws<SerializationException>(() => formatter.Serialize(stream, Maybe<AnyT>.None));
        }

        [Fact]
        public static void Serialization_OnSome_ForNotSerializable()
        {
            // Arrange
            var some = Maybe.SomeOrNone(AnyT.Value);
            var formatter = new BinaryFormatter();
            // Act & Assert
            using var stream = new MemoryStream();
            Assert.Throws<SerializationException>(() => formatter.Serialize(stream, some));
        }
    }
}

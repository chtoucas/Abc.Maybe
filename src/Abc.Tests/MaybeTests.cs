// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Linq;
    using System.Threading.Tasks;

    using Xunit;

    using Assert = AssertEx;

    public static partial class MaybeTests
    {
        private const string NullString = null;
        private const string? NullNullString = null;

        private const string Anagram = "chicane";
        private const string Margana = "caniche";

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
        [Fact]
        public static void None_IsDefault()
        {
            Assert.Equal(default, Maybe<Unit>.None);
            Assert.Equal(default, Maybe<int>.None);
            Assert.Equal(default, Maybe<int?>.None);
            Assert.Equal(default, Maybe<string>.None);
            Assert.Equal(default, Maybe<Uri>.None);
            Assert.Equal(default, Maybe<AnyT>.None);
            Assert.Equal(default, Maybe<object>.None);
        }

        [Fact]
        public static void None_IsNone()
        {
            Assert.None(Maybe<Unit>.None);
            Assert.None(Maybe<int>.None);
            Assert.None(Maybe<int?>.None);
            Assert.None(Maybe<string>.None);
            Assert.None(Maybe<Uri>.None);
            Assert.None(Maybe<AnyT>.None);
            Assert.None(Maybe<object>.None);
        }

        [Fact]
        public static void NoneT_IsNone()
        {
            // NB: int? is not permitted here.
            Assert.None(Maybe.None<Unit>());
            Assert.None(Maybe.None<int>());
            Assert.None(Maybe.None<string>());
            Assert.None(Maybe.None<Uri>());
            Assert.None(Maybe.None<AnyT>());
            Assert.None(Maybe.None<object>());
        }

        [Fact]
        public static void NoneT_ReturnsNone()
        {
            // Maybe.None<T>() simply returns Maybe<T>.None.
            Assert.Equal(Maybe<Unit>.None, Maybe.None<Unit>());
            Assert.Equal(Maybe<int>.None, Maybe.None<int>());
            Assert.Equal(Maybe<string>.None, Maybe.None<string>());
            Assert.Equal(Maybe<Uri>.None, Maybe.None<Uri>());
            Assert.Equal(Maybe<AnyT>.None, Maybe.None<AnyT>());
            Assert.Equal(Maybe<object>.None, Maybe.None<object>());
        }

        [Fact]
        public static void Of_WithValueType()
        {
            Assert.Some(1, Maybe.Of(1));

#pragma warning disable CS0618 // Type or member is obsolete
            Assert.None(Maybe.Of((int?)null));
            Assert.Some(1, Maybe.Of((int?)1));
#pragma warning restore CS0618
        }

        [Fact]
        public static void Of_WithReferenceType()
        {
            Assert.None(Maybe.Of((string?)null));
            Assert.Some(MyText, Maybe.Of(MyText));

            Assert.None(Maybe.Of((Uri?)null));
            Assert.Some(MyUri, Maybe.Of(MyUri));

            var anyT = AnyT.Value;
            Assert.None(Maybe.Of((AnyT?)null));
            Assert.Some(anyT, Maybe.Of(anyT));
        }

        [Fact]
        public static void Some() =>
            Assert.Some(1, Maybe.Some(1));

        [Fact]
        public static void SomeOrNone_WithValueType()
        {
            Assert.None(Maybe.SomeOrNone((int?)null));
            Assert.Some(1, Maybe.SomeOrNone((int?)1));
        }

        [Fact]
        public static void SomeOrNone_WithReferenceType()
        {
            Assert.None(Maybe.SomeOrNone((string?)null));
            Assert.Some(MyText, Maybe.SomeOrNone(MyText));

            Assert.None(Maybe.SomeOrNone((Uri?)null));
            Assert.Some(MyUri, Maybe.SomeOrNone(MyUri));

            var anyT = AnyT.Value;
            Assert.None(Maybe.SomeOrNone((AnyT?)null));
            Assert.Some(anyT, Maybe.SomeOrNone(anyT));
        }

        [Fact]
        public static void Square()
        {
            Assert.Some(One, Maybe.Square(1));
            Assert.Some(Two, Maybe.Square(2));
            Assert.Some(TwoL, Maybe.Square(2L));
        }

        [Fact]
        public static void SquareOrNone_WithValueType()
        {
            Assert.None(Maybe.SquareOrNone((int?)null));
            Assert.Some(One, Maybe.SquareOrNone((int?)1));
        }

        [Fact]
        public static void SquareOrNone_WithReferenceType()
        {
            Assert.None(Maybe.SquareOrNone((string?)null));
            Assert.Some(Maybe.SomeOrNone(MyText), Maybe.SquareOrNone(MyText));

            Assert.None(Maybe.SquareOrNone((Uri?)null));
            Assert.Some(Maybe.SomeOrNone(MyUri), Maybe.SquareOrNone(MyUri));

            var anyT = AnyT.Value;
            Assert.None(Maybe.SquareOrNone((AnyT?)null));
            Assert.Some(Maybe.SomeOrNone(anyT), Maybe.SquareOrNone(anyT));
        }
    }

    // Simple conversions.
    public partial class MaybeTests
    {
        [Fact]
        public static void ToString_None()
        {
            Assert.Equal("Maybe(None)", Maybe<int>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<string>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<Uri>.None.ToString());
            Assert.Equal("Maybe(None)", Maybe<AnyT>.None.ToString());
        }

        [Fact]
        public static void ToString_Some()
        {
            // Arrange
            string text = "My Value";
            var some = Maybe.SomeOrNone(text);
            // Act & Assert
            Assert.Contains(text, some.ToString(), StringComparison.OrdinalIgnoreCase);
        }

        [Fact]
        public static void Explicit_FromMaybe_WithNone()
        {
            Assert.Throws<InvalidCastException>(() => (int)Ø);
            Assert.Throws<InvalidCastException>(() => (string)NoText);
            Assert.Throws<InvalidCastException>(() => (Uri)NoUri);
            Assert.Throws<InvalidCastException>(() => (AnyT)AnyT.None);
        }

        [Fact]
        public static void Explicit_FromMaybe_WithSome()
        {
            Assert.Equal(1, (int)One);
            Assert.Equal(MyText, (string)SomeText);
            Assert.Equal(MyUri, (Uri)SomeUri);

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, (AnyT)anyT.Some);
        }

        //[Fact]
        //public static void Implicit_ToMaybe()
        //{
        //    // Arrange
        //    Maybe<string> none = My.NullString; // implicit cast of a null-string

        //    // Act & Assert
        //    Assert.Some(1, 1);      // the second 1 is implicit casted to Maybe<int>
        //    Assert.None(none);

        //    Assert.True(1 == One);
        //    Assert.True(One == 1);
        //}
    }

    // Core methods.
    public partial class MaybeTests
    {
        #region Bind()

        [Fact]
        public static void Bind_None_NullBinder()
        {
            Assert.ThrowsAnexn("binder", () => Ø.Bind(Kunc<int, AnyResult>.Null));
            Assert.ThrowsAnexn("binder", () => AnyT.None.Bind(Kunc<AnyT, AnyResult>.Null));
        }

        [Fact]
        public static void Bind_Some_NullBinder()
        {
            Assert.ThrowsAnexn("binder", () => One.Bind(Kunc<int, AnyResult>.Null));
            Assert.ThrowsAnexn("binder", () => AnyT.Some.Bind(Kunc<AnyT, AnyResult>.Null));
        }

        [Fact]
        public static void Bind_None()
        {
            Assert.None(Ø.Bind(ReturnSome));
            Assert.None(NoText.Bind(ReturnSome));
            Assert.None(NoUri.Bind(ReturnSome));
            Assert.None(AnyT.None.Bind(ReturnSome));
        }

        [Fact]
        public static void Bind_Some_ReturnsNone()
        {
            Assert.None(One.Bind(ReturnNone));
            Assert.None(SomeText.Bind(ReturnNone));
            Assert.None(SomeUri.Bind(ReturnNone));
            Assert.None(AnyT.Some.Bind(ReturnNone));
        }

        [Fact]
        public static void Bind_Some_ReturnsSome()
        {
            Assert.Some(AnyResult.Value, One.Bind(ReturnSome));
            Assert.Some(AnyResult.Value, SomeText.Bind(ReturnSome));
            Assert.Some(AnyResult.Value, SomeUri.Bind(ReturnSome));
            Assert.Some(AnyResult.Value, AnyT.Some.Bind(ReturnSome));
        }

        [Fact]
        public static void Bind_SomeInt32() =>
            Assert.Some(6, Two.Bind(Times3_));

        [Fact]
        public static void Bind_SomeInt64() =>
            Assert.Some(8L, TwoL.Bind(Times4_));

        [Fact]
        public static void Bind_SomeUri() =>
            Assert.Some(MyUri.AbsoluteUri, SomeUri.Bind(GetAbsoluteUri_));

        #endregion

        #region Flatten()

        [Fact]
        public static void Flatten_None()
        {
            Assert.Equal(Ø, Maybe<Maybe<int>>.None.Flatten());
            Assert.Equal(Ø, Maybe<Maybe<int?>>.None.Flatten());
            Assert.Equal(NoText, Maybe<Maybe<string>>.None.Flatten());
            Assert.Equal(NoUri, Maybe<Maybe<Uri>>.None.Flatten());
            Assert.Equal(AnyT.None, Maybe<Maybe<AnyT>>.None.Flatten());
        }

        [Fact]
        public static void Flatten_SomeOfNone()
        {
            Assert.Equal(Ø, Maybe.Some(Ø).Flatten());
            Assert.Equal(NoText, Maybe.Some(NoText).Flatten());
            Assert.Equal(NoUri, Maybe.Some(NoUri).Flatten());
            Assert.Equal(AnyT.None, Maybe.Some(AnyT.None).Flatten());
        }

        [Fact]
        public static void Flatten_SomeOfSome()
        {
            Assert.Equal(One, Maybe.Some(One).Flatten());
            Assert.Equal(SomeText, Maybe.Some(SomeText).Flatten());
            Assert.Equal(SomeUri, Maybe.Some(SomeUri).Flatten());

            var some = AnyT.Some;
            Assert.Equal(some, Maybe.Some(some).Flatten());

            Maybe<int?> one = One.Select(x => (int?)x);
            Assert.Equal(One, Maybe.Some(one).Flatten());
        }

        #endregion
    }

    // Safe escapes.
    public partial class MaybeTests
    {
        [Fact]
        public static void Switch_None_NullCaseNone_Throws()
        {
            Assert.ThrowsAnexn("caseNone", () => Ø.Switch(Funk<int, AnyResult>.Any, Funk<AnyResult>.Null));
            Assert.ThrowsAnexn("caseNone", () => AnyT.None.Switch(Funk<AnyT, AnyResult>.Any, Funk<AnyResult>.Null));
        }

        [Fact]
        public static void Switch_None_NullCaseSome_DoesNotThrow()
        {
            // Act
            AnyResult v = Ø.Switch(Funk<int, AnyResult>.Null, () => AnyResult.Value);
            // Assert
            Assert.Same(AnyResult.Value, v);
        }

        [Fact]
        public static void Switch_Some_NullCaseSome_Throws()
        {
            Assert.ThrowsAnexn("caseSome", () => One.Switch(Funk<int, AnyResult>.Null, Funk<AnyResult>.Any));
            Assert.ThrowsAnexn("caseSome", () => AnyT.Some.Switch(Funk<AnyT, AnyResult>.Null, Funk<AnyResult>.Any));

            Assert.ThrowsAnexn("caseSome", () => One.Switch(Funk<int, AnyResult>.Null, AnyResult.Value));
            Assert.ThrowsAnexn("caseSome", () => AnyT.Some.Switch(Funk<AnyT, AnyResult>.Null, AnyResult.Value));
        }

        [Fact]
        public static void Switch_Some_NullCaseNone_DoesNotThrow()
        {
            // Act
            AnyResult v = One.Switch(
                caseSome: x => AnyResult.Value,
                caseNone: Funk<AnyResult>.Null);
            // Assert
            Assert.Same(AnyResult.Value, v);
        }

        [Fact]
        public static void Switch_None()
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
        public static void Switch_None_WithConstCaseNone()
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
        public static void Switch_Some()
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
        public static void Switch_Some_WithConstCaseNone()
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

        [Fact]
        public static void TryGetValue_None()
        {
            Assert.False(Ø.TryGetValue(out int _));
            Assert.False(NoText.TryGetValue(out string _));
            Assert.False(NoUri.TryGetValue(out Uri _));
            Assert.False(AnyT.None.TryGetValue(out AnyT _));
        }

        [Fact]
        public static void TryGetValue_Some()
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

        [Fact]
        public static void ValueOrDefault_None()
        {
            Assert.Equal(0, Ø.ValueOrDefault());
            Assert.Null(NoText.ValueOrDefault());
            Assert.Null(NoUri.ValueOrDefault());
            Assert.Null(AnyT.None.ValueOrDefault());
        }

        [Fact]
        public static void ValueOrDefault_Some()
        {
            Assert.Equal(1, One.ValueOrDefault());
            Assert.Equal(MyText, SomeText.ValueOrDefault());
            Assert.Equal(MyUri, SomeUri.ValueOrDefault());

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrDefault());
        }

        [Fact]
        public static void ValueOrElse_None_NullFactory_Throws()
        {
            Assert.ThrowsAnexn("valueFactory", () => Ø.ValueOrElse(Funk<int>.Null));
            Assert.ThrowsAnexn("valueFactory", () => AnyT.None.ValueOrElse(Funk<AnyT>.Null));
        }

        [Fact]
        public static void ValueOrElse_Some_NullFactory_DoesNotThrow()
        {
            Assert.Equal(1, One.ValueOrElse(Funk<int>.Null));
            Assert.Equal(MyText, SomeText.ValueOrElse(Funk<string>.Null));
            Assert.Equal(MyUri, SomeUri.ValueOrElse(Funk<Uri>.Null));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrElse(Funk<AnyT>.Null));
        }

        [Fact]
        public static void ValueOrElse_None()
        {
            Assert.Equal(3, Ø.ValueOrElse(3));
            Assert.Equal("other", NoText.ValueOrElse("other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(otherUri, NoUri.ValueOrElse(otherUri));

            var otherAnyT = AnyT.Value;
            Assert.Equal(otherAnyT, AnyT.None.ValueOrElse(otherAnyT));
        }

        [Fact]
        public static void ValueOrElse_None_WithFactory()
        {
            Assert.Equal(3, Ø.ValueOrElse(() => 3));
            Assert.Equal("other", NoText.ValueOrElse(() => "other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(otherUri, NoUri.ValueOrElse(() => otherUri));

            var otherAnyT = AnyT.Value;
            Assert.Equal(otherAnyT, AnyT.None.ValueOrElse(() => otherAnyT));
        }

        [Fact]
        public static void ValueOrElse_Some()
        {
            Assert.Equal(1, One.ValueOrElse(3));
            Assert.Equal(MyText, SomeText.ValueOrElse("other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(MyUri, SomeUri.ValueOrElse(otherUri));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrElse(AnyT.Value));
        }

        [Fact]
        public static void ValueOrElse_Some_WithFactory()
        {
            Assert.Equal(1, One.ValueOrElse(() => 3));
            Assert.Equal(MyText, SomeText.ValueOrElse(() => "other"));

            var otherUri = new Uri("https://source.dot.net/");
            Assert.Equal(MyUri, SomeUri.ValueOrElse(() => otherUri));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrElse(() => AnyT.Value));
        }

        [Fact]
        public static void ValueOrThrow_NullException()
        {
            Assert.ThrowsAnexn("exception", () => Ø.ValueOrThrow(null!));
            Assert.ThrowsAnexn("exception", () => AnyT.None.ValueOrThrow(null!));
        }

        [Fact]
        public static void ValueOrThrow_None()
        {
            Assert.Throws<InvalidOperationException>(() => Ø.ValueOrThrow());
            Assert.Throws<InvalidOperationException>(() => NoText.ValueOrThrow());
            Assert.Throws<InvalidOperationException>(() => NoUri.ValueOrThrow());
            Assert.Throws<InvalidOperationException>(() => AnyT.None.ValueOrThrow());
        }

        [Fact]
        public static void ValueOrThrow_None_WithCustomException()
        {
            Assert.Throws<NotSupportedException>(() => Ø.ValueOrThrow(new NotSupportedException()));
            Assert.Throws<NotSupportedException>(() => NoText.ValueOrThrow(new NotSupportedException()));
            Assert.Throws<NotSupportedException>(() => NoUri.ValueOrThrow(new NotSupportedException()));
            Assert.Throws<NotSupportedException>(() => AnyT.None.ValueOrThrow(new NotSupportedException()));
        }

        [Fact]
        public static void ValueOrThrow_Some()
        {
            Assert.Equal(1, One.ValueOrThrow());
            Assert.Equal(MyText, SomeText.ValueOrThrow());
            Assert.Equal(MyUri, SomeUri.ValueOrThrow());

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrThrow());
        }

        [Fact]
        public static void ValueOrThrow_Some_WithCustomException()
        {
            Assert.Equal(1, One.ValueOrThrow(new NotSupportedException()));
            Assert.Equal(MyText, SomeText.ValueOrThrow(new NotSupportedException()));
            Assert.Equal(MyUri, SomeUri.ValueOrThrow(new NotSupportedException()));

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value, anyT.Some.ValueOrThrow(new NotSupportedException()));
        }
    }

    // Side effects.
    public partial class MaybeTests
    {
        [Fact]
        public static void Do_None_NullOnNone_Throws()
        {
            Assert.ThrowsAnexn("onNone", () => Ø.Do(Act<int>.Noop, Act.Null));
            Assert.ThrowsAnexn("onNone", () => AnyT.None.Do(Act<AnyT>.Noop, Act.Null));
        }

        [Fact]
        public static void Do_None_NullOnSome_DoesNotThrow()
        {
            // Act
            var ex = Record.Exception(() => Ø.Do(Act<int>.Null, Act.Noop));
            // Assert
            Assert.Null(ex);
        }

        [Fact]
        public static void Do_Some_NullOnSome_Throws()
        {
            Assert.ThrowsAnexn("onSome", () => One.Do(Act<int>.Null, Act.Noop));
            Assert.ThrowsAnexn("onSome", () => AnyT.Some.Do(Act<AnyT>.Null, Act.Noop));
        }

        [Fact]
        public static void Do_Some_NullOnNone_DoesNotThrow()
        {
            // Act
            var ex = Record.Exception(() => One.Do(Act<int>.Noop, Act.Null));
            // Assert
            Assert.Null(ex);
        }

        [Fact]
        public static void Do_None()
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
        public static void Do_Some()
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

        [Fact]
        public static void OnSome_None_NullAction_DoesNotThrow()
        {
            // Act
            var ex = Record.Exception(() => Ø.OnSome(Act<int>.Null));
            // Assert
            Assert.Null(ex);
        }

        [Fact]
        public static void OnSome_Some_NullAction_Throws()
        {
            Assert.ThrowsAnexn("action", () => One.OnSome(Act<int>.Null));
            Assert.ThrowsAnexn("action", () => AnyT.Some.OnSome(Act<AnyT>.Null));
        }

        [Fact]
        public static void OnSome_None()
        {
            // Arrange
            bool wasCalled = false;
            // Act
            NoText.OnSome(_ => { wasCalled = true; });
            // Assert
            Assert.False(wasCalled);
        }

        [Fact]
        public static void OnSome_Some()
        {
            // Arrange
            bool wasCalled = false;
            // Act
            SomeText.OnSome(_ => { wasCalled = true; });
            // Assert
            Assert.True(wasCalled);
        }

        [Fact]
        public static void When_None_WithFalse()
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
        public static void When_Some_WithFalse()
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
        public static void When_None_WithTrue()
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
        public static void When_Some_WithTrue()
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
    }

    // Iterable.
    public partial class MaybeTests
    {
        [Fact]
        public static void ToEnumerable()
        {
            Assert.Equal(Enumerable.Repeat(MyText, 1), SomeText.ToEnumerable());
            Assert.Empty(NoText.ToEnumerable());
        }

        [Fact]
        public static void GetEnumerator_None_ForEach()
        {
            foreach (string _ in NoText)
            {
                Assert.Fails("An empty maybe should create an empty iterator.");
            }
        }

        [Fact]
        public static void GetEnumerator_None_ExplicitIterator()
        {
            var iter = NoText.GetEnumerator();

            Assert.False(iter.MoveNext());
            iter.Reset();
            Assert.False(iter.MoveNext());
        }

        [Fact]
        public static void GetEnumerator_Some_ForEach()
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
        public static void GetEnumerator_Some_ExplicitIterator()
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

        [Fact]
        public static void Yield_None() =>
            Assert.Empty(NoText.Yield());

        [Fact]
        public static void Yield_None_WithCount()
        {
            Assert.Empty(NoText.Yield(0));
            Assert.Empty(NoText.Yield(10));
            Assert.Empty(NoText.Yield(100));
            Assert.Empty(NoText.Yield(1000));
        }

        [Fact]
        public static void Yield_Some()
        {
            Assert.Equal(Enumerable.Repeat(MyText, 0), SomeText.Yield().Take(0));
            Assert.Equal(Enumerable.Repeat(MyText, 1), SomeText.Yield().Take(1));
            Assert.Equal(Enumerable.Repeat(MyText, 10), SomeText.Yield().Take(10));
            Assert.Equal(Enumerable.Repeat(MyText, 100), SomeText.Yield().Take(100));
            Assert.Equal(Enumerable.Repeat(MyText, 1000), SomeText.Yield().Take(1000));
        }

        [Fact]
        public static void Yield_Some_WithCount()
        {
            Assert.Equal(Enumerable.Repeat(MyText, 0), SomeText.Yield(0));
            Assert.Equal(Enumerable.Repeat(MyText, 1), SomeText.Yield(1));
            Assert.Equal(Enumerable.Repeat(MyText, 10), SomeText.Yield(10));
            Assert.Equal(Enumerable.Repeat(MyText, 100), SomeText.Yield(100));
            Assert.Equal(Enumerable.Repeat(MyText, 1000), SomeText.Yield(1000));
        }

        [Fact]
        public static void Contains_None_NullComparer()
        {
            Assert.ThrowsAnexn("comparer", () => Ø.Contains(1, null!));
            Assert.ThrowsAnexn("comparer", () => AnyT.None.Contains(AnyT.Value, null!));
        }

        [Fact]
        public static void Contains_Some_NullComparer()
        {
            Assert.ThrowsAnexn("comparer", () => One.Contains(1, null!));
            Assert.ThrowsAnexn("comparer", () => AnyT.Some.Contains(AnyT.Value, null!));
        }

        [Fact]
        public static void Contains_None_Int32()
        {
            Assert.False(Ø.Contains(0));
            Assert.False(Ø.Contains(1));
            Assert.False(Ø.Contains(2));
        }

        [Fact]
        public static void Contains_None_Text()
        {
            Assert.False(NoText.Contains("XXX"));
            Assert.False(NoText.Contains("XXX", StringComparer.Ordinal));
            Assert.False(NoText.Contains("XXX", StringComparer.OrdinalIgnoreCase));
        }

        [Fact]
        public static void Contains_SomeInt32()
        {
            Assert.False(One.Contains(0));
            Assert.True(One.Contains(1));
            Assert.False(One.Contains(2));
        }

        [Fact]
        public static void Contains_SomeText()
        {
            Assert.True(Maybe.SomeOrNone("XXX").Contains("XXX"));
            // Default comparison does NOT ignore case.
            Assert.False(Maybe.SomeOrNone("XXX").Contains("xxx"));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("yyy"));
        }

        [Fact]
        public static void Contains_SomeText_WithComparer()
        {
            Assert.True(Maybe.SomeOrNone("XXX").Contains("XXX", StringComparer.Ordinal));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("xxx", StringComparer.Ordinal));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("yyy", StringComparer.Ordinal));

            Assert.True(Maybe.SomeOrNone("XXX").Contains("XXX", StringComparer.OrdinalIgnoreCase));
            Assert.True(Maybe.SomeOrNone("XXX").Contains("xxx", StringComparer.OrdinalIgnoreCase));
            Assert.False(Maybe.SomeOrNone("XXX").Contains("yyy", StringComparer.OrdinalIgnoreCase));
        }

        [Fact]
        public static void Contains_SomeText_Anagram()
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
    }
}

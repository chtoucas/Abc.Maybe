// See LICENSE in the project root for license information.

namespace Abc
{
    using System;

    using Xunit;

    using Assert = AssertEx;

    public partial class MaybeTests
    {
        // Normalization: Flatten(), Squash().
        public static partial class MaybeHelper
        {
            #region Flatten()

            [Fact]
            public static void Flatten_None()
            {
                Assert.Equal(Ø, Maybe<Maybe<int>>.None.Flatten());
                Assert.Equal(NoText, Maybe<Maybe<string>>.None.Flatten());
                Assert.Equal(NoUri, Maybe<Maybe<Uri>>.None.Flatten());
                Assert.Equal(AnyT.None, Maybe<Maybe<AnyT>>.None.Flatten());

                Assert.Equal(Maybe<int?>.None, Maybe<Maybe<int?>>.None.Flatten());
                Assert.Equal(Maybe<string?>.None, Maybe<Maybe<string?>>.None.Flatten());
                Assert.Equal(Maybe<Uri?>.None, Maybe<Maybe<Uri?>>.None.Flatten());
                Assert.Equal(Maybe<AnyT?>.None, Maybe<Maybe<AnyT?>>.None.Flatten());
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

                Maybe<AnyT> some = AnyT.Some;
                Assert.Equal(some, Maybe.Some(some).Flatten());

                Maybe<int?> one = One.Select(x => (int?)x);
                Assert.Equal(one, Maybe.Some(one).Flatten());
            }

            #endregion

            #region Squash()

            [Fact]
            public static void Squash_None()
            {
                Assert.Equal(Ø, Maybe<int?>.None.Squash());
                Assert.Equal(NoText, Maybe<string?>.None.Squash());
                Assert.Equal(NoUri, Maybe<Uri?>.None.Squash());
                Assert.Equal(AnyT.None, Maybe<AnyT?>.None.Squash());
            }

            [Fact]
            public static void Squash_Some_ForValueType()
            {
                // Arrange
                Maybe<int?> one = One.Select(x => (int?)x);
                // Act & Assert
                Assert.Equal(One, one.Squash());
            }

            [Fact]
            public static void Squash_Some_ForReferenceType()
            {
                // Arrange
                Maybe<AnyT> some = AnyT.Some;
                Maybe<AnyT?> one = some.Select(x => (AnyT?)x);
                // Act & Assert
                Assert.Equal(some, one.Squash());
            }

            [Fact]
            public static void Squash_Square_None()
            {
                Assert.Equal(Ø, Maybe<Maybe<int?>>.None.Squash());
                Assert.Equal(NoText, Maybe<Maybe<string?>>.None.Squash());
                Assert.Equal(NoUri, Maybe<Maybe<Uri?>>.None.Squash());
                Assert.Equal(AnyT.None, Maybe<Maybe<AnyT?>>.None.Squash());
            }

            [Fact]
            public static void Squash_Square_Some_ForValueType()
            {
                // Arrange
                Maybe<int?> one = One.Select(x => (int?)x);
                Maybe<Maybe<int?>> square = Maybe.Some(one);
                // Act & Assert
                Assert.Equal(One, square.Squash());
            }

            [Fact]
            public static void Squash_Square_Some_ForReferenceType()
            {
                // Arrange
                Maybe<AnyT> m = AnyT.Some;
                Maybe<AnyT?> some = m.Select(x => (AnyT?)x);
                Maybe<Maybe<AnyT?>> square = Maybe.Some(some);
                // Act & Assert
                Assert.Equal(m, square.Squash());
            }

            #endregion
        }

        // Helpers for Maybe<T> where T is a struct.
        public static partial class MaybeHelper
        {
            [Fact]
            public static void ToNullable_None()
            {
                // Arrange
                Maybe<int?> none = Maybe<int?>.None;
                // Act & Assert
                Assert.Null(Ø.ToNullable());
                Assert.Null(none.ToNullable());
            }

            [Fact]
            public static void ToNullable_Some()
            {
                // Arrange
                Maybe<int?> one = One.Select(x => (int?)x);
                // Act & Assert
                Assert.Equal(1, One.ToNullable());
                Assert.Equal(1, one.ToNullable());
            }
        }

        // Helpers for Maybe<Unit>.
        public static partial class MaybeHelper
        {
            [Fact] public static void Unit_IsSome() => Assert.Some(Unit.Default, Maybe.Unit);

            [Fact] public static void Zero_IsNone() => Assert.None(Maybe.Zero);

            [Fact] public static void Guard_ReturnsZero_WithFalse() => Assert.Equal(Maybe.Zero, Maybe.Guard(false));

            [Fact] public static void Guard_ReturnsUnit_WithTrue() => Assert.Equal(Maybe.Unit, Maybe.Guard(true));
        }

        // Helpers for Maybe<bool>.
        public static partial class MaybeHelper
        {
            [Fact] public static void True_IsSome() => Assert.Some(true, Maybe.True);

            [Fact] public static void False_IsSome() => Assert.Some(false, Maybe.False);

            [Fact] public static void Unknown_IsNone() => Assert.None(Maybe.Unknown);

            [Fact] public static void Negate_True() => Assert.Some(false, Maybe.True.Negate());

            [Fact] public static void Negate_False() => Assert.Some(true, Maybe.False.Negate());

            [Fact] public static void Negate_Unknown() => Assert.Unknown(Maybe.Unknown.Negate());

            [Fact]
            public static void Or()
            {
                Assert.Some(true, Maybe.True.Or(Maybe.True));
                Assert.Some(true, Maybe.True.Or(Maybe.False));
                Assert.Some(true, Maybe.True.Or(Maybe.Unknown));

                Assert.Some(true, Maybe.False.Or(Maybe.True));
                Assert.Some(false, Maybe.False.Or(Maybe.False));
                Assert.Unknown(Maybe.False.Or(Maybe.Unknown));

                Assert.Some(true, Maybe.Unknown.Or(Maybe.True));
                Assert.Unknown(Maybe.Unknown.Or(Maybe.False));
                Assert.Unknown(Maybe.Unknown.Or(Maybe.Unknown));
            }

            [Fact]
            public static void And()
            {
                Assert.Some(true, Maybe.True.And(Maybe.True));
                Assert.Some(false, Maybe.True.And(Maybe.False));
                Assert.Unknown(Maybe.True.And(Maybe.Unknown));

                Assert.Some(false, Maybe.False.And(Maybe.True));
                Assert.Some(false, Maybe.False.And(Maybe.False));
                Assert.Some(false, Maybe.False.And(Maybe.Unknown));

                Assert.Unknown(Maybe.Unknown.And(Maybe.True));
                Assert.Some(false, Maybe.Unknown.And(Maybe.False));
                Assert.Unknown(Maybe.Unknown.And(Maybe.Unknown));
            }
        }

        // Helpers for Maybe<T> where T is disposable.
        public static partial class MaybeHelper
        {
#pragma warning disable CA2000 // Dispose objects before losing scope

            [Fact]
            public static void Use_WithNullBinder()
            {
                // Arrange
                var source = Maybe.SomeOrNone(new AnyDisposable());
                // Act & Assert
                Assert.ThrowsAnexn("binder", () =>
                    source.Use(Kunc<AnyDisposable, int>.Null));
            }

            [Fact]
            public static void Use_WithNullSelector()
            {
                // Arrange
                var source = Maybe.SomeOrNone(new AnyDisposable());
                // Act & Assert
                Assert.ThrowsAnexn("selector", () =>
                    source.Use(Funk<AnyDisposable, int>.Null));
            }

            [Fact]
            public static void Use_Bind()
            {
                // Arrange
                var obj = new AnyDisposable();
                var source = Maybe.SomeOrNone(obj);
                // Act
                Maybe<int> result = source.Use(_ => Maybe.Some(1));
                // Assert
                Assert.Some(1, result);
                Assert.True(obj.WasDisposed);
            }

            [Fact]
            public static void Use_Select()
            {
                // Arrange
                var obj = new AnyDisposable();
                var source = Maybe.SomeOrNone(obj);
                // Act
                Maybe<int> result = source.Use(_ => 1);
                // Assert
                Assert.Some(1, result);
                Assert.True(obj.WasDisposed);
            }

#pragma warning restore CA2000
        }
    }
}

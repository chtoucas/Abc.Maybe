// See LICENSE in the project root for license information.

namespace Abc
{
    using System;

    using Xunit;

    using Assert = AssertEx;

    public partial class MaybeTests
    {
        // Normalization: Flatten().
        // Here, we really want to see the return type (because of NRTs),
        // therefore we don't use Assert.None() or Assert.Some().
        public static partial class MaybeHelper
        {
            [Fact]
            public static void Flatten_None_ForValueT()
            {
                Assert.Equal(Maybe<Unit>.None, Maybe<Maybe<Unit>>.None.Flatten());
                Assert.Equal(Maybe<int>.None, Maybe<Maybe<int>>.None.Flatten());
                Assert.Equal(Maybe<long>.None, Maybe<Maybe<long>>.None.Flatten());
            }

            [Fact]
            public static void Flatten_None_ForValueT_AndNullable()
            {
                Assert.Equal(Maybe<Unit?>.None, Maybe<Maybe<Unit?>>.None.Flatten());
                Assert.Equal(Maybe<int?>.None, Maybe<Maybe<int?>>.None.Flatten());
                Assert.Equal(Maybe<long?>.None, Maybe<Maybe<long?>>.None.Flatten());
            }

            [Fact]
            public static void Flatten_None_ForReferenceT()
            {
                Assert.Equal(Maybe<string>.None, Maybe<Maybe<string>>.None.Flatten());
                Assert.Equal(Maybe<Uri>.None, Maybe<Maybe<Uri>>.None.Flatten());
                Assert.Equal(Maybe<AnyT>.None, Maybe<Maybe<AnyT>>.None.Flatten());
                Assert.Equal(Maybe<object>.None, Maybe<Maybe<object>>.None.Flatten());
            }

            [Fact]
            public static void Flatten_None_ForReferenceT_AndNullable()
            {
                Assert.Equal(Maybe<string?>.None, Maybe<Maybe<string?>>.None.Flatten());
                Assert.Equal(Maybe<Uri?>.None, Maybe<Maybe<Uri?>>.None.Flatten());
                Assert.Equal(Maybe<AnyT?>.None, Maybe<Maybe<AnyT?>>.None.Flatten());
                Assert.Equal(Maybe<object?>.None, Maybe<Maybe<object?>>.None.Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfNone_ForValueT()
            {
                Assert.Equal(Maybe<Unit>.None, Maybe.Some(Maybe<Unit>.None).Flatten());
                Assert.Equal(Maybe<int>.None, Maybe.Some(Maybe<int>.None).Flatten());
                Assert.Equal(Maybe<long>.None, Maybe.Some(Maybe<long>.None).Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfNone_ForValueT_AndNullable()
            {
                Assert.Equal(Maybe<Unit?>.None, Maybe.Some(Maybe<Unit?>.None).Flatten());
                Assert.Equal(Maybe<int?>.None, Maybe.Some(Maybe<int?>.None).Flatten());
                Assert.Equal(Maybe<long?>.None, Maybe.Some(Maybe<long?>.None).Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfNone_ForReferenceT()
            {
                Assert.Equal(Maybe<string>.None, Maybe.Some(Maybe<string>.None).Flatten());
                Assert.Equal(Maybe<Uri>.None, Maybe.Some(Maybe<Uri>.None).Flatten());
                Assert.Equal(Maybe<AnyT>.None, Maybe.Some(Maybe<AnyT>.None).Flatten());
                Assert.Equal(Maybe<object>.None, Maybe.Some(Maybe<object>.None).Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfNone_ForReferenceT_AndNullable()
            {
                Assert.Equal(Maybe<string?>.None, Maybe.Some(Maybe<string?>.None).Flatten());
                Assert.Equal(Maybe<Uri?>.None, Maybe.Some(Maybe<Uri?>.None).Flatten());
                Assert.Equal(Maybe<AnyT?>.None, Maybe.Some(Maybe<AnyT?>.None).Flatten());
                Assert.Equal(Maybe<object?>.None, Maybe.Some(Maybe<object?>.None).Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfSome_ForValueT()
            {
                // Arrange
                Maybe<Maybe<int>> square = Maybe.Some(One);
                // Act & Assert
                Assert.Equal(One, square.Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfSome_ForValueT_AndNullable()
            {
                // Arrange
                Maybe<int?> one = One.Select(x => (int?)x);
                Maybe<Maybe<int?>> square = Maybe.Some(one);
                // Act & Assert
                Assert.Equal(one, square.Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfSome_ForReferenceT()
            {
                Maybe<AnyT> some = AnyT.Some;
                Assert.Equal(some, Maybe.Some(some).Flatten());
            }

            [Fact]
            public static void Flatten_SomeOfSome_ForReferenceT_AndNullable()
            {
                // Arrange
                Maybe<AnyT?> some = AnyT.Some.Select(x => (AnyT?)x);
                Maybe<Maybe<AnyT?>> square = Maybe.Some(some);
                // Act & Assert
                Assert.Equal(some, square.Flatten());
            }
        }

        // Normalization: Squash().
        // Here, we really want to see the return type (because of NRTs),
        // therefore we don't use Assert.None() or Assert.Some().
        public static partial class MaybeHelper
        {
            #region Squash()

            [Fact]
            public static void Squash_None_ForValueT()
            {
                Assert.Equal(Maybe<Unit>.None, Maybe<Unit?>.None.Squash());
                Assert.Equal(Maybe<int>.None, Maybe<int?>.None.Squash());
                Assert.Equal(Maybe<long>.None, Maybe<long?>.None.Squash());
            }

            [Fact]
            public static void Squash_None_ForReferenceT()
            {
                Assert.Equal(Maybe<string>.None, Maybe<string?>.None.Squash());
                Assert.Equal(Maybe<Uri>.None, Maybe<Uri?>.None.Squash());
                Assert.Equal(Maybe<AnyT>.None, Maybe<AnyT?>.None.Squash());
                Assert.Equal(Maybe<object>.None, Maybe<object?>.None.Squash());
            }

            [Fact]
            public static void Squash_None_ForReferenceT_WithoutNRTs()
            {
#nullable disable annotations
                Assert.Equal(Maybe<string>.None, Maybe<string>.None.Squash());
                Assert.Equal(Maybe<Uri>.None, Maybe<Uri>.None.Squash());
                Assert.Equal(Maybe<AnyT>.None, Maybe<AnyT>.None.Squash());
                Assert.Equal(Maybe<object>.None, Maybe<object>.None.Squash());
#nullable restore annotations
            }

            [Fact]
            public static void Squash_Some_ForValueT()
            {
                // Arrange
                Maybe<int?> one = One.Select(x => (int?)x);
                // Act & Assert
                Assert.Equal(One, one.Squash());
            }

            [Fact]
            public static void Squash_Some_ForReferenceT()
            {
                // Arrange
                Maybe<AnyT> m = AnyT.Some;
                Maybe<AnyT?> some = m.Select(x => (AnyT?)x);
                // Act & Assert
                Assert.Equal(m, some.Squash());
            }

            [Fact]
            public static void Squash_Some_ForReferenceT_WithoutNRTs()
            {
                // Arrange
                Maybe<AnyT> some = AnyT.Some;
                // Act & Assert
#nullable disable warnings
                Assert.Equal(some, some.Squash());
#nullable restore warnings
            }

            #endregion

            #region Squash(square)

            [Fact]
            public static void Squash2_None_ForValueT()
            {
                Assert.Equal(Maybe<Unit>.None, Maybe<Maybe<Unit?>>.None.Squash());
                Assert.Equal(Maybe<int>.None, Maybe<Maybe<int?>>.None.Squash());
                Assert.Equal(Maybe<long>.None, Maybe<Maybe<long?>>.None.Squash());
            }

            [Fact]
            public static void Squash2_None_ForRerenceType()
            {
                Assert.Equal(Maybe<string>.None, Maybe<Maybe<string?>>.None.Squash());
                Assert.Equal(Maybe<Uri>.None, Maybe<Maybe<Uri?>>.None.Squash());
                Assert.Equal(Maybe<AnyT>.None, Maybe<Maybe<AnyT?>>.None.Squash());
                Assert.Equal(Maybe<object>.None, Maybe<Maybe<object?>>.None.Squash());
            }

            [Fact]
            public static void Squash2_None_ForRerenceType_WithoutNRTs()
            {
#nullable disable annotations
                Assert.Equal(Maybe<string>.None, Maybe<Maybe<string>>.None.Squash());
                Assert.Equal(Maybe<Uri>.None, Maybe<Maybe<Uri>>.None.Squash());
                Assert.Equal(Maybe<AnyT>.None, Maybe<Maybe<AnyT>>.None.Squash());
                Assert.Equal(Maybe<object>.None, Maybe<Maybe<object>>.None.Squash());
#nullable restore annotations
            }

            [Fact]
            public static void Squash2_SomeOfNone_ForValueT()
            {
                Assert.Equal(Maybe<Unit>.None, Maybe.Some(Maybe<Unit?>.None).Squash());
                Assert.Equal(Maybe<int>.None, Maybe.Some(Maybe<int?>.None).Squash());
                Assert.Equal(Maybe<long>.None, Maybe.Some(Maybe<long?>.None).Squash());
            }

            [Fact]
            public static void Squash2_SomeOfNone_ForReferenceT()
            {
                Assert.Equal(Maybe<string>.None, Maybe.Some(Maybe<string?>.None).Squash());
                Assert.Equal(Maybe<Uri>.None, Maybe.Some(Maybe<Uri?>.None).Squash());
                Assert.Equal(Maybe<AnyT>.None, Maybe.Some(Maybe<AnyT?>.None).Squash());
                Assert.Equal(Maybe<object>.None, Maybe.Some(Maybe<object?>.None).Squash());
            }

            [Fact]
            public static void Squash2_SomeOfNone_ForReferenceT_WithoutNRTs()
            {
#nullable disable annotations
                Assert.Equal(Maybe<string>.None, Maybe.Some(Maybe<string>.None).Squash());
                Assert.Equal(Maybe<Uri>.None, Maybe.Some(Maybe<Uri>.None).Squash());
                Assert.Equal(Maybe<AnyT>.None, Maybe.Some(Maybe<AnyT>.None).Squash());
                Assert.Equal(Maybe<object>.None, Maybe.Some(Maybe<object>.None).Squash());
#nullable restore annotations
            }

            [Fact]
            public static void Squash2_SomeOfSome_ForValueT()
            {
                // Arrange
                Maybe<int?> one = One.Select(x => (int?)x);
                Maybe<Maybe<int?>> square = Maybe.Some(one);
                // Act & Assert
                Assert.Equal(One, square.Squash());
            }

            [Fact]
            public static void Squash2_SomeOfSome_ForReferenceT()
            {
                // Arrange
                Maybe<AnyT> m = AnyT.Some;
                Maybe<AnyT?> some = m.Select(x => (AnyT?)x);
                Maybe<Maybe<AnyT?>> square = Maybe.Some(some);
                // Act & Assert
                Assert.Equal(m, square.Squash());
            }

            [Fact]
            public static void Squash2_SomeOfSome_ForReferenceT_WithoutNRTs()
            {
                // Arrange
                Maybe<AnyT> some = AnyT.Some;
                Maybe<Maybe<AnyT>> square = Maybe.Some(some);
                // Act & Assert
#nullable disable warnings
                Assert.Equal(some, square.Squash());
#nullable restore warnings
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

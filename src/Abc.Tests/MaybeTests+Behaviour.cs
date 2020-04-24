// See LICENSE in the project root for license information.

namespace Abc
{
    using System;

    using Xunit;

    using Assert = AssertEx;

    public partial class MaybeTests
    {
        // SquareXXX() compared to Some(SomeXXX()).
        public static partial class Behaviour
        {
            [Fact]
            public static void Square_IsSomeOfSome()
            {
                Assert.Equal(__(Unit.Default), Maybe.Square(Unit.Default));
                Assert.Equal(__(314), Maybe.Square(314));
                Assert.Equal(__(413L), Maybe.Square(413L));

                static Maybe<Maybe<T>> __<T>(T x) where T : struct => Maybe.Some(Maybe.Some(x));
            }

            [Fact]
            public static void SquareOrNone_ForValueT_WithNotNull_IsSomeOfSomeOrNone()
            {
                Assert.Equal(__(Unit.Default), Maybe.SquareOrNone((Unit?)Unit.Default));
                Assert.Equal(__(314), Maybe.SquareOrNone((int?)314));
                Assert.Equal(__(413L), Maybe.SquareOrNone((long?)413));

                static Maybe<Maybe<T>> __<T>(T x) where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)x));
            }

            [Fact]
            public static void SquareOrNone_ForReferenceT_WithNotNull_IsSomeOfSomeOrNone()
            {
                Assert.Equal(__(MyText), Maybe.SquareOrNone(MyText));
                Assert.Equal(__(MyUri), Maybe.SquareOrNone(MyUri));

                var anyT = AnyT.Value;
                Assert.Equal(__(anyT), Maybe.SquareOrNone(anyT));

                var obj = new object();
                Assert.Equal(__(obj), Maybe.SquareOrNone(obj));

                static Maybe<Maybe<T>> __<T>(T x) where T : class => Maybe.Some(Maybe.SomeOrNone(x));
            }

#if PATCH_EQUALITY
            [Fact]
            public static void SquareOrNone_ForValueT_WithNull_IsSomeOfSomeOrNone()
            {
                Assert.Equal(__<Unit>(), Maybe.SquareOrNone((Unit?)null));
                Assert.Equal(__<int>(), Maybe.SquareOrNone((int?)null));
                Assert.Equal(__<long>(), Maybe.SquareOrNone((long?)null));

                static Maybe<Maybe<T>> __<T>() where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)null));
            }

            [Fact]
            public static void SquareOrNone_ForReferenceT_WithNull_IsSomeOfSomeOrNone()
            {
                Assert.Equal(__<string>(), Maybe.SquareOrNone((string?)null));
                Assert.Equal(__<Uri>(), Maybe.SquareOrNone((Uri?)null));
                Assert.Equal(__<AnyT>(), Maybe.SquareOrNone((AnyT?)null));
                Assert.Equal(__<object>(), Maybe.SquareOrNone((object?)null));

                static Maybe<Maybe<T>> __<T>() where T : class => Maybe.Some(Maybe.SomeOrNone((T?)null));
            }
#else
            [Fact]
            public static void SquareOrNone_ForValueT_WithNull_IsNotSomeOfSomeOrNone()
            {
                Assert.NotEqual(__<Unit>(), Maybe.SquareOrNone((Unit?)null));
                Assert.NotEqual(__<int>(), Maybe.SquareOrNone((int?)null));
                Assert.NotEqual(__<long>(), Maybe.SquareOrNone((long?)null));

                static Maybe<Maybe<T>> __<T>() where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)null));
            }

            [Fact]
            public static void SquareOrNone_ForReferenceT_WithNull_IsNotSomeOfSomeOrNone()
            {
                Assert.NotEqual(__<string>(), Maybe.SquareOrNone((string?)null));
                Assert.NotEqual(__<Uri>(), Maybe.SquareOrNone((Uri?)null));
                Assert.NotEqual(__<AnyT>(), Maybe.SquareOrNone((AnyT?)null));
                Assert.NotEqual(__<object>(), Maybe.SquareOrNone((object?)null));

                static Maybe<Maybe<T>> __<T>() where T : class => Maybe.Some(Maybe.SomeOrNone((T?)null));
            }
#endif
        }

        // Equality rules of repeated "Some" starting from "None" depends on the
        // compiler symbol PATCH_EQUALITY.
        public static partial class Behaviour
        {
#if PATCH_EQUALITY
            [Fact]
            public static void SomeOfNone_EqualsNone_ForValueT()
            {
                Assert.Equal(Maybe<Maybe<Unit>>.None, Maybe.Some(Maybe<Unit>.None));
                Assert.Equal(Maybe<Maybe<int>>.None, Maybe.Some(Maybe<int>.None));
                Assert.Equal(Maybe<Maybe<long>>.None, Maybe.Some(Maybe<long>.None));
            }

            [Fact]
            public static void SomeOfNone_EqualsNone_ForReferenceT()
            {
                Assert.Equal(Maybe<Maybe<string>>.None, Maybe.Some(Maybe<string>.None));
                Assert.Equal(Maybe<Maybe<Uri>>.None, Maybe.Some(Maybe<Uri>.None));
                Assert.Equal(Maybe<Maybe<AnyT>>.None, Maybe.Some(Maybe<AnyT>.None));
                Assert.Equal(Maybe<Maybe<object>>.None, Maybe.Some(Maybe<object>.None));
            }

            [Fact]
            public static void SomeSomeOfNone_EqualsNone_ForValueT()
            {
                Assert.Equal(Maybe<Maybe<Maybe<Unit>>>.None, __<Unit>());
                Assert.Equal(Maybe<Maybe<Maybe<int>>>.None, __<int>());
                Assert.Equal(Maybe<Maybe<Maybe<long>>>.None, __<long>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : struct
                    => Maybe.Some(Maybe.Some(Maybe<T>.None));
            }

            [Fact]
            public static void SomeSomeOfNone_EqualsNone_ForReferenceT()
            {
                Assert.Equal(Maybe<Maybe<Maybe<string>>>.None, __<string>());
                Assert.Equal(Maybe<Maybe<Maybe<Uri>>>.None, __<Uri>());
                Assert.Equal(Maybe<Maybe<Maybe<AnyT>>>.None, __<AnyT>());
                Assert.Equal(Maybe<Maybe<Maybe<object>>>.None, __<object>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : class
                    => Maybe.Some(Maybe.Some(Maybe<T>.None));
            }
#else
            [Fact]
            public static void SomeOfNone_DoesNotEqualNone_ForValueT()
            {
                Assert.NotEqual(Maybe<Maybe<Unit>>.None, Maybe.Some(Maybe<Unit>.None));
                Assert.NotEqual(Maybe<Maybe<int>>.None, Maybe.Some(Maybe<int>.None));
                Assert.NotEqual(Maybe<Maybe<long>>.None, Maybe.Some(Maybe<long>.None));
            }

            [Fact]
            public static void SomeOfNone_DoesNotEqualNone_ForReferenceT()
            {
                Assert.NotEqual(Maybe<Maybe<string>>.None, Maybe.Some(Maybe<string>.None));
                Assert.NotEqual(Maybe<Maybe<Uri>>.None, Maybe.Some(Maybe<Uri>.None));
                Assert.NotEqual(Maybe<Maybe<AnyT>>.None, Maybe.Some(Maybe<AnyT>.None));
                Assert.NotEqual(Maybe<Maybe<object>>.None, Maybe.Some(Maybe<object>.None));
            }

            [Fact]
            public static void SomeSomeOfNone_DoesNotEqualNone_ForValueT()
            {
                Assert.NotEqual(Maybe<Maybe<Maybe<Unit>>>.None, __<Unit>());
                Assert.NotEqual(Maybe<Maybe<Maybe<int>>>.None, __<int>());
                Assert.NotEqual(Maybe<Maybe<Maybe<long>>>.None, __<long>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : struct
                    => Maybe.Some(Maybe.Some(Maybe<T>.None));
            }

            [Fact]
            public static void SomeSomeOfNone_DoesNotEqualNone_ForReferenceT()
            {
                Assert.NotEqual(Maybe<Maybe<Maybe<string>>>.None, __<string>());
                Assert.NotEqual(Maybe<Maybe<Maybe<Uri>>>.None, __<Uri>());
                Assert.NotEqual(Maybe<Maybe<Maybe<AnyT>>>.None, __<AnyT>());
                Assert.NotEqual(Maybe<Maybe<Maybe<object>>>.None, __<object>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : class
                    => Maybe.Some(Maybe.Some(Maybe<T>.None));
            }
#endif
        }
    }
}

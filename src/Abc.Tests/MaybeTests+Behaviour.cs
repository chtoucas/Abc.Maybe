// See LICENSE in the project root for license information.

namespace Abc
{
    using System;

    using Xunit;

    using Assert = AssertEx;

    public partial class MaybeTests
    {
        // Behaviour of repeated "Some" starting from null depends on the
        // compiler symbol PATCH_EQUALITY.
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

#if PATCH_EQUALITY
            [Fact]
            public static void SquareOrNone_ForValueT_WithNull_IsSomeOfSomeOrNone()
            {
                Assert.Equal(__<Unit>(), Maybe.SquareOrNone((Unit?)null));
                Assert.Equal(__<int>(), Maybe.SquareOrNone((int?)null));
                Assert.Equal(__<long>(), Maybe.SquareOrNone((long?)null));

                static Maybe<Maybe<T>> __<T>() where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)null));
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
#endif

            [Fact]
            public static void SquareOrNone_ForValueT_WithNotNull_IsSomeOfSomeOrNone()
            {
                Assert.Equal(__(Unit.Default), Maybe.SquareOrNone((Unit?)Unit.Default));
                Assert.Equal(__(314), Maybe.SquareOrNone((int?)314));
                Assert.Equal(__(413L), Maybe.SquareOrNone((long?)413));

                static Maybe<Maybe<T>> __<T>(T x) where T : struct => Maybe.Some(Maybe.SomeOrNone((T?)x));
            }

#if PATCH_EQUALITY
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
            public static void SquareOrNone_ForReferenceT_WithNull_IsNotSomeOfSomeOrNone()
            {
                Assert.NotEqual(__<string>(), Maybe.SquareOrNone((string?)null));
                Assert.NotEqual(__<Uri>(), Maybe.SquareOrNone((Uri?)null));
                Assert.NotEqual(__<AnyT>(), Maybe.SquareOrNone((AnyT?)null));
                Assert.NotEqual(__<object>(), Maybe.SquareOrNone((object?)null));

                static Maybe<Maybe<T>> __<T>() where T : class => Maybe.Some(Maybe.SomeOrNone((T?)null));
            }
#endif

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
            public static void NthPower_ReturnsNone_WithNull_ForValueT0()
            {
                Assert.None(__<Unit>());
                //Assert.None(__<int>());
                //Assert.None(__<long>());

                static Maybe<Maybe<T>> __<T>() where T : struct
                    => Maybe.Some(Maybe.SomeOrNone((T?)null));
            }
#endif

            //[Fact(Skip = "WIP")]
            //public static void NthPower_ReturnsNone_WithNull_ForValueT()
            //{
            //    Assert.None(__<Unit>());
            //    Assert.None(__<int>());
            //    Assert.None(__<long>());

            //    static Maybe<Maybe<Maybe<T>>> __<T>() where T : struct
            //        => Maybe.Some(Maybe.Some(Maybe.SomeOrNone((T?)null)));
            //}

            //[Fact(Skip = "WIP")]
            //public static void NthPower_ReturnsNone_WithNull_ForReferenceT()
            //{
            //    Assert.None(__<string>());
            //    Assert.None(__<Uri>());
            //    Assert.None(__<AnyT>());
            //    Assert.None(__<object>());

            //    static Maybe<Maybe<Maybe<T>>> __<T>() where T : class
            //        => Maybe.Some(Maybe.Some(Maybe.SomeOrNone((T?)null)));
            //}

            [Fact]
            public static void SomeOfNone_ReturnsSome_ForValueT()
            {
                Assert.Some(Maybe.Some(Maybe<Unit>.None));
                Assert.Some(Maybe.Some(Maybe<int>.None));
                Assert.Some(Maybe.Some(Maybe<long>.None));
            }

            [Fact]
            public static void SomeOfNone_ReturnsSome_ForReferenceT()
            {
                Assert.Some(Maybe.Some(Maybe<string>.None));
                Assert.Some(Maybe.Some(Maybe<Uri>.None));
                Assert.Some(Maybe.Some(Maybe<AnyT>.None));
                Assert.Some(Maybe.Some(Maybe<object>.None));
            }

            [Fact]
            public static void NthPower_ReturnsSome_WithNull_ForValueT()
            {
                Assert.Some(__<Unit>());
                Assert.Some(__<int>());
                Assert.Some(__<long>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : struct
                    => Maybe.Some(Maybe.Some(Maybe.SomeOrNone((T?)null)));
            }

            [Fact]
            public static void NthPower_ReturnsSome_WithNull_ForReferenceT()
            {
                Assert.Some(__<string>());
                Assert.Some(__<Uri>());
                Assert.Some(__<AnyT>());
                Assert.Some(__<object>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : class
                    => Maybe.Some(Maybe.Some(Maybe.SomeOrNone((T?)null)));
            }
        }
    }
}

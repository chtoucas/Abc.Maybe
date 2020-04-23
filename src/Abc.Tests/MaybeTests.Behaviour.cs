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
        // See also the tests for SquareXXX().
        public static partial class Behaviour
        {
#if PATCH_EQUALITY
            [Fact]
            public static void NthPower_ReturnsNone_WithNull_ForValueT()
            {
                Assert.None(__<Unit>());
                Assert.None(__<int>());
                Assert.None(__<long>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : struct
                    => Maybe.Some(Maybe.Some(Maybe.SomeOrNone((T?)null)));
            }

            [Fact]
            public static void NthPower_ReturnsNone_WithNull_ForReferenceT()
            {
                Assert.None(__<string>());
                Assert.None(__<Uri>());
                Assert.None(__<AnyT>());
                Assert.None(__<object>());

                static Maybe<Maybe<Maybe<T>>> __<T>() where T : class
                    => Maybe.Some(Maybe.Some(Maybe.SomeOrNone((T?)null)));
            }
#else
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
#endif
        }
    }
}

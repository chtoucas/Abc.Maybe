﻿// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;

    using Xunit;

    using Assert = AssertEx;

    public partial class MaybeTests
    {
        // Helpers for functions in the Kleisli category.
        public static partial class MaybeHelper
        {
            [Fact]
            public static void Invoke_WithNullBinder()
            {
                Assert.ThrowsAnexn("binder", () =>
                    Kunc<AnyT, AnyResult>.Null
                        .Invoke(AnyT.Some));
            }

            [Fact]
            public static void Invoke_WithNone()
            {
                // Arrange
                var f = Thunk<AnyT>.Return(AnyResult.Some);
                // Act & Assert
                Assert.None(f.Invoke(AnyT.None));
            }

            [Fact]
            public static void Invoke_WithSome()
            {
                // Arrange
                var f = Thunk<AnyT1>.Return(AnyResult.Some);
                var g = Thunk<AnyT1>.Return(AnyResult.None);
                // Act & Assert
                Assert.Some(AnyResult.Value, f.Invoke(AnyT1.Some));
                Assert.None(g.Invoke(AnyT1.Some));
            }

            [Fact]
            public static void Compose_WithNullObject()
            {
                Assert.ThrowsAnexn("this", () =>
                    Kunc<AnyT1, AnyT2>.Null
                        .Compose(Kunc<AnyT2, AnyResult>.Any, AnyT1.Value));
            }

            [Fact]
            public static void Compose()
            {
                // Arrange
                var f = Thunk<AnyT1>.Return(AnyT2.Some);
                var g = Thunk<AnyT2>.Return(AnyResult.Some);
                // Act & Assert
                Assert.Some(AnyResult.Value, f.Compose(g, AnyT1.Value));
            }

            [Fact]
            public static void ComposeBack_WithNullOther()
            {
                Assert.ThrowsAnexn("other", () =>
                    Kunc<AnyT2, AnyResult>.Any
                        .ComposeBack(Kunc<AnyT1, AnyT2>.Null, AnyT1.Value));
            }

            [Fact]
            public static void ComposeBack()
            {
                // Arrange
                var f = Thunk<AnyT1>.Return(AnyT2.Some);
                var g = Thunk<AnyT2>.Return(AnyResult.Some);
                // Act & Assert
                Assert.Some(AnyResult.Value, g.ComposeBack(f, AnyT1.Value));
            }
        }

        // Lift.
        public static partial class MaybeHelper
        {
            [Fact]
            public static void Lift_WithNullSelector()
            {
                Assert.ThrowsAnexn("selector", () =>
                    Funk<AnyT, AnyResult>.Null
                        .Lift(AnyT.Some));
            }

            [Fact]
            public static void Lift_WithNone()
            {
                // Arrange
                var source = Thunk<AnyT>.Return(AnyResult.Value);
                // Act & Assert
                Assert.None(source.Lift(AnyT.None));
            }

            [Fact]
            public static void Lift_WithSome()
            {
                // Arrange
                var source = Thunk<AnyT>.Return(AnyResult.Value);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Lift(AnyT.Some));
            }

            [Fact]
            public static void Lift2_WithNullObject()
            {
                Assert.ThrowsAnexn("this", () =>
                    Funk<AnyT1, AnyT2, AnyResult>.Null
                        .Lift(AnyT1.Some, AnyT2.Some));
            }

            [Fact]
            public static void Lift2_WithNone()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2>.Return(AnyResult.Value);
                // Act & Assert
                Assert.None(source.Lift(AnyT1.None, AnyT2.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.None));
            }

            [Fact]
            public static void Lift2_WithSome()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2>.Return(AnyResult.Value);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Lift(AnyT1.Some, AnyT2.Some));
            }

            [Fact]
            public static void Lift3_WithNullObject()
            {
                Assert.ThrowsAnexn("this", () =>
                    Funk<AnyT1, AnyT2, AnyT3, AnyResult>.Null
                        .Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some));
            }

            [Fact]
            public static void Lift3_WithNone()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2, AnyT3>.Return(AnyResult.Value);
                // Act & Assert
                Assert.None(source.Lift(AnyT1.None, AnyT2.Some, AnyT3.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.None, AnyT3.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.None));
            }

            [Fact]
            public static void Lift3_WithSome()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2, AnyT3>.Return(AnyResult.Value);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some));
            }

            [Fact]
            public static void Lift4_WithNullObject()
            {
                Assert.ThrowsAnexn("this", () =>
                    Funk<AnyT1, AnyT2, AnyT3, AnyT4, AnyResult>.Null
                        .Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some));
            }

            [Fact]
            public static void Lift4_WithNone()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2, AnyT3, AnyT4>.Return(AnyResult.Value);
                // Act & Assert
                Assert.None(source.Lift(AnyT1.None, AnyT2.Some, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.None, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.None, AnyT4.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.None));
            }

            [Fact]
            public static void Lift4_WithSome()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2, AnyT3, AnyT4>.Return(AnyResult.Value);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some));
            }

            [Fact]
            public static void Lift5_WithNullObject()
            {
                Assert.ThrowsAnexn("this", () =>
                    Funk<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5, AnyResult>.Null
                        .Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
            }

            [Fact]
            public static void Lift5_WithNone()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5>.Return(AnyResult.Value);
                // Act & Assert
                Assert.None(source.Lift(AnyT1.None, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.None, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.None, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.None, AnyT5.Some));
                Assert.None(source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.None));
            }

            [Fact]
            public static void Lift5_WithSome()
            {
                // Arrange
                var source = Thunk<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5>.Return(AnyResult.Value);
                // Act & Assert
                Assert.Some(AnyResult.Value,
                    source.Lift(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
            }
        }

        // Helpers for Maybe<T> where T is a function.
        public static partial class MaybeHelper
        {
            #region Invoke()

            [Fact]
            public static void Invoke_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Invoke(AnyT.Value));
            }

            [Fact]
            public static void Invoke_Some()
            {
                // Arrange
                var f = Thunk<AnyT>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Invoke(AnyT.Value));
            }

            [Fact]
            public static void Invoke2_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Invoke(AnyT1.Value, AnyT2.Value));
            }

            [Fact]
            public static void Invoke2_Some()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Invoke(AnyT1.Value, AnyT2.Value));
            }

            [Fact]
            public static void Invoke3_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyT3, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Invoke(AnyT1.Value, AnyT2.Value, AnyT3.Value));
            }

            [Fact]
            public static void Invoke3_Some()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value,
                        source.Invoke(AnyT1.Value, AnyT2.Value, AnyT3.Value));
            }

            [Fact]
            public static void Invoke4_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyT3, AnyT4, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Invoke(AnyT1.Value, AnyT2.Value, AnyT3.Value, AnyT4.Value));
            }

            [Fact]
            public static void Invoke4_Some()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3, AnyT4>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value,
                    source.Invoke(AnyT1.Value, AnyT2.Value, AnyT3.Value, AnyT4.Value));
            }

            [Fact]
            public static void Invoke5_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Invoke(
                    AnyT1.Value, AnyT2.Value, AnyT3.Value, AnyT4.Value, AnyT5.Value));
            }

            [Fact]
            public static void Invoke5_Some()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value,
                    source.Invoke(AnyT1.Value, AnyT2.Value, AnyT3.Value, AnyT4.Value, AnyT5.Value));
            }

            #endregion

            #region Apply()

            [Fact]
            public static void Apply_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Apply(AnyT.None));
                Assert.None(source.Apply(AnyT.Some));
            }

            [Fact]
            public static void Apply_Some_WithNone()
            {
                // Arrange
                var f = Thunk<AnyT>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.None(source.Apply(AnyT.None));
            }

            [Fact]
            public static void Apply_Some_WithSome()
            {
                // Arrange
                var f = Thunk<AnyT>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Apply(AnyT.Some));
            }

            [Fact]
            public static void Apply2_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some));
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None));
            }

            [Fact]
            public static void Apply2_Some_WithNone()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None));
            }

            [Fact]
            public static void Apply2_Some_WithSome()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Apply(AnyT1.Some, AnyT2.Some));
            }

            [Fact]
            public static void Apply3_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyT3, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some));
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some, AnyT3.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None, AnyT3.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.None));
            }

            [Fact]
            public static void Apply3_Some_WithNone()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some, AnyT3.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None, AnyT3.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.None));
            }

            [Fact]
            public static void Apply3_Some_WithSome()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value, source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some));
            }

            [Fact]
            public static void Apply4_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyT3, AnyT4, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.None, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.None));
            }

            [Fact]
            public static void Apply4_Some_WithNone()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3, AnyT4>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None, AnyT3.Some, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.None, AnyT4.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.None));
            }

            [Fact]
            public static void Apply4_Some_WithSome()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3, AnyT4>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value,
                    source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some));
            }

            [Fact]
            public static void Apply5_None()
            {
                // Arrange
                var source = Maybe<Func<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5, AnyResult>>.None;
                // Act & Assert
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.None, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.None, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.None));
            }

            [Fact]
            public static void Apply5_Some_WithNone()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.None(source.Apply(AnyT1.None, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.None, AnyT3.Some, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.None, AnyT4.Some, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.None, AnyT5.Some));
                Assert.None(source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.None));
            }

            [Fact]
            public static void Apply5_Some_WithSome()
            {
                // Arrange
                var f = Thunk<AnyT1, AnyT2, AnyT3, AnyT4, AnyT5>.Return(AnyResult.Value);
                var source = Maybe.SomeOrNone(f);
                // Act & Assert
                Assert.Some(AnyResult.Value,
                    source.Apply(AnyT1.Some, AnyT2.Some, AnyT3.Some, AnyT4.Some, AnyT5.Some));
            }

            #endregion
        }
    }
}

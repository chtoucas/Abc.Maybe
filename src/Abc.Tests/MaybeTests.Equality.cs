// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;
    using System.Collections;
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

    // Equality.
    //
    // Expected algebraic properties.
    //   1) Reflexivity
    //   2) Symmetry
    //   3) Transitivity
    public partial class MaybeTests
    {
        [Fact]
        public static void Equality_None_ForValueT()
        {
            // Arrange
            var none = Maybe<int>.None;
            var same = Maybe<int>.None;
            var notSame = Maybe.Some(2);

            // Act & Assert
            Assert.True(none == same);
            Assert.True(same == none);
            Assert.False(none == notSame);
            Assert.False(notSame == none);

            Assert.False(none != same);
            Assert.False(same != none);
            Assert.True(none != notSame);
            Assert.True(notSame != none);

            Assert.True(none.Equals(none));
            Assert.True(none.Equals(same));
            Assert.True(same.Equals(none));
            Assert.False(none.Equals(notSame));
            Assert.False(notSame.Equals(none));

            Assert.True(none.Equals((object)same));
            Assert.False(none.Equals((object)notSame));

            Assert.False(none.Equals(null));
            Assert.False(none.Equals(new object()));
        }

        [Fact]
        public static void Equality_Some_ForValueT()
        {
            // Arrange
            var some = Maybe.Some(1);
            var same = Maybe.Some(1);
            var notSame = Maybe.Some(2);

            // Act & Assert
            Assert.True(some == same);
            Assert.True(same == some);
            Assert.False(some == notSame);
            Assert.False(notSame == some);

            Assert.False(some != same);
            Assert.False(same != some);
            Assert.True(some != notSame);
            Assert.True(notSame != some);

            Assert.True(some.Equals(some));
            Assert.True(some.Equals(same));
            Assert.True(same.Equals(some));
            Assert.False(some.Equals(notSame));
            Assert.False(notSame.Equals(some));

            Assert.True(some.Equals((object)same));
            Assert.False(some.Equals((object)notSame));

            Assert.False(some.Equals(null));
            Assert.False(some.Equals(new object()));
        }

        [Fact]
        public static void Equality_None_ForReferenceT()
        {
            // Arrange
            var none = Maybe<AnyT>.None;
            var same = Maybe<AnyT>.None;
            var notSame = Maybe.SomeOrNone(AnyT.Value);

            // Act & Assert
            Assert.True(none == same);
            Assert.True(same == none);
            Assert.False(none == notSame);
            Assert.False(notSame == none);

            Assert.False(none != same);
            Assert.False(same != none);
            Assert.True(none != notSame);
            Assert.True(notSame != none);

            Assert.True(none.Equals(none));
            Assert.True(none.Equals(same));
            Assert.True(same.Equals(none));
            Assert.False(none.Equals(notSame));
            Assert.False(notSame.Equals(none));

            Assert.True(none.Equals((object)same));
            Assert.False(none.Equals((object)notSame));

            Assert.False(none.Equals(null));
            Assert.False(none.Equals(new object()));
        }

        [Fact]
        public static void Equality_Some_ForReferenceT()
        {
            // Arrange
            var anyT = AnyT.Value;
            var some = Maybe.SomeOrNone(anyT);
            var same = Maybe.SomeOrNone(anyT);
            var notSame = Maybe.SomeOrNone(AnyT.Value);

            // Act & Assert
            Assert.True(some == same);
            Assert.True(same == some);
            Assert.False(some == notSame);
            Assert.False(notSame == some);

            Assert.False(some != same);
            Assert.False(same != some);
            Assert.True(some != notSame);
            Assert.True(notSame != some);

            Assert.True(some.Equals(some));
            Assert.True(some.Equals(same));
            Assert.True(same.Equals(some));
            Assert.False(some.Equals(notSame));
            Assert.False(notSame.Equals(some));

            Assert.True(some.Equals((object)same));
            Assert.False(some.Equals((object)notSame));

            Assert.False(some.Equals(null));
            Assert.False(some.Equals(new object()));
        }

        [Fact]
        public static void GetHashCode_None()
        {
            Assert.Equal(0, Ø.GetHashCode());
            Assert.Equal(0, ØL.GetHashCode());
            Assert.Equal(0, NoText.GetHashCode());
            Assert.Equal(0, NoUri.GetHashCode());
            Assert.Equal(0, AnyT.None.GetHashCode());
        }

        [Fact]
        public static void GetHashCode_Some()
        {
            Assert.Equal(1.GetHashCode(), One.GetHashCode());
            Assert.Equal(2.GetHashCode(), Two.GetHashCode());
            Assert.Equal(2L.GetHashCode(), TwoL.GetHashCode());
#if !(NETSTANDARD2_0 || NETSTANDARD1_x || NETFRAMEWORK) // GetHashCode(StringComparison)
            Assert.Equal(MyText.GetHashCode(StringComparison.Ordinal), SomeText.GetHashCode());
#endif
            Assert.Equal(MyUri.GetHashCode(), SomeUri.GetHashCode());

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value.GetHashCode(), anyT.Some.GetHashCode());
        }
    }

    // Structural equality.
    public partial class MaybeTests
    {
        // TODO: tests w/ IMaybe.
        public static partial class Structural
        {
            [Fact]
            public static void Equals_WithNullComparer()
            {
                // Arrange
                IStructuralEquatable one = One;
                // Act & Assert
                Assert.ThrowsAnexn("comparer", () => one.Equals(One, null!));
            }

            [Fact]
            public static void Equals_None_ForValueT()
            {
                // Arrange
                IStructuralEquatable none = Maybe<int>.None;
                var same = Maybe<int>.None;
                var some = Maybe.Some(2);
                var cmp = EqualityComparer<int>.Default;

                // Act & Assert
                Assert.False(none.Equals(null, cmp));
                Assert.False(none.Equals(new object(), cmp));

                Assert.True(none.Equals(none, cmp));
                Assert.True(none.Equals(same, cmp));

                Assert.False(none.Equals(some, cmp));
            }

            [Fact]
            public static void Equals_Some_ForValueT()
            {
                // Arrange
                IStructuralEquatable some = Maybe.Some(1);
                var same = Maybe.Some(1);
                var notSame = Maybe.Some(2);
                var none = Maybe<int>.None;
                var cmp = EqualityComparer<int>.Default;

                // Act & Assert
                Assert.False(some.Equals(null, cmp));
                Assert.False(some.Equals(new object(), cmp));

                Assert.True(some.Equals(some, cmp));
                Assert.True(some.Equals(same, cmp));
                Assert.False(some.Equals(notSame, cmp));

                Assert.False(some.Equals(none, cmp));
            }

            [Fact]
            public static void Equals_None_ForReferenceT()
            {
                // Arrange
                IStructuralEquatable none = Maybe<AnyT>.None;
                var same = Maybe<AnyT>.None;
                var some = Maybe.SomeOrNone(AnyT.Value);
                var cmp = EqualityComparer<AnyT>.Default;

                // Act & Assert
                Assert.False(none.Equals(null, cmp));
                Assert.False(none.Equals(new object(), cmp));

                Assert.True(none.Equals(none, cmp));
                Assert.True(none.Equals(same, cmp));

                Assert.False(none.Equals(some, cmp));
            }

            [Fact]
            public static void Equals_Some_ForReferenceT_WithDefaultComparer()
            {
                // Arrange
                var anyT = AnyT.Value;
                IStructuralEquatable some = Maybe.SomeOrNone(anyT);
                var same = Maybe.SomeOrNone(anyT);
                var notSame = Maybe.SomeOrNone(AnyT.Value);
                var none = Maybe<AnyT>.None;
                var cmp = EqualityComparer<AnyT>.Default;

                // Act & Assert
                Assert.False(some.Equals(null, cmp));
                Assert.False(some.Equals(new object(), cmp));

                Assert.True(some.Equals(some, cmp));
                Assert.True(some.Equals(same, cmp));
                Assert.False(some.Equals(notSame, cmp));

                Assert.False(some.Equals(none, cmp));
            }

            [Fact]
            public static void Equals_Some_ForReferenceT_WithCustomComparer()
            {
                // Arrange
                IStructuralEquatable anagram = Maybe.SomeOrNone(Anagram);
                var margana = Maybe.SomeOrNone(Margana);
                var other = Maybe.SomeOrNone("XXX");
                var none = Maybe<string>.None;
                var cmp = new AnagramEqualityComparer();

                // Act & Assert
                Assert.True(anagram.Equals(anagram));
                Assert.False(anagram.Equals(margana));
                Assert.False(anagram.Equals(other));
                Assert.False(anagram.Equals(none));
                Assert.False(anagram.Equals(new object()));

                Assert.True(anagram.Equals(anagram, cmp));
                Assert.True(anagram.Equals(margana, cmp));
                Assert.False(anagram.Equals(other, cmp));
                Assert.False(anagram.Equals(none, cmp));
                Assert.False(anagram.Equals(new object(), cmp));
                Assert.False(anagram.Equals(null, cmp));

                // REVIEW: very odd, after Equals(null), we must use !.
                Assert.False(anagram.Equals(null));
            }

            [Fact]
            public static void GetHashCode_WithNullComparer()
            {
                // Arrange
                IStructuralEquatable one = One;
                // Act & Assert
                Assert.ThrowsAnexn("comparer", () => one.GetHashCode(null!));
            }

            [Fact]
            public static void GetHashCode_None_WithDefaultComparer()
            {
                // Arrange
                var icmp = EqualityComparer<int>.Default;
                var lcmp = EqualityComparer<long>.Default;
                var scmp = EqualityComparer<string>.Default;
                var ucmp = EqualityComparer<Uri>.Default;
                var acmp = EqualityComparer<AnyT>.Default;
                // Act & Assert
                Assert.Equal(0, ((IStructuralEquatable)Ø).GetHashCode(icmp));
                Assert.Equal(0, ((IStructuralEquatable)ØL).GetHashCode(lcmp));
                Assert.Equal(0, ((IStructuralEquatable)NoText).GetHashCode(scmp));
                Assert.Equal(0, ((IStructuralEquatable)NoUri).GetHashCode(ucmp));
                Assert.Equal(0, ((IStructuralEquatable)AnyT.None).GetHashCode(acmp));
            }

            [Fact]
            public static void GetHashCode_None_WithCustomComparer()
            {
                // Arrange
                var cmp = new AnagramEqualityComparer();
                // Act & Assert
                Assert.Equal(0, ((IStructuralEquatable)NoText).GetHashCode(cmp));
            }

            [Fact]
            public static void GetHashCode_Some_WithDefaultComparer()
            {
                // Arrange
                var icmp = EqualityComparer<int>.Default;
                var lcmp = EqualityComparer<long>.Default;
                var scmp = EqualityComparer<string>.Default;
                var ucmp = EqualityComparer<Uri>.Default;
                var acmp = EqualityComparer<AnyT>.Default;
                // Act & Assert
                Assert.Equal(icmp.GetHashCode(1), ((IStructuralEquatable)One).GetHashCode(icmp));
                Assert.Equal(icmp.GetHashCode(2), ((IStructuralEquatable)Two).GetHashCode(icmp));
                Assert.Equal(lcmp.GetHashCode(2L), ((IStructuralEquatable)TwoL).GetHashCode(lcmp));
                Assert.Equal(scmp.GetHashCode(MyText), ((IStructuralEquatable)SomeText).GetHashCode(scmp));
                Assert.Equal(ucmp.GetHashCode(MyUri), ((IStructuralEquatable)SomeUri).GetHashCode(ucmp));

                var anyT = AnyT.New();
                Assert.Equal(acmp.GetHashCode(anyT.Value), ((IStructuralEquatable)anyT.Some).GetHashCode(acmp));
            }

            [Fact]
            public static void GetHashCode_Some_WithCustomComparer()
            {
                // Arrange
                var cmp = new AnagramEqualityComparer();
                // Act & Assert
                Assert.Equal(cmp.GetHashCode(MyText), ((IStructuralEquatable)SomeText).GetHashCode(cmp));
            }
        }
    }

    // Equality w/ composite objects.
    public partial class MaybeTests
    {
        [Fact]
        public static void Equality_CompositeObject()
        {
            // Arrange
            var v1 = AnyT.Value;
            var v2 = AnyT.Value;
            var v3 = AnyT.Value;
            var v4 = AnyT.Value;
            var xs = new List<Maybe<AnyT>>
            {
                Maybe.SomeOrNone(v1),
                Maybe.SomeOrNone(v2),
                Maybe.SomeOrNone(v3),
                Maybe.SomeOrNone(v4),
            };
            var ys = new List<Maybe<AnyT>>
            {
                Maybe.SomeOrNone(v1),
                Maybe.SomeOrNone(v2),
                Maybe.SomeOrNone(v3),
                Maybe.SomeOrNone(v4),
            };
            // Assert
            // The object references are different.
            Assert.NotSame(xs, ys);
            // The objets are different too using the types's default comparer.
            Assert.NotStrictEqual(xs, ys);
            // The objets are equal using the default comparer.
            Assert.Equal(xs, ys);
        }
    }
}

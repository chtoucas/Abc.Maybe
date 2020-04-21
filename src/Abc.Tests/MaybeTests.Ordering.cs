// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections;
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

    // Order comparison.
    //
    // Expected algebraic properties.
    //   1) Reflexivity     x <= x
    //   2) Anti-symmetry   (x <= y and y <= x) => x = y
    //   3) Transitivity    (x <= y and y <= z) => x <= z
    //
    // Beware, <= does NOT define a proper ordering when none is included.
    public partial class MaybeTests
    {
        #region Comparison ops

        [Fact]
        public static void OpComparison_None_None_ReturnsFalse()
        {
            // Arrange
            Maybe<int> none = Ø;
            // Act & Assert
            Assert.False(none < Ø);
            Assert.False(none <= Ø);
            Assert.False(none > Ø);
            Assert.False(none >= Ø);
        }

        [Fact]
        public static void OpComparison_None_None_ReturnsFalse_ForNotComparable()
        {
            // Arrange
            var none = AnyT.None;
            // Act & Assert
            Assert.False(none < AnyT.None);
            Assert.False(none <= AnyT.None);
            Assert.False(none > AnyT.None);
            Assert.False(none >= AnyT.None);
        }

        [Fact]
        public static void OpComparison_None_Some_ReturnsFalse()
        {
            Assert.False(Ø < One);
            Assert.False(Ø <= One);
            Assert.False(Ø > One);
            Assert.False(Ø >= One);

            Assert.False(One < Ø);
            Assert.False(One <= Ø);
            Assert.False(One > Ø);
            Assert.False(One >= Ø);
        }

        [Fact]
        public static void OpComparison_None_Some_ReturnsFalse_ForNotComparable()
        {
            // Arrange
            var some = AnyT.Some;

            // Act & Assert
            Assert.False(AnyT.None < some);
            Assert.False(AnyT.None <= some);
            Assert.False(AnyT.None > some);
            Assert.False(AnyT.None >= some);

            Assert.False(some < AnyT.None);
            Assert.False(some <= AnyT.None);
            Assert.False(some > AnyT.None);
            Assert.False(some >= AnyT.None);
        }

        [Fact]
        public static void OpComparison_Some_Some_WhenEqual()
        {
            // Arrange
            var one = Maybe.Some(1);
            // Act & Assert
            Assert.False(One < one);
            Assert.True(One <= one);
            Assert.False(One > one);
            Assert.True(One >= one);
        }

        [Fact]
        public static void OpComparison_Some_Some_WhenEqual_ForNotComparable()
        {
            // Arrange
            var anyT = AnyT.Value;
            var x = Maybe.SomeOrNone(anyT);
            var y = Maybe.SomeOrNone(anyT);
            // Act & Assert
            Assert.False(x < y);
            Assert.True(x <= y);
            Assert.False(x > y);
            Assert.True(x >= y);
        }

        [Fact]
        public static void OpComparison_Some_Some_WhenNotEqual()
        {
            Assert.True(One < Two);
            Assert.True(One <= Two);
            Assert.False(One > Two);
            Assert.False(One >= Two);

            Assert.False(Two < One);
            Assert.False(Two <= One);
            Assert.True(Two > One);
            Assert.True(Two >= One);
        }

        [Fact]
        public static void OpComparison_Some_Some_WhenNotEqual_Throws_ForNotComparable()
        {
            // Arrange
            var x = AnyT.Some;
            var y = AnyT.Some;
            // Act & Assert
            Assert.ThrowsArgexn(() => x < y);
            Assert.ThrowsArgexn(() => x <= y);
            Assert.ThrowsArgexn(() => x > y);
            Assert.ThrowsArgexn(() => x >= y);
        }

        #endregion

        #region CompareTo()

        [Fact]
        public static void CompareTo_None_WithNone() => Assert.Equal(0, Ø.CompareTo(Ø));

        [Fact]
        public static void CompareTo_None_WithNone_ForNotComparable() =>
            Assert.Equal(0, AnyT.None.CompareTo(AnyT.None));

        [Fact]
        public static void CompareTo_None_WithSome() => Assert.Equal(-1, Ø.CompareTo(One));

        [Fact]
        public static void CompareTo_None_WithSome_ForNotComparable() =>
            Assert.Equal(-1, AnyT.None.CompareTo(AnyT.Some));

        [Fact]
        public static void CompareTo_Some_WithNone() => Assert.Equal(1, One.CompareTo(Ø));

        [Fact]
        public static void CompareTo_Some_WithNone_ForNotComparable() =>
            Assert.Equal(1, AnyT.Some.CompareTo(AnyT.None));

        [Fact]
        public static void CompareTo_Some_WithSome_AndEqual() => Assert.Equal(0, One.CompareTo(One));

        [Fact]
        public static void CompareTo_Some_WithSome_AndEqual_ForNotComparable()
        {
            // Arrange
            var anyT = AnyT.Value;
            var x = Maybe.SomeOrNone(anyT);
            var y = Maybe.SomeOrNone(anyT);
            // Act & Assert
            Assert.Equal(0, x.CompareTo(y));
        }

        [Fact]
        public static void CompareTo_Some_WithSome_AndNotEqual()
        {
            Assert.Equal(1, Two.CompareTo(One));
            Assert.Equal(-1, One.CompareTo(Two));
        }

        [Fact]
        public static void CompareTo_Some_WithSome_AndNotEqual_Throws_ForNotComparable() =>
            Assert.ThrowsArgexn(() => AnyT.Some.CompareTo(AnyT.Some));

        #endregion

        #region CompareTo() from IComparable

        [Fact]
        public static void Comparable_None_WithNull()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.Equal(1, none.CompareTo(null));
        }

        [Fact]
        public static void Comparable_Some_WithNull()
        {
            // Arrange
            IComparable one = One;
            // Act & Assert
            Assert.Equal(1, one.CompareTo(null));
        }

        [Fact]
        public static void Comparable_None_Throws_WithInvalidType()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.ThrowsArgexn("obj", () => none.CompareTo(new object()));
            Assert.ThrowsArgexn("obj", () => none.CompareTo(NoText));
            Assert.ThrowsArgexn("obj", () => none.CompareTo(SomeText));
        }

        [Fact]
        public static void Comparable_Some_Throws_WithInvalidType()
        {
            // Arrange
            IComparable one = One;
            // Act & Assert
            Assert.ThrowsArgexn("obj", () => one.CompareTo(new object()));
            Assert.ThrowsArgexn("obj", () => one.CompareTo(NoText));
            Assert.ThrowsArgexn("obj", () => one.CompareTo(SomeText));
        }

        [Fact]
        public static void Comparable_None_WithNone()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.Equal(0, none.CompareTo(Ø));
        }

        [Fact]
        public static void Comparable_None_WithNone_ForNotComparable()
        {
            // Arrange
            IComparable none = AnyT.None;
            // Act & Assert
            Assert.Equal(0, none.CompareTo(AnyT.None));
        }

        [Fact]
        public static void Comparable_None_WithSome()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.Equal(-1, none.CompareTo(One));
            Assert.Equal(-1, none.CompareTo(Two));
        }

        [Fact]
        public static void Comparable_None_WithSome_ForNotComparable()
        {
            // Arrange
            IComparable none = AnyT.None;
            // Act & Assert
            Assert.Equal(-1, none.CompareTo(AnyT.Some));
        }

        [Fact]
        public static void Comparable_Some_WithNone()
        {
            // Arrange
            IComparable one = One;
            IComparable two = Two;
            // Act & Assert
            Assert.Equal(1, one.CompareTo(Ø));
            Assert.Equal(1, two.CompareTo(Ø));
        }

        [Fact]
        public static void Comparable_Some_WithNone_ForNotComparable()
        {
            // Arrange
            IComparable some = AnyT.Some;
            // Act & Assert
            Assert.Equal(1, some.CompareTo(AnyT.None));
        }

        [Fact]
        public static void Comparable_Some_WithSome_AndEqual()
        {
            // Arrange
            IComparable one = One;
            // Act & Assert
            Assert.Equal(0, one.CompareTo(One));
        }

        [Fact]
        public static void Comparable_Some_WithSome_AndEqual_ForNotComparable()
        {
            // Arrange
            var anyT = AnyT.Value;
            IComparable x = Maybe.SomeOrNone(anyT);
            var y = Maybe.SomeOrNone(anyT);
            // Act & Assert
            Assert.Equal(0, x.CompareTo(y));
        }

        [Fact]
        public static void Comparable_Some_WithSome_AndNotEqual()
        {
            // Arrange
            IComparable one = One;
            IComparable two = Two;
            // Act & Assert
            Assert.Equal(-1, one.CompareTo(Two));
            Assert.Equal(1, two.CompareTo(One));
        }

        [Fact]
        public static void Comparable_Some_WithSome_AndNotEqual_Throws_ForNotComparable()
        {
            // Arrange
            IComparable some = AnyT.Some;
            // Act & Assert
            Assert.ThrowsArgexn(() => some.CompareTo(AnyT.Some));
        }

        #endregion
    }

    // Structural comparisons.
    public partial class MaybeTests
    {
        // Ordering.
        public static partial class Structural
        {
            [Fact]
            public static void CompareTo_None_WithNullComparer()
            {
                // Arrange
                IStructuralComparable none = Ø;
                // Act & Assert
                Assert.ThrowsAnexn("comparer", () => none.CompareTo(One, null!));
            }

            [Fact]
            public static void CompareTo_Some_WithNullComparer()
            {
                // Arrange
                IStructuralComparable one = One;
                // Act & Assert
                Assert.ThrowsAnexn("comparer", () => one.CompareTo(One, null!));
            }

            [Fact]
            public static void CompareTo()
            {
                // Arrange
                var cmp = Comparer<int>.Default;
                IStructuralComparable none = Ø;
                IStructuralComparable one = One;
                IStructuralComparable two = Two;

                // Act & Assert
                Assert.ThrowsArgexn("other", () => none.CompareTo(new object(), cmp));
                Assert.ThrowsArgexn("other", () => one.CompareTo(new object(), cmp));

                Assert.Equal(1, none.CompareTo(null, cmp));
                Assert.Equal(1, one.CompareTo(null, cmp));

                // With None
                Assert.Equal(1, one.CompareTo(Ø, cmp));
                Assert.Equal(-1, none.CompareTo(One, cmp));
                Assert.Equal(0, none.CompareTo(Ø, cmp));

                // Without None
                Assert.Equal(1, two.CompareTo(One, cmp));
                Assert.Equal(0, one.CompareTo(One, cmp));
                Assert.Equal(-1, one.CompareTo(Two, cmp));
            }
        }
    }
}

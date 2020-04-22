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
        public static void OpComparison_Some_Some_WhenNotEqual_ForNotComparable_Throws()
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

        // If we add/update tests here, do the same w/ IComparable.CompareTo()
        // and IStructuralComparable.CompareTo().

        [Fact]
        public static void CompareTo_None_WithNone() => Assert.Equal(0, Ø.CompareTo(Ø));

        [Fact]
        public static void CompareTo_None_WithNone_ForNotComparable() =>
            Assert.Equal(0, AnyT.None.CompareTo(AnyT.None));

        [Fact]
        public static void CompareTo_None_WithSome()
        {
            Assert.Equal(-1, Ø.CompareTo(One));
            Assert.Equal(-1, Ø.CompareTo(Two));
        }

        [Fact]
        public static void CompareTo_None_WithSome_ForNotComparable() =>
            Assert.Equal(-1, AnyT.None.CompareTo(AnyT.Some));

        [Fact]
        public static void CompareTo_Some_WithNone()
        {
            Assert.Equal(1, One.CompareTo(Ø));
            Assert.Equal(1, Two.CompareTo(Ø));
        }

        [Fact]
        public static void CompareTo_Some_WithNone_ForNotComparable() =>
            Assert.Equal(1, AnyT.Some.CompareTo(AnyT.None));

        [Fact]
        public static void CompareTo_Some_WithSome_AndEqual()
        {
            Assert.Equal(0, One.CompareTo(One));
            Assert.Equal(0, Two.CompareTo(Two));
        }

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
        public static void CompareTo_Some_WithSome_AndNotEqual_ForNotComparable_Throws() =>
            Assert.ThrowsArgexn(() => AnyT.Some.CompareTo(AnyT.Some));

        #endregion

        #region IComparable.CompareTo()

        // If we add/update tests here, do the same w/ CompareTo() and
        // IStructuralComparable.CompareTo().

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

        //
        // What follows is "identical" to what we do w/ CompareTo().
        //

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
        public static void Comparable_Some_WithSome_AndNotEqual_ForNotComparable_Throws()
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
        // Tests identical to the those written for IComparable.CompareTo().
        // 1) If we add/update tests here, do the same w/ CompareTo() and
        //    IComparable.CompareTo().
        // 2) Use AnyComparer when any comparer will do the job.
        public static partial class Structural
        {
            [Fact]
            public static void Comparable_None_WithNull()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable none = Ø;
                // Act & Assert
                Assert.Equal(1, none.CompareTo(null, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithNull()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable one = One;
                // Act & Assert
                Assert.Equal(1, one.CompareTo(null, cmp));
            }

            [Fact]
            public static void Comparable_None_Throws_WithInvalidType()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable none = Ø;
                // Act & Assert
#if NONGENERIC_MAYBE
                Assert.ThrowsArgexn("other", () => none.CompareTo(new object(), cmp));
                Assert.Equal(0, none.CompareTo(NoText, cmp));
                Assert.Equal(-1, none.CompareTo(SomeText, cmp));
#else
                Assert.ThrowsArgexn("other", () => none.CompareTo(new object(), cmp));
                Assert.ThrowsArgexn("other", () => none.CompareTo(NoText, cmp));
                Assert.ThrowsArgexn("other", () => none.CompareTo(SomeText, cmp));
#endif
            }

            [Fact]
            public static void Comparable_Some_Throws_WithInvalidType()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable one = One;
                // Act & Assert
#if NONGENERIC_MAYBE
                Assert.ThrowsArgexn("other", () => one.CompareTo(new object(), cmp));
                Assert.Equal(1, one.CompareTo(NoText, cmp));
                Assert.Throws<UnexpectedCallException>(() => one.CompareTo(SomeText, cmp));
#else
                Assert.ThrowsArgexn("other", () => one.CompareTo(new object(), cmp));
                Assert.ThrowsArgexn("other", () => one.CompareTo(NoText, cmp));
                Assert.ThrowsArgexn("other", () => one.CompareTo(SomeText, cmp));
#endif
            }

            [Fact]
            public static void Comparable_None_WithNone()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable none = Ø;
                // Act & Assert
                Assert.Equal(0, none.CompareTo(Ø, cmp));
            }

            [Fact]
            public static void Comparable_None_WithNone_ForNotComparable()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable none = AnyT.None;
                // Act & Assert
                Assert.Equal(0, none.CompareTo(AnyT.None, cmp));
            }

            [Fact]
            public static void Comparable_None_WithSome()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable none = Ø;
                // Act & Assert
                Assert.Equal(-1, none.CompareTo(One, cmp));
                Assert.Equal(-1, none.CompareTo(Two, cmp));
            }

            [Fact]
            public static void Comparable_None_WithSome_ForNotComparable()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable none = AnyT.None;
                // Act & Assert
                Assert.Equal(-1, none.CompareTo(AnyT.Some, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithNone()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable one = One;
                IStructuralComparable two = Two;
                // Act & Assert
                Assert.Equal(1, one.CompareTo(Ø, cmp));
                Assert.Equal(1, two.CompareTo(Ø, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithNone_ForNotComparable()
            {
                // Arrange
                var cmp = new AnyComparer();
                IStructuralComparable some = AnyT.Some;
                // Act & Assert
                Assert.Equal(1, some.CompareTo(AnyT.None, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual()
            {
                // Arrange
                var cmp = Comparer<int>.Default;
                IStructuralComparable one = One;
                // Act & Assert
                Assert.Equal(0, one.CompareTo(One, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual_ForNotComparable()
            {
                // Arrange
                var cmp = Comparer<AnyT>.Default;
                var anyT = AnyT.Value;
                IStructuralComparable x = Maybe.SomeOrNone(anyT);
                var y = Maybe.SomeOrNone(anyT);
                // Act & Assert
                Assert.Equal(0, x.CompareTo(y, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual()
            {
                // Arrange
                var cmp = Comparer<int>.Default;
                IStructuralComparable one = One;
                IStructuralComparable two = Two;
                // Act & Assert
                Assert.Equal(-1, one.CompareTo(Two, cmp));
                Assert.Equal(1, two.CompareTo(One, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_ForNotComparable_Throws()
            {
                // Arrange
                var cmp = Comparer<AnyT>.Default;
                IStructuralComparable some = AnyT.Some;
                // Act & Assert
                Assert.ThrowsArgexn(() => some.CompareTo(AnyT.Some, cmp));
            }
        }

        // Specific tests.
        public static partial class Structural
        {
            [Fact]
            public static void Comparable_None_WithNullComparer()
            {
                // Arrange
                IStructuralComparable none = Ø;
                // Act & Assert
                Assert.ThrowsAnexn("comparer", () => none.CompareTo(One, null!));
            }

            [Fact]
            public static void Comparable_Some_WithNullComparer()
            {
                // Arrange
                IStructuralComparable one = One;
                // Act & Assert
                Assert.ThrowsAnexn("comparer", () => one.CompareTo(One, null!));
            }

            //
            // The custom comparer (IComparer) does get called!
            //

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual_CallsComparer()
            {
                // Arrange
                IStructuralComparable one = One;
                // Act & Assert
                Assert.Throws<UnexpectedCallException>(() => one.CompareTo(One, new AnyComparer()));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual_ForNotComparable_CallsComparer()
            {
                // Arrange
                var anyT = AnyT.Value;
                IStructuralComparable x = Maybe.SomeOrNone(anyT);
                var y = Maybe.SomeOrNone(anyT);
                // Act & Assert
                Assert.Throws<UnexpectedCallException>(() => x.CompareTo(y, new AnyComparer()));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_CallsComparer()
            {
                // Arrange
                IStructuralComparable one = One;
                // Act & Assert
                Assert.Throws<UnexpectedCallException>(() => one.CompareTo(Two, new AnyComparer()));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_ForNotComparable_CallsComparer()
            {
                // Arrange
                IStructuralComparable some = AnyT.Some;
                // Act & Assert
                Assert.Throws<UnexpectedCallException>(() => some.CompareTo(AnyT.Some, new AnyComparer()));
            }

            //
            // The custom comparer (IComparer<T>) must be compatible with the underlying type.
            //

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual_Throws_WithNotCompatibleComparer()
            {
                // Arrange
                var cmp = Comparer<AnyT>.Default;
                IStructuralComparable one = One;
                // Act & Assert
                Assert.ThrowsArgexn(() => one.CompareTo(One, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual_ForNotComparable_Throws_WithNotCompatibleComparer()
            {
                // Arrange
                var cmp = Comparer<int>.Default;
                var anyT = AnyT.Value;
                IStructuralComparable x = Maybe.SomeOrNone(anyT);
                var y = Maybe.SomeOrNone(anyT);
                // Act & Assert
                Assert.ThrowsArgexn(() => x.CompareTo(y, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_Throws_WithNotCompatibleComparer()
            {
                // Arrange
                var cmp = Comparer<AnyT>.Default;
                IStructuralComparable one = One;
                // Act & Assert
                Assert.ThrowsArgexn(() => one.CompareTo(Two, cmp));
            }

            // NB: actually identical to
            /// <seealso cref="Comparable_Some_WithSome_AndNotEqual_ForNotComparable_Throws"/>
            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_ForNotComparable_Throws_WithNotCompatibleComparer()
            {
                // Arrange
                var cmp = Comparer<int>.Default;
                IStructuralComparable some = AnyT.Some;
                // Act & Assert
                Assert.ThrowsArgexn(() => some.CompareTo(AnyT.Some, cmp));
            }

            //
            // TODO: Using a custom comparer.
            //

            [Fact]
            public static void Comparable_Some_WithSome_AndEqual_WithCustomComparer()
            {
                // Arrange
                var cmp = new ReversedLengthComparer();
                IStructuralComparable x = SomeText;
                var y = SomeText;
                // Act & Assert
                Assert.Equal(0, x.CompareTo(y, cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_WithCustomComparer_ForString()
            {
                // Arrange
                var cmp = new ReversedLengthComparer();
                IStructuralComparable x = Maybe.SomeOrNone("XXX");
                // Act & Assert
                Assert.Equal(-1, x.CompareTo(Maybe.SomeOrNone(""), cmp));
                Assert.Equal(-1, x.CompareTo(Maybe.SomeOrNone("Y"), cmp));
                Assert.Equal(-1, x.CompareTo(Maybe.SomeOrNone("YY"), cmp));
                Assert.Equal(0, x.CompareTo(Maybe.SomeOrNone("YYY"), cmp));
                Assert.Equal(1, x.CompareTo(Maybe.SomeOrNone("YYYY"), cmp));
                Assert.Equal(1, x.CompareTo(Maybe.SomeOrNone("YYYYY"), cmp));
                Assert.Equal(1, x.CompareTo(Maybe.SomeOrNone("YYYYYY"), cmp));
            }

            [Fact]
            public static void Comparable_Some_WithSome_AndNotEqual_WithCustomComparer_ForDouble()
            {
                // Arrange
                var cmp = new ReversedNaNComparer();
                var other = new ReversedLengthComparer();
                var x = Maybe.Some(Double.NaN);
                var y = Maybe.Some(1d);

                // Act & Assert
                Assert.Equal(-1, x.CompareTo(y));
                Assert.Equal(-1, ((IStructuralComparable)x).CompareTo(y, other));
                Assert.Equal(1, ((IStructuralComparable)x).CompareTo(y, cmp));

                Assert.Equal(1, y.CompareTo(x));
                Assert.Equal(1, ((IStructuralComparable)y).CompareTo(x, other));
                Assert.Equal(-1, ((IStructuralComparable)y).CompareTo(x, cmp));
            }

#if NONGENERIC_MAYBE
            [Fact]
#else
            [Fact(Skip = "WIP")]
#endif
            public static void Comparable_Some_WithSome_AndNotEqual_WithCustomComparer_Hybrid()
            {
                // Arrange
                var cmp = new ReversedNaNComparer();
                //var other = new ReversedLengthComparer();
                var x = Maybe.Some(Double.NaN);
                var y = Maybe.Some(1f);

                // Act & Assert
                //Assert.Equal(-1, ((IStructuralComparable)x).CompareTo(y, other));
                Assert.Equal(1, ((IStructuralComparable)x).CompareTo(y, cmp));

                //Assert.Equal(1, ((IStructuralComparable)y).CompareTo(x, other));
                Assert.Equal(-1, ((IStructuralComparable)y).CompareTo(x, cmp));
            }
        }
    }
}

// See LICENSE in the project root for license information.

namespace Abc
{
    using Xunit;

    using Assert = AssertEx;

    // "Bitwise" logical operations.
    public partial class MaybeTests
    {
        [Fact]
        public static void OrElse()
        {
            // Some Some -> Some
            Assert.Equal(One, One.OrElse(Two));
            // Some None -> Some
            Assert.Equal(One, One.OrElse(Ø));
            // None Some -> Some
            Assert.Equal(Two, Ø.OrElse(Two));
            // None None -> None
            Assert.Equal(Ø, Ø.OrElse(Ø));

            // OrElse() is OrElseRTL() flipped.
            Assert.Equal(One, Two.OrElseRTL(One));
            Assert.Equal(One, Ø.OrElseRTL(One));
            Assert.Equal(Two, Two.OrElseRTL(Ø));
            Assert.Equal(Ø, Ø.OrElseRTL(Ø));
        }

        [Fact]
        public static void AndThen()
        {
            // Some Some -> Some
            Assert.Equal(TwoL, One.AndThen(TwoL));
            // Some None -> None
            Assert.Equal(ØL, One.AndThen(ØL));
            // None Some -> None
            Assert.Equal(ØL, Ø.AndThen(TwoL));
            // None None -> None
            Assert.Equal(ØL, Ø.AndThen(ØL));

            // AndThen() is AndThenRTL() flipped.
            Assert.Equal(TwoL, TwoL.AndThenRTL(One));
            Assert.Equal(ØL, ØL.AndThenRTL(One));
            Assert.Equal(ØL, TwoL.AndThenRTL(Ø));
            Assert.Equal(ØL, ØL.AndThenRTL(Ø));
        }

        [Fact]
        public static void XorElse()
        {
            // Some Some -> None
            Assert.Equal(Ø, One.XorElse(Two));
            // Some None -> Some
            Assert.Equal(One, One.XorElse(Ø));
            // None Some -> Some
            Assert.Equal(Two, Ø.XorElse(Two));
            // None None -> None
            Assert.Equal(Ø, Ø.XorElse(Ø));

            // XorElse() flips to itself.
            Assert.Equal(Ø, Two.XorElse(One));
            Assert.Equal(One, Ø.XorElse(One));
            Assert.Equal(Two, Two.XorElse(Ø));
            Assert.Equal(Ø, Ø.XorElse(Ø));
        }

        [Fact]
        public static void BitwiseOr()
        {
            // Some Some -> Some
            Assert.Equal(One, One | Two);
            Assert.Equal(Two, Two | One);   // non-abelian
            // Some None -> Some
            Assert.Equal(One, One | Ø);
            // None Some -> Some
            Assert.Equal(Two, Ø | Two);
            // None None -> None
            Assert.Equal(Ø, Ø | Ø);

            Assert.LogicalTrue(One | Two);
            Assert.LogicalTrue(One | Ø);
            Assert.LogicalTrue(Ø | Two);
            Assert.LogicalFalse(Ø | Ø);
        }

        [Fact]
        public static void BitwiseAnd()
        {
            // Some Some -> Some
            Assert.Equal(Two, One & Two);
            Assert.Equal(One, Two & One);   // non-abelian
            // Some None -> None
            Assert.Equal(Ø, One & Ø);
            // None Some -> None
            Assert.Equal(Ø, Ø & Two);
            // None None -> None
            Assert.Equal(Ø, Ø & Ø);

            Assert.LogicalTrue(One & Two);
            Assert.LogicalFalse(One & Ø);
            Assert.LogicalFalse(Ø & Two);
            Assert.LogicalFalse(Ø & Ø);
        }

        [Fact]
        public static void ExclusiveOr()
        {
            // Some Some -> None
            Assert.Equal(Ø, One ^ Two);
            Assert.Equal(Ø, Two ^ One);     // abelian
            // Some None -> Some
            Assert.Equal(One, One ^ Ø);
            // None Some -> Some
            Assert.Equal(Two, Ø ^ Two);
            // None None -> None
            Assert.Equal(Ø, Ø ^ Ø);

            Assert.LogicalFalse(One ^ Two);
            Assert.LogicalTrue(One ^ Ø);
            Assert.LogicalTrue(Ø ^ Two);
            Assert.LogicalFalse(Ø ^ Ø);
        }
    }

    // In Future.
    public partial class MaybeTests
    {
        [Fact]
        public static void OrElseRTL()
        {
            // Some Some -> Some
            Assert.Equal(Two, One.OrElseRTL(Two));
            // Some None -> Some
            Assert.Equal(One, One.OrElseRTL(Ø));
            // None Some -> Some
            Assert.Equal(Two, Ø.OrElseRTL(Two));
            // None None -> None
            Assert.Equal(Ø, Ø.OrElseRTL(Ø));

            // OrElseRTL() is OrElse() flipped.
            Assert.Equal(Two, Two.OrElse(One));
            Assert.Equal(One, Ø.OrElse(One));
            Assert.Equal(Two, Two.OrElse(Ø));
            Assert.Equal(Ø, Ø.OrElse(Ø));
        }

        [Fact]
        public static void AndThenRTL()
        {
            // Some Some -> Some
            Assert.Equal(One, One.AndThenRTL(TwoL));
            // Some None -> None
            Assert.Equal(Ø, One.AndThenRTL(ØL));
            // None Some -> None
            Assert.Equal(Ø, Ø.AndThenRTL(TwoL));
            // None None -> None
            Assert.Equal(Ø, Ø.AndThenRTL(ØL));

            // AndThenRTL() is AndThen() flipped.
            Assert.Equal(One, TwoL.AndThen(One));
            Assert.Equal(Ø, ØL.AndThen(One));
            Assert.Equal(Ø, TwoL.AndThen(Ø));
            Assert.Equal(Ø, ØL.AndThen(Ø));
        }

        [Fact]
        public static void Unless()
        {
            // Some Some -> None
            Assert.Equal(Ø, One.Unless(TwoL));
            // Some None -> Some
            Assert.Equal(One, One.Unless(ØL));
            // None Some -> None
            Assert.Equal(Ø, Ø.Unless(TwoL));
            // None None -> None
            Assert.Equal(Ø, Ø.Unless(ØL));

            // Unless() is UnlessRTL() flipped.
            Assert.Equal(Ø, TwoL.UnlessRTL(One));
            Assert.Equal(One, ØL.UnlessRTL(One));
            Assert.Equal(Ø, TwoL.UnlessRTL(Ø));
            Assert.Equal(Ø, ØL.UnlessRTL(Ø));

            // Logic behaviour.
            Assert.LogicalFalse(One.Unless(TwoL));
            Assert.LogicalTrue(One.Unless(ØL));
            Assert.LogicalFalse(Ø.Unless(TwoL));
            Assert.LogicalFalse(Ø.Unless(ØL));
        }

        [Fact]
        public static void UnlessRTL()
        {
            // Some Some -> None
            Assert.Equal(ØL, One.UnlessRTL(TwoL));
            // Some None -> None
            Assert.Equal(ØL, One.UnlessRTL(ØL));
            // None Some -> Some
            Assert.Equal(TwoL, Ø.UnlessRTL(TwoL));
            // None None -> None
            Assert.Equal(ØL, Ø.UnlessRTL(ØL));

            // UnlessRTL() is Unless() flipped.
            Assert.Equal(ØL, TwoL.Unless(One));
            Assert.Equal(ØL, ØL.Unless(One));
            Assert.Equal(TwoL, TwoL.Unless(Ø));
            Assert.Equal(ØL, ØL.Unless(Ø));

            // Logic behaviour.
            Assert.LogicalFalse(One.UnlessRTL(TwoL));
            Assert.LogicalFalse(One.UnlessRTL(ØL));
            Assert.LogicalTrue(Ø.UnlessRTL(TwoL));
            Assert.LogicalFalse(Ø.UnlessRTL(ØL));
        }

        [Fact]
        public static void LeftAnd()
        {
            // Some Some -> Some
            Assert.Equal(One, MaybeEx.LeftAnd(One, Two));
            // Some None -> None
            Assert.Equal(Ø, MaybeEx.LeftAnd(One, Ø));
            // None Some -> Some
            Assert.Equal(Two, MaybeEx.LeftAnd(Ø, Two));
            // None None -> None
            Assert.Equal(Ø, MaybeEx.LeftAnd(Ø, Ø));

            // LeftAnd() is RightAnd() flipped.
            Assert.Equal(One, MaybeEx.RightAnd(Two, One));
            Assert.Equal(Ø, MaybeEx.RightAnd(Ø, One));
            Assert.Equal(Two, MaybeEx.RightAnd(Two, Ø));
            Assert.Equal(Ø, MaybeEx.RightAnd(Ø, Ø));

            // Logic behaviour.
            Assert.LogicalTrue(MaybeEx.LeftAnd(One, Two));
            Assert.LogicalFalse(MaybeEx.LeftAnd(One, Ø));
            Assert.LogicalTrue(MaybeEx.LeftAnd(Ø, Two));
            Assert.LogicalFalse(MaybeEx.LeftAnd(Ø, Ø));
        }

        [Fact]
        public static void RightAnd()
        {
            // Some Some -> Some
            Assert.Equal(Two, MaybeEx.RightAnd(One, Two));
            // Some None -> Some
            Assert.Equal(One, MaybeEx.RightAnd(One, Ø));
            // None Some -> None
            Assert.Equal(Ø, MaybeEx.RightAnd(Ø, Two));
            // None None -> None
            Assert.Equal(Ø, MaybeEx.RightAnd(Ø, Ø));

            // RightAnd() is LeftAnd() flipped.
            Assert.Equal(Two, MaybeEx.LeftAnd(Two, One));
            Assert.Equal(One, MaybeEx.LeftAnd(Ø, One));
            Assert.Equal(Ø, MaybeEx.LeftAnd(Two, Ø));
            Assert.Equal(Ø, MaybeEx.LeftAnd(Ø, Ø));

            // Logic behaviour.
            Assert.LogicalTrue(MaybeEx.RightAnd(One, Two));
            Assert.LogicalTrue(MaybeEx.RightAnd(One, Ø));
            Assert.LogicalFalse(MaybeEx.RightAnd(Ø, Two));
            Assert.LogicalFalse(MaybeEx.RightAnd(Ø, Ø));
        }

        [Fact]
        public static void Ignore()
        {
            // Some Some -> Some
            Assert.Equal(One, One.Ignore(TwoL));
            // Some None -> Some
            Assert.Equal(One, One.Ignore(ØL));
            // None Some -> None
            Assert.Equal(Ø, Ø.Ignore(TwoL));
            // None None -> None
            Assert.Equal(Ø, Ø.Ignore(ØL));

            // Ignore() is Always() flipped.
            Assert.Equal(One, TwoL.ContinueWith(One));
            Assert.Equal(One, ØL.ContinueWith(One));
            Assert.Equal(Ø, TwoL.ContinueWith(Ø));
            Assert.Equal(Ø, ØL.ContinueWith(Ø));

            // Logic behaviour.
            Assert.LogicalTrue(One.Ignore(TwoL));
            Assert.LogicalTrue(One.Ignore(ØL));
            Assert.LogicalFalse(Ø.Ignore(TwoL));
            Assert.LogicalFalse(Ø.Ignore(ØL));
        }

        [Fact]
        public static void ContinueWith()
        {
            // Some Some -> Some
            Assert.Equal(TwoL, One.ContinueWith(TwoL));
            // Some None -> None
            Assert.Equal(ØL, One.ContinueWith(ØL));
            // None Some -> Some
            Assert.Equal(TwoL, Ø.ContinueWith(TwoL));
            // None None -> None
            Assert.Equal(ØL, Ø.ContinueWith(ØL));

            // Always() is Ignore() flipped.
            Assert.Equal(TwoL, TwoL.Ignore(One));
            Assert.Equal(ØL, ØL.Ignore(One));
            Assert.Equal(TwoL, TwoL.Ignore(Ø));
            Assert.Equal(ØL, ØL.Ignore(Ø));

            // Logic behaviour.
            Assert.LogicalTrue(One.ContinueWith(TwoL));
            Assert.LogicalFalse(One.ContinueWith(ØL));
            Assert.LogicalTrue(Ø.ContinueWith(TwoL));
            Assert.LogicalFalse(Ø.ContinueWith(ØL));
        }
    }
}

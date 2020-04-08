// See LICENSE in the project root for license information.

namespace Abc
{
    using Xunit;

    using Assert = AssertEx;

    // Misc methods.
    public partial class MaybeTests
    {
        [Fact]
        public static void ZipWith_None_NullZipper()
        {
            Assert.ThrowsAnexn("zipper", () => Ø.ZipWith(TwoL, Funk<int, long, AnyResult>.Null));
            Assert.ThrowsAnexn("zipper", () => AnyT.None.ZipWith(TwoL, Funk<AnyT, long, AnyResult>.Null));
        }

        [Fact]
        public static void ZipWith_Some_NullZipper()
        {
            Assert.ThrowsAnexn("zipper", () => One.ZipWith(TwoL, Funk<int, long, AnyResult>.Null));
            Assert.ThrowsAnexn("zipper", () => AnyT.Some.ZipWith(TwoL, Funk<AnyT, long, AnyResult>.Null));
        }

        [Fact]
        public static void ZipWith()
        {
            // Some Some -> Some
            Assert.Some(3L, One.ZipWith(TwoL, (i, j) => i + j));
            // Some None -> None
            Assert.None(One.ZipWith(ØL, (i, j) => i + j));
            // None Some -> None
            Assert.None(Ø.ZipWith(TwoL, (i, j) => i + j));
            // None None -> None
            Assert.None(Ø.ZipWith(ØL, (i, j) => i + j));
        }

        [Fact]
        public static void Skip_None()
        {
            Assert.Equal(Maybe.Zero, Ø.Skip());
            Assert.Equal(Maybe.Zero, NoText.Skip());
            Assert.Equal(Maybe.Zero, NoUri.Skip());
            Assert.Equal(Maybe.Zero, AnyT.None.Skip());
        }

        [Fact]
        public static void Skip_Some()
        {
            Assert.Equal(Maybe.Unit, One.Skip());
            Assert.Equal(Maybe.Unit, SomeText.Skip());
            Assert.Equal(Maybe.Unit, SomeUri.Skip());
            Assert.Equal(Maybe.Unit, AnyT.Some.Skip());
        }
    }

    // In Future.
    public partial class MaybeTests
    {
        [Fact]
        public static void ReplaceWith()
        {
            // Arrange
            var some = Maybe.Unit;

            // Act & Assert
            Assert.Some("value", some.ReplaceWith("value"));
            Assert.None(Ø.ReplaceWith("value"));

            Assert.None(some.ReplaceWith(NullString));
            Assert.None(Ø.ReplaceWith(NullString));

#nullable disable
            Assert.Some(2, some.ReplaceWith((int?)2));
            Assert.None(Ø.ReplaceWith((int?)2));

            Assert.None(some.ReplaceWith(NullNullString));
            Assert.None(Ø.ReplaceWith(NullNullString));
#nullable restore
        }
    }
}

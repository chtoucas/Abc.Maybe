// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections;

    using Xunit;

    public static partial class MaybeComparerTests { }

    // Default.
    public partial class MaybeComparerTests
    {
        [Fact]
        public static void Default_Repeated()
        {
            Assert.Same(MaybeComparer<int>.Default, MaybeComparer<int>.Default);
            Assert.Same(MaybeComparer<long>.Default, MaybeComparer<long>.Default);
            Assert.Same(MaybeComparer<string>.Default, MaybeComparer<string>.Default);
            Assert.Same(MaybeComparer<Uri>.Default, MaybeComparer<Uri>.Default);
            Assert.Same(MaybeComparer<AnyT>.Default, MaybeComparer<AnyT>.Default);
        }

        [Fact]
        public static void Compare_ValueType()
        {
            // Arrange
            var cmp = MaybeComparer<int>.Default;
            var none = Maybe<int>.None;
            var one = Maybe.Some(1);
            var two = Maybe.Some(2);

            // Act & Assert
            // With None
            Assert.Equal(1, cmp.Compare(one, none));
            Assert.Equal(-1, cmp.Compare(none, one));
            Assert.Equal(0, cmp.Compare(none, none));

            // Without None
            Assert.Equal(1, cmp.Compare(two, one));
            Assert.Equal(0, cmp.Compare(one, one));
            Assert.Equal(-1, cmp.Compare(one, two));
        }

        [Fact]
        public static void Compare_Objects()
        {
            // Arrange
            IComparer cmp = MaybeComparer<int>.Default;
            object none = Maybe<int>.None;
            object one = Maybe.Some(1);
            object two = Maybe.Some(2);

            // Act & Assert
            Assert.Equal(0, cmp.Compare(null, null));
            Assert.Equal(-1, cmp.Compare(null, new object()));
            Assert.Equal(1, cmp.Compare(new object(), null));
            Assert.Equal(1, cmp.Compare(new object(), null));

            // With None
            Assert.Equal(1, cmp.Compare(one, none));
            Assert.Equal(-1, cmp.Compare(none, one));
            Assert.Equal(0, cmp.Compare(none, none));

            // Without None
            Assert.Equal(1, cmp.Compare(two, one));
            Assert.Equal(0, cmp.Compare(one, one));
            Assert.Equal(-1, cmp.Compare(one, two));

            // Not comparable
            Assert.Throws<ArgumentException>(() => cmp.Compare(new object(), none));
            Assert.Throws<ArgumentException>(() => cmp.Compare(new object(), one));
            Assert.Throws<ArgumentException>(() => cmp.Compare(none, new object()));
            Assert.Throws<ArgumentException>(() => cmp.Compare(one, new object()));
        }

        [Fact]
        public static void Equals_ValueType()
        {
            // Arrange
            var cmp = MaybeComparer<int>.Default;
            var none = Maybe<int>.None;
            var some = Maybe.Some(1);
            var same = Maybe.Some(1);
            var notSame = Maybe.Some(2);

            // Act & Assert
            // With None
            Assert.False(cmp.Equals(some, none));
            Assert.False(cmp.Equals(none, some));
            Assert.True(cmp.Equals(none, none));

            // Without None
            Assert.False(cmp.Equals(notSame, some));
            Assert.True(cmp.Equals(same, some));
            Assert.True(cmp.Equals(some, some));
            Assert.True(cmp.Equals(some, same));
            Assert.False(cmp.Equals(some, notSame));
        }

        [Fact]
        public static void Equals_ReferenceType()
        {
            // Arrange
            var cmp = MaybeComparer<Uri>.Default;
            var none = Maybe<Uri>.None;
            var some = Maybe.SomeOrNone(new Uri("http://www.narvalo.org"));
            var same = Maybe.SomeOrNone(new Uri("http://www.narvalo.org"));
            var notSame = Maybe.SomeOrNone(new Uri("https://source.dot.net/"));

            // Act & Assert
            // With None
            Assert.False(cmp.Equals(some, none));
            Assert.False(cmp.Equals(none, some));
            Assert.True(cmp.Equals(none, none));

            // Without None
            Assert.False(cmp.Equals(notSame, some));
            Assert.True(cmp.Equals(same, some));
            Assert.True(cmp.Equals(some, some));
            Assert.True(cmp.Equals(some, same));
            Assert.False(cmp.Equals(some, notSame));
        }

        [Fact]
        public static void GetHashCode_None()
        {
            Assert.Equal(0, MaybeComparer<int>.Default.GetHashCode(Maybe<int>.None));
            Assert.Equal(0, MaybeComparer<long>.Default.GetHashCode(Maybe<long>.None));
            Assert.Equal(0, MaybeComparer<string>.Default.GetHashCode(Maybe<string>.None));
            Assert.Equal(0, MaybeComparer<Uri>.Default.GetHashCode(Maybe<Uri>.None));
        }

        [Fact]
        public static void GetHashCode_Some()
        {
            // Arrange
            var icmp = MaybeComparer<int>.Default;
            var lcmp = MaybeComparer<long>.Default;
            var scmp = MaybeComparer<string>.Default;
            var ucmp = MaybeComparer<Uri>.Default;
            string text = "text";
            var someText = Maybe.SomeOrNone(text);
            var uri = new Uri("http://www.narvalo.org");
            var someUri = Maybe.SomeOrNone(uri);
            // Act & Assert
            Assert.Equal(1.GetHashCode(), icmp.GetHashCode(Maybe.Some(1)));
            Assert.Equal(2.GetHashCode(), icmp.GetHashCode(Maybe.Some(2)));
            Assert.Equal(2L.GetHashCode(), lcmp.GetHashCode(Maybe.Some(2L)));
            Assert.Equal(text.GetHashCode(StringComparison.Ordinal), scmp.GetHashCode(someText));
            Assert.Equal(uri.GetHashCode(), ucmp.GetHashCode(someUri));
        }
    }

    // Structural.
    public partial class MaybeComparerTests
    {
        [Fact]
        public static void Structural_Repeated()
        {
            Assert.Same(MaybeComparer<int>.Structural, MaybeComparer<int>.Structural);
            Assert.Same(MaybeComparer<long>.Structural, MaybeComparer<long>.Structural);
            Assert.Same(MaybeComparer<string>.Structural, MaybeComparer<string>.Structural);
            Assert.Same(MaybeComparer<Uri>.Structural, MaybeComparer<Uri>.Structural);
            Assert.Same(MaybeComparer<AnyT>.Structural, MaybeComparer<AnyT>.Structural);
        }
    }
}

// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Collections.Generic;
    using System.Linq;

    using Xunit;

    using Assert = AssertEx;

    // Helpers for Maybe<IEnumerable<T>>.
    public partial class MaybeTests
    {
        [Fact]
        public static void EmptyEnumerable() =>
            Assert.Some(Enumerable.Empty<int>(), Maybe.EmptyEnumerable<int>());

        [Fact]
        public static void CollectAny_NullSource() =>
            Assert.ThrowsAnexn("source", () =>
                Maybe.CollectAny(default(IEnumerable<Maybe<int>>)!));

        [Fact]
        public static void CollectAny_IsDeferred()
        {
            // Arrange
            var source = new ThrowingCollection<Maybe<int>>();
            // Act
            var q = Maybe.CollectAny(source);
            // Assert
            Assert.ThrowsOnNext(q);
        }

        [Fact]
        public static void CollectAny_WithEmpty()
        {
            // Arrange
            var source = Enumerable.Empty<Maybe<int>>();
            // Act
            var q = Maybe.CollectAny(source);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public static void CollectAny_None2None()
        {
            // Arrange
            var expected = new List<int> { 1, 2 };
            // Act
            var q = Maybe.CollectAny(__());
            // Assert
            Assert.Equal(expected, q);

            static IEnumerable<Maybe<int>> __()
            {
                // Start w/ None, end w/ None.
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe.Some(1);
                yield return Maybe.Some(2);
                yield return Maybe<int>.None;
            }
        }

        [Fact]
        public static void CollectAny_None2Some()
        {
            // Arrange
            var expected = new List<int> { 1, 1, 3 };
            // Act
            var q = Maybe.CollectAny(__());
            // Assert
            Assert.Equal(expected, q);

            static IEnumerable<Maybe<int>> __()
            {
                // Start w/ None, end w/ Some.
                yield return Maybe<int>.None;
                yield return Maybe.Some(1);
                yield return Maybe<int>.None;
                yield return Maybe.Some(1);
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe.Some(3);
            }
        }

        [Fact]
        public static void CollectAny_Some2None()
        {
            // Arrange
            var expected = new List<int> { 1, 2 };
            // Act
            var q = Maybe.CollectAny(__());
            // Assert
            Assert.Equal(expected, q);

            static IEnumerable<Maybe<int>> __()
            {
                // Start w/ Some, end w/ None.
                yield return Maybe.Some(1);
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe.Some(2);
                yield return Maybe<int>.None;
            }
        }

        [Fact]
        public static void CollectAny_Some2Some()
        {
            // Arrange
            var expected = new List<int> { 1, 2, 3 };
            // Act
            var q = Maybe.CollectAny(__());
            // Assert
            Assert.Equal(expected, q);

            static IEnumerable<Maybe<int>> __()
            {
                // Start w/ Some, end w/ Some.
                yield return Maybe.Some(1);
                yield return Maybe.Some(2);
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe.Some(3);
            }
        }

        [Fact]
        public static void CollectAny_OnlySome()
        {
            // Arrange
            var expected = new List<int> { 1, 2, 3, 314, 413, 7, 5, 3 };
            // Act
            var q = Maybe.CollectAny(__());
            // Assert
            Assert.Equal(expected, q);

            static IEnumerable<Maybe<int>> __()
            {
                // Only Some.
                yield return Maybe.Some(1);
                yield return Maybe.Some(2);
                yield return Maybe.Some(3);
                yield return Maybe.Some(314);
                yield return Maybe.Some(413);
                yield return Maybe.Some(7);
                yield return Maybe.Some(5);
                yield return Maybe.Some(3);
            }
        }

        [Fact]
        public static void CollectAny_OnlyNone()
        {
            // Act
            var q = Maybe.CollectAny(__());
            // Assert
            Assert.Empty(q);

            static IEnumerable<Maybe<int>> __()
            {
                // Only None.
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
                yield return Maybe<int>.None;
            }
        }
    }
}

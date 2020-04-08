// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System.Collections;
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

    public static class NeverEndingSequenceTests
    {
        private static readonly AnyT Value;
        private static readonly IEnumerable<AnyT> Iter;

#pragma warning disable CA1810 // Initialize reference type static fields inline
        static NeverEndingSequenceTests()
#pragma warning restore CA1810
        {
            var anyT = AnyT.New();
            Value = anyT.Value;
            Iter = anyT.Some.Yield();
        }

        [Fact(DisplayName = "GetEnumerator() always returns the same iterator.")]
        public static void GetEnumerator()
        {
            // Arrange
            IEnumerator<AnyT> it = Iter.GetEnumerator();
            // Act & Assert
            Assert.Same(Iter, it);
        }

        [Fact(DisplayName = "GetEnumerator() (untyped) always returns the same iterator.")]
        public static void GetEnumerator_Untyped()
        {
            // Arrange
            IEnumerable enumerable = Iter;
            IEnumerator it = enumerable.GetEnumerator();
            // Act & Assert
            Assert.Same(Iter, it);
        }

        [Fact]
        public static void Current()
        {
            // Arrange
            IEnumerator<AnyT> it = Iter.GetEnumerator();

            // Act & Assert
            // Even before the first MoveNext(), Current already returns Value.
            Assert.Same(Value, it.Current);

            for (int i = 0; i < 100; i++)
            {
                Assert.True(it.MoveNext());
                Assert.Same(Value, it.Current);
            }
        }

        [Fact]
        public static void Current_Untyped()
        {
            // Arrange
            IEnumerator it = Iter.GetEnumerator();

            // Act & Assert
            // Even before the first MoveNext(), Current already returns Value.
            Assert.Same(Value, it.Current);

            for (int i = 0; i < 100; i++)
            {
                Assert.True(it.MoveNext());
                Assert.Same(Value, it.Current);
            }
        }

        [Fact]
        public static void MoveNext()
        {
            // Arrange
            IEnumerator it = Iter.GetEnumerator();
            // Act & Assert
            Assert.True(it.MoveNext());
        }

        [Fact]
        public static void Reset()
        {
            // Arrange
            IEnumerator it = Iter.GetEnumerator();

            // Act & Assert
            for (int i = 0; i < 100; i++)
            {
                Assert.True(it.MoveNext());
                Assert.Same(Value, it.Current);
            }

            // Reset() does nothing.
            it.Reset();

            for (int i = 0; i < 100; i++)
            {
                Assert.True(it.MoveNext());
                Assert.Same(Value, it.Current);
            }
        }

        [Fact]
        public static void Dispose()
        {
            // Arrange
            IEnumerator<AnyT> it = Iter.GetEnumerator();

            // Act & Assert
            for (int i = 0; i < 100; i++)
            {
                Assert.True(it.MoveNext());
                Assert.Same(Value, it.Current);
            }

            // Dispose() does nothing.
            it.Dispose();

            for (int i = 0; i < 100; i++)
            {
                Assert.True(it.MoveNext());
                Assert.Same(Value, it.Current);
            }
        }
    }
}

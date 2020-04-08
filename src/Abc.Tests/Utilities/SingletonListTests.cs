// See LICENSE in the project root for license information.

namespace Abc.Utilities
{
    using System;
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

    public static partial class SingletonListTests
    {
        private static readonly AnyT Value;
        private static readonly IEnumerable<AnyT> Iter;

#pragma warning disable CA1810 // Initialize reference type static fields inline
        static SingletonListTests()
#pragma warning restore CA1810
        {
            var anyT = AnyT.New();
            Value = anyT.Value;
            Iter = anyT.Some.ToEnumerable();
        }
    }

    // IList<T>
    public partial class SingletonListTests
    {
        public static readonly TheoryData<int> IndexesForNotSupportedMethod
            = new TheoryData<int>
            {
                // -1 is always invalid for a list.
                -1,
                // Only 0 is actually valid but we use this data to test not
                // supported methods.
                0, 1, 100, 1000, Int32.MaxValue
            };

        [Theory]
        [InlineData(-1)]
        [InlineData(1)]
        [InlineData(10)]
        [InlineData(100)]
        [InlineData(Int32.MaxValue)]
        public static void Indexer_Get_InvalidIndex(int index)
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.ThrowsAoorexn("index", () => list[index]);
        }

        [Fact]
        public static void Indexer_Get()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Equal(Value, list[0]);
        }

        [Theory, MemberData(nameof(IndexesForNotSupportedMethod))]
        public static void Indexer_Set(int index)
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Throws<NotSupportedException>(() => list[index] = AnyT.Value);
        }

        [Fact]
        public static void IndexOf_OK()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Equal(0, list.IndexOf(Value));
        }

        [Fact]
        public static void IndexOf_KO()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Equal(-1, list.IndexOf(AnyT.Value));
        }

        [Theory, MemberData(nameof(IndexesForNotSupportedMethod))]
        public static void Insert(int index)
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Throws<NotSupportedException>(() => list.Insert(index, AnyT.Value));
        }

        [Theory, MemberData(nameof(IndexesForNotSupportedMethod))]
        public static void RemoveAt(int index)
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Throws<NotSupportedException>(() => list.RemoveAt(index));
        }
    }

    // ICollection<T>
    public partial class SingletonListTests
    {
        [Fact]
        public static void Count()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Equal(1, list.Count);
        }

        [Fact]
        public static void IsReadOnly()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.True(list.IsReadOnly);
        }

        [Fact]
        public static void Add()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Throws<NotSupportedException>(() => list.Add(AnyT.Value));
        }

        [Fact]
        public static void Clear()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Throws<NotSupportedException>(() => list.Clear());
        }

        [Fact]
        public static void Contains_OK()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.True(list.Contains(Value));
        }

        [Fact]
        public static void Contains_KO()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.False(list.Contains(AnyT.Value));
        }

        [Theory]
        [InlineData(0)]
        [InlineData(1)]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        [InlineData(5)]
        [InlineData(6)]
        [InlineData(7)]
        [InlineData(8)]
        [InlineData(9)]
        public static void CopyTo(int index)
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            var arr = new AnyT[10]
            {
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
                AnyT.Value,
            };
            // Act
            list.CopyTo(arr, index);
            // Assert
            for (int i = 0; i < 10; i++)
            {
                if (i == index)
                {
                    Assert.Same(Value, arr[index]);
                }
                else
                {
                    Assert.NotSame(Value, arr[i]);
                }
            }
        }

        [Fact]
        public static void Remove()
        {
            // Arrange
            var list = (IList<AnyT>)Iter;
            // Act & Assert
            Assert.Throws<NotSupportedException>(() => list.Remove(Value));
        }
    }

    // IEnumerable<T>.
    public partial class SingletonListTests
    {
        [Fact(DisplayName = "GetEnumerator() returns a new iterator.")]
        public static void GetEnumerator()
        {
            Assert.NotSame(Iter.GetEnumerator(), Iter.GetEnumerator());
        }

        [Fact]
        public static void Iterate()
        {
            // Arrange
            IEnumerator<AnyT> it = Iter.GetEnumerator();

            // Act & Assert
            // Even before the first MoveNext(), Current already returns Value.
            Assert.Same(Value, it.Current);

            Assert.True(it.MoveNext());
            Assert.Same(Value, it.Current);
            Assert.False(it.MoveNext());

            it.Reset();

            Assert.True(it.MoveNext());
            Assert.Same(Value, it.Current);
            Assert.False(it.MoveNext());

            // Dispose() does nothing.
            it.Dispose();
            Assert.False(it.MoveNext());

            it.Reset();

            Assert.True(it.MoveNext());
            Assert.Same(Value, it.Current);
            Assert.False(it.MoveNext());
        }
    }
}

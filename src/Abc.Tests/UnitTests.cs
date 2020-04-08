// See LICENSE in the project root for license information.

namespace Abc.Tests
{
    using System;
    using System.Runtime.InteropServices;

    using Xunit;

    public static class UnitTests
    {
        [Fact]
        public static void RuntimeSize()
        {
            // 1 byte.
            Assert.Equal(1, Marshal.SizeOf(typeof(Unit)));
        }

        [Fact]
        public static void Singleton()
        {
            // Arrange
            var unit = default(Unit);
            // Act & Assert
            Assert.True(Unit.Default == unit);
            Assert.True(unit == Unit.Default);
            Assert.True(Unit.Default.Equals(unit));
            Assert.True(unit.Equals(Unit.Default));
        }

        [Fact]
        public static void Equality()
        {
            // Arrange
            var unit = new Unit();
            var same = new Unit();
            var tupl = new ValueTuple();

            // Act & Assert
            Assert.True(unit == same);
            Assert.True(same == unit);
            Assert.True(unit == tupl);
            Assert.True(tupl == unit);

            Assert.False(unit != same);
            Assert.False(same != unit);
            Assert.False(unit != tupl);
            Assert.False(tupl != unit);

            Assert.True(unit.Equals(unit));
            Assert.True(unit.Equals(same));
            Assert.True(same.Equals(unit));
            Assert.True(unit.Equals(tupl));

            Assert.True(unit.Equals((object)unit));
            Assert.True(unit.Equals((object)same));
            Assert.True(unit.Equals((object)tupl));
            Assert.False(unit.Equals(null));
            Assert.False(unit.Equals(new object()));
        }

        [Fact]
        public static void HashCode()
            => Assert.Equal(0, Unit.Default.GetHashCode());

        [Fact]
        public static void ToString_CurrentCulture()
            => Assert.Equal("()", Unit.Default.ToString());
    }
}

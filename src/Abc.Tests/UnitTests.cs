// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Tests
{
#if API_PROFILE_21 // ValueTuple
    using System;
#endif
    using System.Runtime.InteropServices;

#if !NETSTANDARD1_x && !NET5_0_OR_GREATER // System.Runtime.Serialization
    using System.IO;
    using System.Runtime.Serialization.Formatters.Binary;
#endif

    using Xunit;

    public static class UnitTests
    {
        [Fact]
        public static void RuntimeSize() =>
            // 1 byte.
            Assert.Equal(1, Marshal.SizeOf(typeof(Unit)));

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

            // Act & Assert
            Assert.True(unit == same);
            Assert.True(same == unit);

            Assert.False(unit != same);
            Assert.False(same != unit);

            Assert.True(unit.Equals(unit));
            Assert.True(unit.Equals(same));
            Assert.True(same.Equals(unit));

            Assert.True(unit.Equals((object)unit));
            Assert.True(unit.Equals((object)same));
            Assert.False(unit.Equals(null));
            Assert.False(unit.Equals(new object()));

#if API_PROFILE_21 // ValueTuple
            // Arrange
            var tupl = new ValueTuple();

            // Act & Assert
            Assert.True(unit == tupl);
            Assert.True(tupl == unit);

            Assert.False(unit != tupl);
            Assert.False(tupl != unit);

            Assert.True(unit.Equals(tupl));

            Assert.True(unit.Equals((object)tupl));
#endif
        }

        [Fact]
        public static void HashCode()
            => Assert.Equal(0, Unit.Default.GetHashCode());

        [Fact]
        public static void ToString_CurrentCulture()
            => Assert.Equal("()", Unit.Default.ToString());

#if !NETSTANDARD1_x && !NET5_0_OR_GREATER // System.Runtime.Serialization
        [Fact]
        public static void Serialization()
        {
            // Arrange
            var formatter = new BinaryFormatter();
            Unit unit;
            // Act (serialize then deserialize)
            using (var stream = new MemoryStream())
            {
                formatter.Serialize(stream, Unit.Default);

                stream.Seek(0, SeekOrigin.Begin);
                unit = (Unit)formatter.Deserialize(stream);
            }
            // Assert
            Assert.Equal(Unit.Default, unit);
        }
#endif
    }
}

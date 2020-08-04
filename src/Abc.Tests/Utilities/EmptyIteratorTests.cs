// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Utilities
{
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

    public static class EmptyIteratorTests
    {
        [Fact]
        public static void Iterate()
        {
            // Arrange
            IEnumerator<AnyT> it = AnyT.None.GetEnumerator();
            // Act & Assert
            Assert.False(it.MoveNext());
            it.Reset();
            Assert.False(it.MoveNext());
            it.Dispose();
            Assert.False(it.MoveNext());
        }
    }
}

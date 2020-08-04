// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#region License
// The MIT License (MIT)
//
// Copyright (c) .NET Foundation and Contributors
//
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
#endregion

// Adapted from https://github.com/dotnet/runtime/blob/master/src/libraries/System.Linq/tests/ZipTests.cs

namespace Abc.Linq
{
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class ZipAnyTests : QperatorsTests
    {
        [Pure] private static Maybe<int> AddNone(int x, int y) => Maybe<int>.None;
        [Pure] private static Maybe<int> AddSome(int x, int y) => Maybe.Some(x + y);

        [Pure]
        private static Maybe<int> AddUnless7(int x, int y)
        {
            int sum = x + y;
            return sum == 7 ? Maybe<int>.None : Maybe.Some(sum);
        }
    }

    // Arg check.
    public partial class ZipAnyTests
    {
        [Fact]
        public static void NullFirst() =>
            Assert.ThrowsAnexn("first", () =>
                NullSeq.ZipAny(AnySeq, Kunc<int, int, int>.Any));

        [Fact]
        public static void NullSecond() =>
            Assert.ThrowsAnexn("second", () =>
                AnySeq.ZipAny(NullSeq, Kunc<int, int, int>.Any));

        [Fact]
        public static void NullResultSelector() =>
            Assert.ThrowsAnexn("resultSelector", () =>
                AnySeq.ZipAny(AnySeq, Kunc<int, int, int>.Null));
    }

    // Deferred execution.
    public partial class ZipAnyTests
    {
        [Fact]
        public static void Enumerable_Deferred()
        {
            // Arrange
            bool called = false;
            var first = Enumerable.Range(1, 5);
            var second = Enumerable.Range(10, 5);
            // Act
            var q = first.ZipAny(second, __);
            // Assert
            Assert.False(called);
            Assert.CalledOnNext(q, ref called);

            Maybe<int> __(int x, int y) { called = true; return Maybe.Some(x + y); }
        }
    }

    public partial class ZipAnyTests
    {
        [Fact]
        public void ImplicitTypeParameters_OnlyNone()
        {
            // Arrange
            IEnumerable<int> first = new int[] { 1, 2, 3 };
            IEnumerable<int> second = new int[] { 2, 5, 9 };
            // Act
            var q = first.ZipAny(second, AddNone);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void ImplicitTypeParameters_OnlySome()
        {
            // Arrange
            IEnumerable<int> first = new int[] { 1, 2, 3 };
            IEnumerable<int> second = new int[] { 2, 5, 9 };
            IEnumerable<int> expected = new int[] { 3, 7, 12 };
            // Act
            var q = first.ZipAny(second, AddSome);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ImplicitTypeParameters_Mixed()
        {
            // Arrange
            IEnumerable<int> first = new int[] { 1, 2, 3 };
            IEnumerable<int> second = new int[] { 2, 5, 9 };
            IEnumerable<int> expected = new int[] { 3, 12 };
            // Act
            var q = first.ZipAny(second, AddUnless7);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ExplicitTypeParameters()
        {
            IEnumerable<int> first = new int[] { 1, 2, 3 };
            IEnumerable<int> second = new int[] { 2, 5, 9 };
            IEnumerable<int> expected = new int[] { 3, 7, 12 };
            // Act
            var q = first.ZipAny<int, int, int>(second, AddSome);
            // Assert
            Assert.Equal(expected, q);
        }
    }
}

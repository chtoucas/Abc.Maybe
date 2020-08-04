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

// Adapted from https://github.com/dotnet/runtime/blob/master/src/libraries/System.Linq/tests/SelectTests.cs

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class SelectAnyTests : QperatorsTests
    {
        [Pure] private static Maybe<int> ReturnNone(int i) => Maybe<int>.None;
        [Pure] private static Maybe<int> AddOne(int i) => Maybe.Some(i + 1);
        [Pure] private static Maybe<int> AddOneUnless3(int i) => i == 3 ? Maybe<int>.None : Maybe.Some(i + 1);
    }

    // Arg check.
    public partial class SelectAnyTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () => NullSeq.SelectAny(Kunc<int, int>.Any));

        [Fact]
        public static void NullSelector() =>
            Assert.ThrowsAnexn("selector", () => AnySeq.SelectAny(Kunc<int, int>.Null));
    }

    // Deferred execution.
    public partial class SelectAnyTests
    {
        [Fact]
        public static void Enumerable_Deferred()
        {
            // Arrange
            bool called = false;
            var source = Enumerable.Repeat((Func<Maybe<int>>)__, 1);
            // Act
            var q = source.SelectAny(f => f());
            // Assert
            Assert.False(called);
            Assert.CalledOnNext(q, ref called);

            Maybe<int> __() { called = true; return Maybe.Some(1); }
        }
    }

    // Selector returns None, always.
    public partial class SelectAnyTests
    {
        [Fact]
        public void Array_OnlyNone()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            // Act
            var q = source.SelectAny(ReturnNone);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void List_OnlyNone()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            // Act
            var q = source.SelectAny(ReturnNone);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void ReadOnlyCollection_OnlyNone()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            // Act
            var q = source.SelectAny(ReturnNone);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void Collection_OnlyNone()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            // Act
            var q = source.SelectAny(ReturnNone);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void Enumerable_OnlyNone()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            // Act
            var q = source.SelectAny(ReturnNone);
            // Assert
            Assert.Empty(q);
        }
    }

    // Selector returns Some, always.
    public partial class SelectAnyTests
    {
        [Fact]
        public void Array_OnlySome()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            int[] expected = new[] { 2, 3, 4, 5, 6 };
            // Act
            var q = source.SelectAny(AddOne);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void List_OnlySome()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            var expected = new List<int> { 2, 3, 4, 5, 6 };
            // Act
            var q = source.SelectAny(AddOne);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ReadOnlyCollection_OnlySome()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 2, 3, 4, 5, 6 };
            // Act
            var q = source.SelectAny(AddOne);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Collection_OnlySome()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 2, 3, 4, 5, 6 };
            // Act
            var q = source.SelectAny(AddOne);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Enumerable_OnlySome()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            var expected = new List<int> { 2, 3, 4, 5, 6 };
            // Act
            var q = source.SelectAny(AddOne);
            // Assert
            Assert.Equal(expected, q);
        }
    }

    // Selector returns Some or None.
    public partial class SelectAnyTests
    {
        [Fact]
        public void Array_Mixed()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            int[] expected = new[] { 2, 3, 5, 6 };
            // Act
            var q = source.SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void List_Mixed()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            var expected = new List<int> { 2, 3, 5, 6 };
            // Act
            var q = source.SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ReadOnlyCollection_Mixed()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 2, 3, 5, 6 };
            // Act
            var q = source.SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Collection_Mixed()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 2, 3, 5, 6 };
            // Act
            var q = source.SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Enumerable_Mixed()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            var expected = new List<int> { 2, 3, 5, 6 };
            // Act
            var q = source.SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }
    }

    // Current is default after enumeration.
    public partial class SelectAnyTests
    {
        [Fact]
        public void Array_CurrentAfterEnumeration()
        {
            // Arrange
            int[] source = new[] { 1 };
            // Act
            IEnumerable<int> q = source.SelectAny(AddOne);
            var enumerator = q.GetEnumerator();
            while (enumerator.MoveNext()) { }
            // Assert
            Assert.Equal(default, enumerator.Current);
        }

        [Fact]
        public void List_CurrentAfterEnumeration()
        {
            // Arrange
            var source = new List<int> { 1 };
            // Act
            IEnumerable<int> q = source.SelectAny(AddOne);
            var enumerator = q.GetEnumerator();
            while (enumerator.MoveNext()) { }
            // Assert
            Assert.Equal(default, enumerator.Current);
        }

        [Fact]
        public void ReadOnlyCollection_CurrentAfterEnumeration()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1 });
            // Act
            IEnumerable<int> q = source.SelectAny(AddOne);
            var enumerator = q.GetEnumerator();
            while (enumerator.MoveNext()) { }
            // Assert
            Assert.Equal(default, enumerator.Current);
        }

        [Fact]
        public void Collection_CurrentAfterEnumeration()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1 });
            // Act
            IEnumerable<int> q = source.SelectAny(AddOne);
            var enumerator = q.GetEnumerator();
            while (enumerator.MoveNext()) { }
            // Assert
            Assert.Equal(default, enumerator.Current);
        }

        [Fact]
        public void Enumerable_CurrentAfterEnumeration()
        {
            // Arrange
            var source = Enumerable.Range(1, 1);
            // Act
            IEnumerable<int> q = source.SelectAny(AddOne);
            var enumerator = q.GetEnumerator();
            while (enumerator.MoveNext()) { }
            // Assert
            Assert.Equal(default, enumerator.Current);
        }
    }

    // SelectAny() called twice in a row.
    public partial class SelectAnyTests
    {
        [Fact]
        public void Array_Twice()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            int[] expected = new[] { 3, 6, 7 };
            // Act
            var q = source.SelectAny(AddOneUnless3).SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void List_Twice()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            var expected = new List<int> { 3, 6, 7 };
            // Act
            var q = source.SelectAny(AddOneUnless3).SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ReadOnlyCollection_Twice()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 3, 6, 7 };
            // Act
            var q = source.SelectAny(AddOneUnless3).SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Collection_Twice()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 3, 6, 7 };
            // Act
            var q = source.SelectAny(AddOneUnless3).SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Enumerable_Twice()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            var expected = new List<int> { 3, 6, 7 };
            // Act
            var q = source.SelectAny(AddOneUnless3).SelectAny(AddOneUnless3);
            // Assert
            Assert.Equal(expected, q);
        }
    }
}

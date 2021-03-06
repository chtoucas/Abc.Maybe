﻿// Licensed to the .NET Foundation under one or more agreements.
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

// Adapted from https://github.com/dotnet/runtime/blob/master/src/libraries/System.Linq/tests/WhereTests.cs

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Diagnostics.Contracts;
    using System.Linq;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class WhereAnyTests : QperatorsTests
    {
        [Pure] private static Maybe<bool> AlwaysTrue<T>(T _) => Maybe.True;
        [Pure] private static Maybe<bool> AlwaysFalse<T>(T _) => Maybe.False;

        [Pure] private static Maybe<bool> TrueUnless3(int i) => i == 3 ? Maybe.False : Maybe.True;

        [Pure] private static Maybe<bool> TrueUnless13(int i) => i == 1 ? Maybe.Unknown : i == 3 ? Maybe.False : Maybe.True;
    }

    // Arg check.
    public partial class WhereAnyTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () => NullSeq.WhereAny(Kunc<int, bool>.Any));

        [Fact]
        public static void NullPredicate() =>
            Assert.ThrowsAnexn("predicate", () => AnySeq.WhereAny(Kunc<int, bool>.Null));
    }

    // Deferred execution.
    public partial class WhereAnyTests
    {
        [Fact]
        public static void Enumerable_Deferred()
        {
            // Arrange
            bool called = false;
            var source = Enumerable.Repeat((Func<Maybe<bool>>)__, 1);
            // Act
            var q = source.WhereAny(f => f());
            // Assert
            Assert.False(called);
            Assert.CalledOnNext(q, ref called);

            Maybe<bool> __() { called = true; return Maybe.True; }
        }
    }

    // Predicate returns True, always.
    public partial class WhereAnyTests
    {
        [Fact]
        public void Array_AlwaysTrue()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            // Act
            var q = source.WhereAny(AlwaysTrue);
            // Assert
            Assert.Equal(source, q);
        }

        [Fact]
        public void List_AlwaysTrue()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            // Act
            var q = source.WhereAny(AlwaysTrue);
            // Assert
            Assert.Equal(source, q);
        }

        [Fact]
        public void ReadOnlyCollection_AlwaysTrue()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            // Act
            var q = source.WhereAny(AlwaysTrue);
            // Assert
            Assert.Equal(source, q);
        }

        [Fact]
        public void Collection_AlwaysTrue()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            // Act
            var q = source.WhereAny(AlwaysTrue);
            // Assert
            Assert.Equal(source, q);
        }

        [Fact]
        public void Enumerable_AlwaysTrue()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            // Act
            var q = source.WhereAny(AlwaysTrue);
            // Assert
            Assert.Equal(source, q);
        }
    }

    // Predicate returns False, always.
    public partial class WhereAnyTests
    {
        [Fact]
        public void Array_AlwaysFalse()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            // Act
            var q = source.WhereAny(AlwaysFalse);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void List_AlwaysFalse()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            // Act
            var q = source.WhereAny(AlwaysFalse);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void ReadOnlyCollection_AlwaysFalse()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            // Act
            var q = source.WhereAny(AlwaysFalse);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void Collection_AlwaysFalse()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            // Act
            var q = source.WhereAny(AlwaysFalse);
            // Assert
            Assert.Empty(q);
        }

        [Fact]
        public void Enumerable_AlwaysFalse()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            // Act
            var q = source.WhereAny(AlwaysFalse);
            // Assert
            Assert.Empty(q);
        }
    }

    // Predicate returns True or False.
    public partial class WhereAnyTests
    {
        [Fact]
        public void Array_TrueOrFalse()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            int[] expected = new[] { 1, 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void List_TrueOrFalse()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            var expected = new List<int> { 1, 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ReadOnlyCollection_TrueOrFalse()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 1, 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Collection_TrueOrFalse()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 1, 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless3);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Enumerable_TrueOrFalse()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            var expected = new List<int> { 1, 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless3);
            // Assert
            Assert.Equal(expected, q);
        }
    }

    // Predicate returns True, False or Unknown.
    public partial class WhereAnyTests
    {
        [Fact]
        public void Array_BooleanOrUnknown()
        {
            // Arrange
            int[] source = new[] { 1, 2, 3, 4, 5 };
            int[] expected = new[] { 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless13);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void List_BooleanOrUnknown()
        {
            // Arrange
            var source = new List<int> { 1, 2, 3, 4, 5 };
            var expected = new List<int> { 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless13);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void ReadOnlyCollection_BooleanOrUnknown()
        {
            // Arrange
            var source = new ReadOnlyCollection<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless13);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Collection_BooleanOrUnknown()
        {
            // Arrange
            var source = new LinkedList<int>(new List<int> { 1, 2, 3, 4, 5 });
            var expected = new List<int> { 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless13);
            // Assert
            Assert.Equal(expected, q);
        }

        [Fact]
        public void Enumerable_BooleanOrUnknown()
        {
            // Arrange
            var source = Enumerable.Range(1, 5);
            var expected = new List<int> { 2, 4, 5 };
            // Act
            var q = source.WhereAny(TrueUnless13);
            // Assert
            Assert.Equal(expected, q);
        }
    }
}

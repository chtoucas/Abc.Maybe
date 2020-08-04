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

// Adapted from https://github.com/dotnet/runtime/blob/master/src/libraries/System.Linq/tests/ElementAtOrDefaultTests.cs

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Linq.Tests;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class ElementAtOrNoneTests : QperatorsTests
    {
        public static IEnumerable<object[]> SampleData
        {
            get
            {
                yield return new object[] { NumberRangeGuaranteedNotCollectionType(9, 1), 0, Maybe.Some(9) };
                yield return new object[] { NumberRangeGuaranteedNotCollectionType(9, 10), 9, Maybe.Some(18) };
                yield return new object[] { NumberRangeGuaranteedNotCollectionType(-4, 10), 3, Maybe.Some(-1) };

                yield return new object[] { new int[] { 1, 2, 3, 4 }, 4, Maybe<int>.None };
                yield return new object[] { ArrayEx.Empty<int>(), 0, Maybe<int>.None };
                yield return new object[] { new int[] { -4 }, 0, Maybe.Some(-4) };
                yield return new object[] { new int[] { 9, 8, 0, -5, 10 }, 4, Maybe.Some(10) };

                yield return new object[] { NumberRangeGuaranteedNotCollectionType(-4, 5), -1, Maybe<int>.None };
                yield return new object[] { NumberRangeGuaranteedNotCollectionType(5, 5), 5, Maybe<int>.None };
                yield return new object[] { NumberRangeGuaranteedNotCollectionType(0, 0), 0, Maybe<int>.None };
            }
        }
    }

    // Arg check.
    public partial class ElementAtOrNoneTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () => NullSeq.ElementAtOrNone(1));
    }

    public partial class ElementAtOrNoneTests
    {
        [Fact(DisplayName = "ElementAtOrNone() for int's returns the same result when called repeatedly.")]
        public static void ElementAtOrNone1()
        {
            var q = from x in new[] { 9999, 0, 888, -1, 66, -777, 1, 2, -12345 }
                    where x > Int32.MinValue
                    select x;

            Assert.Equal(q.ElementAtOrNone(3), q.ElementAtOrNone(3));
        }

        [Fact(DisplayName = "ElementAtOrNone() for string's returns the same result when called repeatedly.")]
        public static void ElementAtOrNone2()
        {
            var q = from x in new[] { "!@#$%^", "C", "AAA", "", "Calling Twice", "SoS", String.Empty }
                    where !String.IsNullOrEmpty(x)
                    select x;

            Assert.Equal(q.ElementAtOrNone(4), q.ElementAtOrNone(4));
        }

        [Theory(DisplayName = "ElementAtOrDefault")]
        [MemberData(nameof(SampleData))]
        public static void ElementAtOrNone3(IEnumerable<int> source, int index, Maybe<int> expected)
        {
            Assert.Equal(expected, source.ElementAtOrNone(index));
        }

        [Theory(DisplayName = "ElementAtOrDefaultRunOnce")]
        [MemberData(nameof(SampleData))]
        public static void ElementAtOrNone4(IEnumerable<int> source, int index, Maybe<int> expected)
        {
            Assert.Equal(expected, source.RunOnce().ElementAtOrNone(index));
        }

        [Fact]
        public static void NullableArray_NegativeIndex_ReturnsNone()
        {
            string[] source = { "a", "b" };
            Assert.None(source.ElementAtOrNone(-1));
        }

        [Fact(DisplayName = "NullableArray_ValidIndex_ReturnsCorrectObjecvt")]
        public static void ElementAtOrNone6()
        {
            string[] source = { "a", "b", null!, "d", "e" };

            Assert.Equal(Maybe<string>.None, source.ElementAtOrNone(2));
            Assert.Equal(Maybe.SomeOrNone("d"), source.ElementAtOrNone(3));
        }
    }
}

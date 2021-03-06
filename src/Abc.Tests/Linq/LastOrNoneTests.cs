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

// Adapted from https://github.com/dotnet/corefx/blob/master/src/System.Linq/tests/LastOrDefaultTests.cs

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Data;
    using System.Linq;
    using System.Linq.Tests;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class LastOrNoneTests : QperatorsTests { }

    // Arg check.
    public partial class LastOrNoneTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () => NullSeq.LastOrNone());

        [Fact]
        public static void NullSource_WithPredicate() =>
            Assert.ThrowsAnexn("source", () => NullSeq.LastOrNone(Funk<int, bool>.Any));

        [Fact]
        public static void NullPredicate() =>
            Assert.ThrowsAnexn("predicate", () => AnySeq.LastOrNone(Funk<int, bool>.Null));
    }

    public partial class LastOrNoneTests
    {
        [Fact(DisplayName = "LastOrNone() for int's returns the same result when called repeatedly.")]
        public static void LastOrNone1()
        {
            var q = from x in new[] { 9999, 0, 888, -1, 66, -777, 1, 2, -12345 }
                    where x > Int32.MinValue
                    select x;

            Assert.Equal(q.LastOrNone(), q.LastOrNone());
        }

        [Fact(DisplayName = "LastOrNone() for string's returns the same result when called repeatedly.")]
        public static void LastOrNone2()
        {
            var q = from x in new[] { "!@#$%^", "C", "AAA", "", "Calling Twice", "SoS", String.Empty }
                    where !String.IsNullOrEmpty(x)
                    select x;

            Assert.Equal(q.LastOrNone(), q.LastOrNone());
        }

        private static void LastOrNone3Impl<T>()
        {
            T[] source = ArrayEx.Empty<T>();
            var expected = Maybe<T>.None;

            Assert.IsAssignableFrom<IList<T>>(source);
            Assert.Equal(expected, source.RunOnce().LastOrNone());
        }

        [Fact(DisplayName = "EmptyIListT")]
        public static void LastOrNone3()
        {
            LastOrNone3Impl<int>();
            LastOrNone3Impl<string>();
            LastOrNone3Impl<DateTime>();
            LastOrNone3Impl<QperatorsTests>();
        }

        [Fact]
        public static void LastOrNone3a()
        {
            // Covers the branch (!iter.MoveNext()) prior to .NET Core 3.0.
            var source = new Dictionary<int, int>();
            Assert.None(source.RunOnce().LastOrNone());
        }

        [Fact(DisplayName = "IListTOneElement")]
        public static void LastOrNone4()
        {
            int[] source = { 5 };
            var expected = Maybe.Some(5);

            Assert.IsAssignableFrom<IList<int>>(source);
            Assert.Equal(expected, source.LastOrNone());
        }

        [Fact(DisplayName = "IListTManyElementsLastIsDefault")]
        public static void LastOrNone5()
        {
            string[] source = { "!@#$%^", "C", "AAA", "", "Calling Twice", "SoS", null! };
            var expected = Maybe<string>.None;

            Assert.IsAssignableFrom<IList<string>>(source);
            Assert.Equal(expected, source.LastOrNone());
        }

        [Fact(DisplayName = "IListTManyElementsLastIsNotDefault")]
        public static void LastOrNone6()
        {
            string[] source = { "!@#$%^", "C", "AAA", "", "Calling Twice", null!, "SoS" };
            var expected = Maybe.SomeOrNone("SoS");

            Assert.IsAssignableFrom<IList<string>>(source);
            Assert.Equal(expected, source.LastOrNone());
        }

        private static void LastOrNone7Impl<T>()
        {
            var source = Enumerable.Empty<T>();
            var expected = Maybe<T>.None;

#if NETCOREAPP2_x || NETFRAMEWORK // Enumerable.Empty
            Assert.Empty(source as IList<T>);
#else
            Assert.Null(source as IList<T>);
#endif

            Assert.Equal(expected, source.RunOnce().LastOrNone());
        }

        [Fact(DisplayName = "EmptyNotIListT")]
        public static void LastOrNone7()
        {
            LastOrNone7Impl<int>();
            LastOrNone7Impl<string>();
            LastOrNone7Impl<DateTime>();
            LastOrNone7Impl<QperatorsTests>();
        }

        [Fact(DisplayName = "OneElementNotIListT")]
        public static void LastOrNone8()
        {
            IEnumerable<int> source = NumberRangeGuaranteedNotCollectionType(-5, 1);
            var expected = Maybe.Some(-5);

            Assert.Null(source as IList<int>);
            Assert.Equal(expected, source.LastOrNone());
        }

        [Fact(DisplayName = "ManyElementsNotIListT")]
        public static void LastOrNone9()
        {
            IEnumerable<int> source = NumberRangeGuaranteedNotCollectionType(3, 10);
            var expected = Maybe.Some(12);

            Assert.Null(source as IList<int>);
            Assert.Equal(expected, source.LastOrNone());
        }

        [Fact(DisplayName = "EmptyIListSource")]
        public static void LastOrNone10()
        {
            string[] source = ArrayEx.Empty<string>();

            Assert.Equal(Maybe<string>.None, source.LastOrNone(x => true));
            Assert.Equal(Maybe<string>.None, source.LastOrNone(x => false));
        }

        [Fact(DisplayName = "OneElementIListTruePredicate")]
        public static void LastOrNone11()
        {
            int[] source = { 4 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(4);

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "ManyElementsIListPredicateFalseForAll")]
        public static void LastOrNone12()
        {
            int[] source = { 9, 5, 1, 3, 17, 21 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "IListPredicateTrueOnlyForLast")]
        public static void LastOrNone13()
        {
            int[] source = { 9, 5, 1, 3, 17, 21, 50 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(50);

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "IListPredicateTrueForSome")]
        public static void LastOrNone14()
        {
            int[] source = { 3, 7, 10, 7, 9, 2, 11, 18, 13, 9 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(18);

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "IListPredicateTrueForSomeRunOnce")]
        public static void LastOrNone15()
        {
            int[] source = { 3, 7, 10, 7, 9, 2, 11, 18, 13, 9 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(18);

            Assert.Equal(expected, source.RunOnce().LastOrNone(predicate));
        }

        [Fact(DisplayName = "EmptyNotIListSource")]
        public static void LastOrNone16()
        {
            IEnumerable<string> source = Enumerable.Repeat("value", 0);

            Assert.Equal(Maybe<string>.None, source.LastOrNone(x => true));
            Assert.Equal(Maybe<string>.None, source.LastOrNone(x => false));
        }

        [Fact(DisplayName = "OneElementNotIListTruePredicate")]
        public static void LastOrNone17()
        {
            IEnumerable<int> source = ForceNotCollection(new[] { 4 });
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(4);

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "ManyElementsNotIListPredicateFalseForAll")]
        public static void LastOrNone18()
        {
            IEnumerable<int> source = ForceNotCollection(new int[] { 9, 5, 1, 3, 17, 21 });
            Func<int, bool> predicate = IsEven;
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "NotIListPredicateTrueOnlyForLast")]
        public static void LastOrNone19()
        {
            IEnumerable<int> source = ForceNotCollection(new int[] { 9, 5, 1, 3, 17, 21, 50 });
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(50);

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "NotIListPredicateTrueForSome")]
        public static void LastOrNone20()
        {
            IEnumerable<int> source = ForceNotCollection(new int[] { 3, 7, 10, 7, 9, 2, 11, 18, 13, 9 });
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(18);

            Assert.Equal(expected, source.LastOrNone(predicate));
        }

        [Fact(DisplayName = "NotIListPredicateTrueForSomeRunOnce")]
        public static void LastOrNone21()
        {
            IEnumerable<int> source = ForceNotCollection(new int[] { 3, 7, 10, 7, 9, 2, 11, 18, 13, 9 });
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(18);

            Assert.Equal(expected, source.RunOnce().LastOrNone(predicate));
        }
    }
}

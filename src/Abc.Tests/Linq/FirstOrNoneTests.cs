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

// Adapted from https://github.com/dotnet/corefx/blob/master/src/System.Linq/tests/FirstOrDefaultTests.cs

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Linq.Tests;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class FirstOrNoneTests : QperatorsTests { }

    // Arg check.
    public partial class FirstOrNoneTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () => NullSeq.FirstOrNone());

        [Fact]
        public static void NullSource_WithPredicate() =>
            Assert.ThrowsAnexn("source", () =>
                NullSeq.FirstOrNone(Funk<int, bool>.Any));

        [Fact]
        public static void NullPredicate() =>
            Assert.ThrowsAnexn("predicate", () =>
                AnySeq.FirstOrNone(Funk<int, bool>.Null));
    }

    public partial class FirstOrNoneTests
    {
        [Fact(DisplayName = "FirstOrNone() for int's returns the same result when called repeatedly.")]
        public static void FirstOrNone1()
        {
            var source = Enumerable.Range(0, 0);

            var q = from x in source select x;

            Assert.Equal(q.FirstOrNone(), q.FirstOrNone());
        }

        [Fact(DisplayName = "FirstOrNone() for string's returns the same result when called repeatedly.")]
        public static void FirstOrNone2()
        {
            var q = from x in new[] { "!@#$%^", "C", "AAA", "", "Calling Twice", "SoS", String.Empty }
                    where !String.IsNullOrEmpty(x)
                    select x;

            Assert.Equal(q.FirstOrNone(), q.FirstOrNone());
        }

        private static void FirstOrNone3Impl<T>()
        {
            T[] source = ArrayEx.Empty<T>();
            var expected = Maybe<T>.None;

            Assert.IsAssignableFrom<IList<T>>(source);
            Assert.Equal(expected, source.RunOnce().FirstOrNone());
        }

        [Fact(DisplayName = "FirstOrNone() for an empty IList<T>.")]
        public static void FirstOrNone3()
        {
            FirstOrNone3Impl<int>();
            FirstOrNone3Impl<string>();
            FirstOrNone3Impl<DateTime>();
            FirstOrNone3Impl<QperatorsTests>();
        }

        [Fact(DisplayName = "FirstOrNone() for an IList<T> of one element.")]
        public static void FirstOrNone4()
        {
            int[] source = { 5 };
            var expected = Maybe.Some(5);

            Assert.IsAssignableFrom<IList<int>>(source);
            Assert.Equal(expected, source.FirstOrNone());
        }

        [Fact(DisplayName = "FirstOrNone() for an IList<T> of many elements whose first is none.")]
        public static void FirstOrNone5()
        {
            string[] source = { null!, "!@#$%^", "C", "AAA", "", "Calling Twice", "SoS" };
            var expected = Maybe<string>.None;

            Assert.IsAssignableFrom<IList<string>>(source);
            Assert.Equal(expected, source.FirstOrNone());
        }

        [Fact(DisplayName = "FirstOrNone() for an IList<T> of many elements whose first is some.")]
        public static void FirstOrNone6()
        {
            string[] source = { "!@#$%^", null!, "C", "AAA", "", "Calling Twice", "SoS" };
            var expected = Maybe.SomeOrNone("!@#$%^");

            Assert.IsAssignableFrom<IList<string>>(source);
            Assert.Equal(expected, source.FirstOrNone());
        }

        private static void FirstOrNone7Impl<T>()
        {
            var source = Enumerable.Empty<T>();
            var expected = Maybe<T>.None;

#if NETCOREAPP2_x || NETFRAMEWORK // Enumerable.Empty
            Assert.Empty(source as IList<T>);
#else
            Assert.Null(source as IList<T>);
#endif

            Assert.Equal(expected, source.RunOnce().FirstOrNone());
        }

        [Fact(DisplayName = "EmptyNotIListT")]
        public static void FirstOrNone7()
        {
            FirstOrNone7Impl<int>();
            FirstOrNone7Impl<string>();
            FirstOrNone7Impl<DateTime>();
            FirstOrNone7Impl<QperatorsTests>();
        }

        [Fact(DisplayName = "OneElementNotIListT")]
        public static void FirstOrNone8()
        {
            IEnumerable<int> source = NumberRangeGuaranteedNotCollectionType(-5, 1);
            var expected = Maybe.Some(-5);

            Assert.Null(source as IList<int>);
            Assert.Equal(expected, source.FirstOrNone());
        }

        [Fact(DisplayName = "ManyElementsNotIListT")]
        public static void FirstOrNone9()
        {
            IEnumerable<int> source = NumberRangeGuaranteedNotCollectionType(3, 10);
            var expected = Maybe.Some(3);

            Assert.Null(source as IList<int>);
            Assert.Equal(expected, source.FirstOrNone());
        }

        [Fact(DisplayName = "EmptySource")]
        public static void FirstOrNone10()
        {
            string[] source = ArrayEx.Empty<string>();
            var expected = Maybe<string>.None;

            Assert.Equal(expected, source.FirstOrNone(x => true));
            Assert.Equal(expected, source.FirstOrNone(x => false));
        }

        [Fact(DisplayName = "FirstOrNone() on a list of one element returns some.")]
        public static void FirstOrNone11()
        {
            int[] source = { 4 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(4);

            Assert.Equal(expected, source.FirstOrNone(predicate));
        }

        [Fact(DisplayName = "FirstOrNone() w/ predicate always false returns none.")]
        public static void FirstOrNone12()
        {
            int[] source = { 9, 5, 1, 3, 17, 21 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.FirstOrNone(predicate));
        }

        [Fact(DisplayName = "FirstOrNone() w/ predicate returns last.")]
        public static void FirstOrNone13()
        {
            int[] source = { 9, 5, 1, 3, 17, 21, 50 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(50);

            Assert.Equal(expected, source.FirstOrNone(predicate));
        }

        [Fact(DisplayName = "FirstOrNone() w/ predicate returns some (1).")]
        public static void FirstOrNone14()
        {
            int[] source = { 3, 7, 10, 7, 9, 2, 11, 17, 13, 8 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(10);

            Assert.Equal(expected, source.FirstOrNone(predicate));
        }

        [Fact(DisplayName = "FirstOrNone() w/ predicate returns some (2).")]
        public static void FirstOrNone15()
        {
            int[] source = { 3, 7, 10, 7, 9, 2, 11, 17, 13, 8 };
            Func<int, bool> predicate = IsEven;
            var expected = Maybe.Some(10);

            Assert.Equal(expected, source.RunOnce().FirstOrNone(predicate));
        }
    }
}

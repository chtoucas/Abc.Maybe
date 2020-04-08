// See LICENSE.dotnet in the project root for license information.
//
// https://github.com/dotnet/corefx/blob/master/src/System.Linq/tests/SingleOrDefaultTests.cs

namespace Abc.Linq
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Linq.Tests;

    using Xunit;

    using Assert = AssertEx;

    public sealed partial class SingleOrNoneTests : QperatorsTests { }

    // Arg check.
    public partial class SingleOrNoneTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () => NullSeq.SingleOrNone());

        [Fact]
        public static void NullSource_WithPredicate() =>
            Assert.ThrowsAnexn("source", () => NullSeq.SingleOrNone(Funk<int, bool>.Any));

        [Fact]
        public static void NullPredicate() =>
            Assert.ThrowsAnexn("predicate", () => AnySeq.SingleOrNone(Funk<int, bool>.Null));
    }

    public partial class SingleOrNoneTests
    {
        [Fact(DisplayName = "SingleOrNone() for int's returns the same result when called repeatedly.")]
        public static void SingleOrNone1()
        {
            var q = from x in new[] { 0.12335f }
                    select x;

            Assert.Equal(q.SingleOrNone(), q.SingleOrNone());
        }

        [Fact(DisplayName = "SingleOrNone() for string's returns the same result when called repeatedly.")]
        public static void SingleOrNone2()
        {
            var q = from x in new[] { "" }
                    select x;

            Assert.Equal(q.SingleOrNone(String.IsNullOrEmpty), q.SingleOrNone(String.IsNullOrEmpty));
        }

        [Fact(DisplayName = "EmptyIList")]
        public static void SingleOrNone3()
        {
            string[] source = Array.Empty<string>();
            var expected = Maybe<string>.None;

            Assert.Equal(expected, source.SingleOrNone());
        }

        [Fact(DisplayName = "SingleElementIList")]
        public static void SingleOrNone4()
        {
            int[] source = { 4 };
            var expected = Maybe.Of(4);

            Assert.Equal(expected, source.SingleOrNone());
        }

        [Fact(DisplayName = "ManyElementIList")]
        public static void SingleOrNone5()
        {
            int[] source = { 4, 4, 4, 4, 4 };
            var expected = Maybe<int>.None;

            // NB: SingleOrDefault() throws InvalidOperationException.
            Assert.Equal(expected, source.SingleOrNone());
        }

        [Fact(DisplayName = "EmptyNotIList")]
        public static void SingleOrNone6()
        {
            IEnumerable<int> source = RepeatedNumberGuaranteedNotCollectionType(0, 0);
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.SingleOrNone());
        }

        [Fact(DisplayName = "SingleElementNotIList")]
        public static void SingleOrNone7()
        {
            IEnumerable<int> source = RepeatedNumberGuaranteedNotCollectionType(-5, 1);
            var expected = Maybe.Of(-5);

            Assert.Equal(expected, source.SingleOrNone());
        }

        [Fact(DisplayName = "ManyElementNotIList")]
        public static void SingleOrNone8()
        {
            IEnumerable<int> source = RepeatedNumberGuaranteedNotCollectionType(3, 5);
            var expected = Maybe<int>.None;

            // NB: SingleOrDefault() throws InvalidOperationException.
            Assert.Equal(expected, source.SingleOrNone());
        }

        [Fact(DisplayName = "EmptySourceWithPredicate")]
        public static void SingleOrNone9()
        {
            int[] source = Array.Empty<int>();
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.SingleOrNone(i => i % 2 == 0));
        }

        [Fact(DisplayName = "SingleElementPredicateTrue")]
        public static void SingleOrNone10()
        {
            int[] source = { 4 };
            var expected = Maybe.Of(4);

            Assert.Equal(expected, source.SingleOrNone(i => i % 2 == 0));
        }

        [Fact(DisplayName = "SingleElementPredicateFalse")]
        public static void SingleOrNone11()
        {
            int[] source = { 3 };
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.SingleOrNone(i => i % 2 == 0));
        }

        [Fact(DisplayName = "ManyElementsPredicateFalseForAll")]
        public static void SingleOrNone12()
        {
            int[] source = { 3, 1, 7, 9, 13, 19 };
            var expected = Maybe<int>.None;

            Assert.Equal(expected, source.SingleOrNone(i => i % 2 == 0));
        }

        [Fact(DisplayName = "ManyElementsPredicateTrueForLast")]
        public static void SingleOrNone13()
        {
            int[] source = { 3, 1, 7, 9, 13, 19, 20 };
            var expected = Maybe.Of(20);

            Assert.Equal(expected, source.SingleOrNone(i => i % 2 == 0));
        }

        [Fact(DisplayName = "ManyElementsPredicateTrueForFirstAndFifth")]
        public static void SingleOrNone14()
        {
            int[] source = { 2, 3, 1, 7, 10, 13, 19, 9 };
            var expected = Maybe<int>.None;

            // NB: SingleOrDefault() throws InvalidOperationException.
            Assert.Equal(expected, source.SingleOrNone(i => i % 2 == 0));
        }

        [Theory(DisplayName = "FindSingleMatch")]
        [InlineData(1, 100)]
        [InlineData(42, 100)]
        public static void SingleOrNone15(int target, int range)
        {
            var expected = Maybe.Of(target);
            Assert.Equal(expected, Enumerable.Range(0, range).SingleOrNone(i => i == target));
        }

        [Theory(DisplayName = "RunOnce")]
        [InlineData(1, 100)]
        [InlineData(42, 100)]
        public static void SingleOrNone16(int target, int range)
        {
            var expected = Maybe.Of(target);
            Assert.Equal(expected, Enumerable.Range(0, range).RunOnce().SingleOrNone(i => i == target));
        }
    }
}

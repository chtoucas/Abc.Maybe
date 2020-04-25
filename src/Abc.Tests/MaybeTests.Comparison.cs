// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

    // See MaybeTests.Equality & MaybeTests.Ordering.

    // Not actually a test of Maybe.
    public partial class MaybeTests
    {
        // Comparison w/ null is "weird".
        //   "For the comparison operators <, >, <=, and >=, if one or both
        //   operands are null, the result is false; otherwise, the contained
        //   values of operands are compared. Do not assume that because a
        //   particular comparison (for example, <=) returns false, the opposite
        //   comparison (>) returns true."
        // https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/nullable-value-types#lifted-operators
        //   "Basically the rule here is that nulls compare for equality normally,
        //   but any other comparison results in false."
        // https://ericlippert.com/2015/08/31/nullable-comparisons-are-weird/
        // Three options (extracts from Lippert's article):
        // 1) Make comparison operators produce nullable bool.
        // 2) Make comparison operators produce bool, and say that
        //    greater-than-or-equal comparisons to null have the same semantics
        //    as "or-ing" together the greater-than and equals operations.
        // 3) Make comparison operators produce a bool and apply a total
        //    ordering.
        // Choice 3 is for sorting.
        [Fact]
        public static void Nullable_Comparisons()
        {
            // Arrange
            int? one = 1;
            int? nil = null;
            // Default comparer for nullable int.
            var cmp = Comparer<int?>.Default;

            // Act & Assert
            // If one of the operand is null, the comparison returns false.
            // Important consequence: we can't say that "x >= y" is equivalent
            // to "not(x < y)"...
            Assert.False(one < nil);    // false
            Assert.False(one > nil);    // false    "contradicts" Compare; see below
            Assert.False(one <= nil);   // false
            Assert.False(one >= nil);   // false

            // Equality is fine.
            Assert.False(one == nil);   // false
            Assert.True(one != nil);    // true

#pragma warning disable CS1718 // Comparison made to same variable
            Assert.False(nil < nil);    // false
            Assert.False(nil > nil);    // false
            Assert.False(nil <= nil);   // false    weird
            Assert.False(nil >= nil);   // false    weird

            Assert.True(nil == nil);    // true
            Assert.False(nil != nil);   // false
#pragma warning restore CS1718

            Assert.Equal(1, cmp.Compare(one, nil));    // "one > nil"
            Assert.Equal(-1, cmp.Compare(nil, one));   // "nil < one"
            Assert.Equal(0, cmp.Compare(nil, nil));    // "nil >= nil"
        }

        [Fact]
        public static void Nullable_Comparisons_ForNotComparable()
        {
            // Arrange
            MyNotComparableStruct? x = new MyNotComparableStruct { Value = "XXX" };
            MyNotComparableStruct? y = new MyNotComparableStruct { Value = "YYY" };
            MyNotComparableStruct? nil = null;
            var cmp = Comparer<MyNotComparableStruct?>.Default;

            // Act & Assert
            Assert.Equal(1, cmp.Compare(x, nil));
            Assert.Equal(-1, cmp.Compare(nil, x));
            Assert.Equal(0, cmp.Compare(nil, nil));

            Assert.ThrowsArgexn(() => cmp.Compare(x, x));
            Assert.ThrowsArgexn(() => cmp.Compare(x, y));
        }

        [Fact]
        public static void ValueTuple_Comparisons_ForNotComparable()
        {
            // Arrange
            var x = ValueTuple.Create(new MyNotComparableStruct { Value = "XXX" });
            var y = ValueTuple.Create(new MyNotComparableStruct { Value = "YYY" });
            var cmp = Comparer<ValueTuple<MyNotComparableStruct?>>.Default;
            // Act & Assert
            Assert.ThrowsArgexn(() => cmp.Compare(x, x));
            Assert.ThrowsArgexn(() => cmp.Compare(x, y));
        }
    }
}
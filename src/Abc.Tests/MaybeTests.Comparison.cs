// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Collections;
    using System.Collections.Generic;

    using Xunit;

    using Assert = AssertEx;

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
            int? one = 1;
            int? nil = null;
            // Default comparer for nullable int.
            var cmp = Comparer<int?>.Default;

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
            MyNotComparableStruct_? x = new MyNotComparableStruct_ { Value = "XXX" };
            MyNotComparableStruct_? y = new MyNotComparableStruct_ { Value = "YYY" };
            MyNotComparableStruct_? nil = null;
            var cmp = Comparer<MyNotComparableStruct_?>.Default;

            Assert.Equal(1, cmp.Compare(x, nil));
            Assert.Equal(-1, cmp.Compare(nil, x));
            Assert.Equal(0, cmp.Compare(nil, nil));

            Assert.ThrowsArgexn(() => cmp.Compare(x, x));
            Assert.ThrowsArgexn(() => cmp.Compare(x, y));
        }

        private struct MyNotComparableStruct_
        {
            public string Value;
        }
    }

    // Order comparison.
    //
    // Expected algebraic properties.
    //   1) Reflexivity     x <= x
    //   2) Anti-symmetry   (x <= y and y <= x) => x = y
    //   3) Transitivity    (x <= y and y <= z) => x <= z
    //
    // Beware, <= does NOT define a proper ordering when none is included.
    public partial class MaybeTests
    {
        #region Comparison ops

        // Comparison with none always returns "false".

        [Fact]
        public static void Comparison_None_None()
        {
            // Arrange
            Maybe<int> none = Ø;
            // Act & Assert
            Assert.False(none < Ø);
            Assert.False(none <= Ø);
            Assert.False(none > Ø);
            Assert.False(none >= Ø);
        }

        [Fact]
        public static void Comparison_None_None_ForNotComparable()
        {
            // Arrange
            var none = AnyT.None;
            // Act & Assert
            Assert.False(none < AnyT.None);
            Assert.False(none <= AnyT.None);
            Assert.False(none > AnyT.None);
            Assert.False(none >= AnyT.None);
        }

        [Fact]
        public static void Comparison_None_Some()
        {
            Assert.False(Ø < One);
            Assert.False(Ø <= One);
            Assert.False(Ø > One);
            Assert.False(Ø >= One);

            Assert.False(One < Ø);
            Assert.False(One <= Ø);
            Assert.False(One > Ø);
            Assert.False(One >= Ø);
        }

        [Fact]
        public static void Comparison_None_Some_ForNotComparable()
        {
            // Arrange
            var some = AnyT.Some;

            // Act & Assert
            Assert.False(AnyT.None < some);
            Assert.False(AnyT.None <= some);
            Assert.False(AnyT.None > some);
            Assert.False(AnyT.None >= some);

            Assert.False(some < AnyT.None);
            Assert.False(some <= AnyT.None);
            Assert.False(some > AnyT.None);
            Assert.False(some >= AnyT.None);
        }

        [Fact]
        public static void Comparison_Some_Some()
        {
            Assert.True(One < Two);
            Assert.True(One <= Two);
            Assert.False(One > Two);
            Assert.False(One >= Two);

            Assert.False(Two < One);
            Assert.False(Two <= One);
            Assert.True(Two > One);
            Assert.True(Two >= One);
        }

        [Fact]
        public static void Comparison_Some_Some_ForNotComparable()
        {
            // Arrange
            var x = AnyT.Some;
            var y = AnyT.Some;
            // Act & Assert
            Assert.ThrowsArgexn(() => x < y);
            Assert.ThrowsArgexn(() => x <= y);
            Assert.ThrowsArgexn(() => x > y);
            Assert.ThrowsArgexn(() => x >= y);
        }

        [Fact]
        public static void Comparison_Some_Some_Identical()
        {
            // Arrange
            Maybe<int> one = One;
            // Act & Assert
            Assert.False(One < one);
            Assert.True(One <= one);
            Assert.False(One > one);
            Assert.True(One >= one);
        }

        [Fact(Skip = "Not comparable")]
        public static void Comparison_Some_Some_Identical_ForNotComparable()
        {
            // Arrange
            var x = AnyT.Some;
            var copy = x;
            // Act & Assert
            Assert.ThrowsArgexn(() => x < copy);
            Assert.ThrowsArgexn(() => x <= copy);
            Assert.ThrowsArgexn(() => x > copy);
            Assert.ThrowsArgexn(() => x >= copy);
        }

        #endregion

        #region CompareTo()

        [Fact]
        public static void CompareTo_None_WithNone() =>
            Assert.Equal(0, Ø.CompareTo(Ø));

        [Fact]
        public static void CompareTo_None_WithNone_ForNotComparable() =>
            Assert.Equal(0, AnyT.None.CompareTo(AnyT.None));

        [Fact]
        public static void CompareTo_None_WithSome()
        {
            Assert.Equal(-1, Ø.CompareTo(One));
            Assert.Equal(-1, Ø.CompareTo(Two));
        }

        [Fact]
        public static void CompareTo_None_WithSome_ForNotComparable() =>
            Assert.Equal(-1, AnyT.None.CompareTo(AnyT.Some));

        [Fact]
        public static void CompareTo_Some_WithNone()
        {
            Assert.Equal(1, One.CompareTo(Ø));
            Assert.Equal(1, Two.CompareTo(Ø));
        }

        [Fact]
        public static void CompareTo_Some_WithNone_ForNotComparable() =>
            Assert.Equal(1, AnyT.Some.CompareTo(AnyT.None));

        [Fact]
        public static void CompareTo_Some_WithSome_AndIdentical() => Assert.Equal(0, One.CompareTo(One));

        [Fact(Skip = "Not comparable")]
        public static void CompareTo_Some_WithSome_AndIdentical_ForNotComparable()
        {
            // Arrange
            var x = AnyT.Some;
            // Act & Assert
            Assert.ThrowsArgexn(() => x.CompareTo(x));
        }

        [Fact]
        public static void CompareTo_Some_WithSome_AndDifferent()
        {
            Assert.Equal(1, Two.CompareTo(One));
            Assert.Equal(-1, One.CompareTo(Two));
        }

        [Fact]
        public static void CompareTo_Some_WithSome_AndDifferent_ForNotComparable() =>
            Assert.ThrowsArgexn(() => AnyT.Some.CompareTo(AnyT.Some));

        #endregion

        #region Comparable

        [Fact]
        public static void Comparable_None_WithNull()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.Equal(1, none.CompareTo(null));
        }

        [Fact]
        public static void Comparable_Some_WithNull()
        {
            // Arrange
            IComparable one = One;
            // Act & Assert
            Assert.Equal(1, one.CompareTo(null));
        }

        [Fact]
        public static void Comparable_None_WithInvalidType()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.ThrowsArgexn("obj", () => none.CompareTo(new object()));
            Assert.ThrowsArgexn("obj", () => none.CompareTo(NoText));
            Assert.ThrowsArgexn("obj", () => none.CompareTo(SomeText));
        }

        [Fact]
        public static void Comparable_Some_WithInvalidType()
        {
            // Arrange
            IComparable one = One;
            // Act & Assert
            Assert.ThrowsArgexn("obj", () => one.CompareTo(new object()));
            Assert.ThrowsArgexn("obj", () => one.CompareTo(NoText));
            Assert.ThrowsArgexn("obj", () => one.CompareTo(SomeText));
        }

        [Fact]
        public static void Comparable_None()
        {
            // Arrange
            IComparable none = Ø;
            // Act & Assert
            Assert.Equal(-1, none.CompareTo(One));
            Assert.Equal(0, none.CompareTo(Ø));
            Assert.Equal(-1, none.CompareTo(Two));
        }

        [Fact]
        public static void Comparable_Some()
        {
            // Arrange
            IComparable one = One;
            IComparable two = Two;

            // Act & Assert
            Assert.Equal(1, one.CompareTo(Ø));
            Assert.Equal(1, two.CompareTo(Ø));

            Assert.Equal(0, one.CompareTo(One));
            Assert.Equal(0, two.CompareTo(Two));

            Assert.Equal(-1, one.CompareTo(Two));
            Assert.Equal(1, two.CompareTo(One));
        }

        #endregion

        [Fact]
        public static void Comparable_ForNotComparable()
        {
            // Arrange
            IComparable x = AnyT.Some;
            IComparable y = AnyT.Some;
            // Act & Assert
            Assert.ThrowsArgexn(() => x.CompareTo(y));
        }
    }

    // Equality.
    //
    // Expected algebraic properties.
    //   1) Reflexivity
    //   2) Symmetry
    //   3) Transitivity
    public partial class MaybeTests
    {
        [Fact]
        public static void Equality_None_ForValueT()
        {
            // Arrange
            var none = Maybe<int>.None;
            var same = Maybe<int>.None;
            var notSame = Maybe.Some(2);

            // Act & Assert
            Assert.True(none == same);
            Assert.True(same == none);
            Assert.False(none == notSame);
            Assert.False(notSame == none);

            Assert.False(none != same);
            Assert.False(same != none);
            Assert.True(none != notSame);
            Assert.True(notSame != none);

            Assert.True(none.Equals(none));
            Assert.True(none.Equals(same));
            Assert.True(same.Equals(none));
            Assert.False(none.Equals(notSame));
            Assert.False(notSame.Equals(none));

            Assert.True(none.Equals((object)same));
            Assert.False(none.Equals((object)notSame));

            Assert.False(none.Equals(null));
            Assert.False(none.Equals(new object()));
        }

        [Fact]
        public static void Equality_Some_ForValueT()
        {
            // Arrange
            var some = Maybe.Some(1);
            var same = Maybe.Some(1);
            var notSame = Maybe.Some(2);

            // Act & Assert
            Assert.True(some == same);
            Assert.True(same == some);
            Assert.False(some == notSame);
            Assert.False(notSame == some);

            Assert.False(some != same);
            Assert.False(same != some);
            Assert.True(some != notSame);
            Assert.True(notSame != some);

            Assert.True(some.Equals(some));
            Assert.True(some.Equals(same));
            Assert.True(same.Equals(some));
            Assert.False(some.Equals(notSame));
            Assert.False(notSame.Equals(some));

            Assert.True(some.Equals((object)same));
            Assert.False(some.Equals((object)notSame));

            Assert.False(some.Equals(null));
            Assert.False(some.Equals(new object()));
        }

        [Fact]
        public static void Equality_None_ForReferenceT()
        {
            // Arrange
            var none = Maybe<AnyT>.None;
            var same = Maybe<AnyT>.None;
            var notSame = Maybe.SomeOrNone(AnyT.Value);

            // Act & Assert
            Assert.True(none == same);
            Assert.True(same == none);
            Assert.False(none == notSame);
            Assert.False(notSame == none);

            Assert.False(none != same);
            Assert.False(same != none);
            Assert.True(none != notSame);
            Assert.True(notSame != none);

            Assert.True(none.Equals(none));
            Assert.True(none.Equals(same));
            Assert.True(same.Equals(none));
            Assert.False(none.Equals(notSame));
            Assert.False(notSame.Equals(none));

            Assert.True(none.Equals((object)same));
            Assert.False(none.Equals((object)notSame));

            Assert.False(none.Equals(null));
            Assert.False(none.Equals(new object()));
        }

        [Fact]
        public static void Equality_Some_ForReferenceT()
        {
            // Arrange
            var anyT = AnyT.Value;
            var some = Maybe.SomeOrNone(anyT);
            var same = Maybe.SomeOrNone(anyT);
            var notSame = Maybe.SomeOrNone(AnyT.Value);

            // Act & Assert
            Assert.True(some == same);
            Assert.True(same == some);
            Assert.False(some == notSame);
            Assert.False(notSame == some);

            Assert.False(some != same);
            Assert.False(same != some);
            Assert.True(some != notSame);
            Assert.True(notSame != some);

            Assert.True(some.Equals(some));
            Assert.True(some.Equals(same));
            Assert.True(same.Equals(some));
            Assert.False(some.Equals(notSame));
            Assert.False(notSame.Equals(some));

            Assert.True(some.Equals((object)same));
            Assert.False(some.Equals((object)notSame));

            Assert.False(some.Equals(null));
            Assert.False(some.Equals(new object()));
        }

        [Fact]
        public static void GetHashCode_None()
        {
            Assert.Equal(0, Ø.GetHashCode());
            Assert.Equal(0, ØL.GetHashCode());
            Assert.Equal(0, NoText.GetHashCode());
            Assert.Equal(0, NoUri.GetHashCode());
            Assert.Equal(0, AnyT.None.GetHashCode());
        }

        [Fact]
        public static void GetHashCode_Some()
        {
            Assert.Equal(1.GetHashCode(), One.GetHashCode());
            Assert.Equal(2.GetHashCode(), Two.GetHashCode());
            Assert.Equal(2L.GetHashCode(), TwoL.GetHashCode());
            Assert.Equal(MyText.GetHashCode(StringComparison.Ordinal), SomeText.GetHashCode());
            Assert.Equal(MyUri.GetHashCode(), SomeUri.GetHashCode());

            var anyT = AnyT.New();
            Assert.Equal(anyT.Value.GetHashCode(), anyT.Some.GetHashCode());
        }
    }

    // Structural order comparison.
    public partial class MaybeTests
    {
        [Fact]
        public static void CompareTo_Structural_None_WithNullComparer()
        {
            // Arrange
            IStructuralComparable none = Ø;
            // Act & Assert
            Assert.ThrowsAnexn("comparer", () => none.CompareTo(One, null!));
        }

        [Fact]
        public static void CompareTo_Structural_Some_WithNullComparer()
        {
            // Arrange
            IStructuralComparable one = One;
            // Act & Assert
            Assert.ThrowsAnexn("comparer", () => one.CompareTo(One, null!));
        }

        [Fact]
        public static void CompareTo_Structural()
        {
            // Arrange
            var cmp = Comparer<int>.Default;
            IStructuralComparable none = Ø;
            IStructuralComparable one = One;
            IStructuralComparable two = Two;

            // Act & Assert
            Assert.ThrowsArgexn("other", () => none.CompareTo(new object(), cmp));
            Assert.ThrowsArgexn("other", () => one.CompareTo(new object(), cmp));

            Assert.Equal(1, none.CompareTo(null, cmp));
            Assert.Equal(1, one.CompareTo(null, cmp));

            // With None
            Assert.Equal(1, one.CompareTo(Ø, cmp));
            Assert.Equal(-1, none.CompareTo(One, cmp));
            Assert.Equal(0, none.CompareTo(Ø, cmp));

            // Without None
            Assert.Equal(1, two.CompareTo(One, cmp));
            Assert.Equal(0, one.CompareTo(One, cmp));
            Assert.Equal(-1, one.CompareTo(Two, cmp));
        }
    }

    // Structural equality.
    public partial class MaybeTests
    {
        [Fact]
        public static void Equals_Structural_WithNullComparer()
        {
            // Arrange
            IStructuralEquatable one = One;
            // Act & Assert
            Assert.ThrowsAnexn("comparer", () => one.Equals(One, null!));
        }

        [Fact]
        public static void Equals_Structural_None_ForValueT()
        {
            // Arrange
            IStructuralEquatable none = Maybe<int>.None;
            var same = Maybe<int>.None;
            var some = Maybe.Some(2);
            var cmp = EqualityComparer<int>.Default;

            // Act & Assert
            Assert.False(none.Equals(null, cmp));
            Assert.False(none.Equals(new object(), cmp));

            Assert.True(none.Equals(none, cmp));
            Assert.True(none.Equals(same, cmp));

            Assert.False(none.Equals(some, cmp));
        }

        [Fact]
        public static void Equals_Structural_Some_ForValueT()
        {
            // Arrange
            IStructuralEquatable some = Maybe.Some(1);
            var same = Maybe.Some(1);
            var notSame = Maybe.Some(2);
            var none = Maybe<int>.None;
            var cmp = EqualityComparer<int>.Default;

            // Act & Assert
            Assert.False(some.Equals(null, cmp));
            Assert.False(some.Equals(new object(), cmp));

            Assert.True(some.Equals(some, cmp));
            Assert.True(some.Equals(same, cmp));
            Assert.False(some.Equals(notSame, cmp));

            Assert.False(some.Equals(none, cmp));
        }

        [Fact]
        public static void Equals_Structural_None_ForReferenceT()
        {
            // Arrange
            IStructuralEquatable none = Maybe<AnyT>.None;
            var same = Maybe<AnyT>.None;
            var some = Maybe.SomeOrNone(AnyT.Value);
            var cmp = EqualityComparer<AnyT>.Default;

            // Act & Assert
            Assert.False(none.Equals(null, cmp));
            Assert.False(none.Equals(new object(), cmp));

            Assert.True(none.Equals(none, cmp));
            Assert.True(none.Equals(same, cmp));

            Assert.False(none.Equals(some, cmp));
        }

        [Fact]
        public static void Equals_Structural_Some_ForReferenceT_WithDefaultComparer()
        {
            // Arrange
            var anyT = AnyT.Value;
            IStructuralEquatable some = Maybe.SomeOrNone(anyT);
            var same = Maybe.SomeOrNone(anyT);
            var notSame = Maybe.SomeOrNone(AnyT.Value);
            var none = Maybe<AnyT>.None;
            var cmp = EqualityComparer<AnyT>.Default;

            // Act & Assert
            Assert.False(some.Equals(null, cmp));
            Assert.False(some.Equals(new object(), cmp));

            Assert.True(some.Equals(some, cmp));
            Assert.True(some.Equals(same, cmp));
            Assert.False(some.Equals(notSame, cmp));

            Assert.False(some.Equals(none, cmp));
        }

        [Fact]
        public static void Equals_Structural_Some_ForReferenceT_WithCustomComparer()
        {
            // Arrange
            IStructuralEquatable anagram = Maybe.SomeOrNone(Anagram);
            var margana = Maybe.SomeOrNone(Margana);
            var other = Maybe.SomeOrNone("XXX");
            var none = Maybe<string>.None;
            var cmp = new AnagramEqualityComparer();

            // Act & Assert
            Assert.True(anagram.Equals(anagram));
            Assert.False(anagram.Equals(margana));
            Assert.False(anagram.Equals(other));
            Assert.False(anagram.Equals(none));
            Assert.False(anagram.Equals(new object()));

            Assert.True(anagram.Equals(anagram, cmp));
            Assert.True(anagram.Equals(margana, cmp));
            Assert.False(anagram.Equals(other, cmp));
            Assert.False(anagram.Equals(none, cmp));
            Assert.False(anagram.Equals(new object(), cmp));
            Assert.False(anagram.Equals(null, cmp));

            // REVIEW: very odd, after Equals(null), we must use !.
            Assert.False(anagram.Equals(null));
        }

        [Fact]
        public static void GetHashCode_Structural_WithNullComparer()
        {
            // Arrange
            IStructuralEquatable one = One;
            // Act & Assert
            Assert.ThrowsAnexn("comparer", () => one.GetHashCode(null!));
        }

        [Fact]
        public static void GetHashCode_Structural_None_WithDefaultComparer()
        {
            // Arrange
            var icmp = EqualityComparer<int>.Default;
            var lcmp = EqualityComparer<long>.Default;
            var scmp = EqualityComparer<string>.Default;
            var ucmp = EqualityComparer<Uri>.Default;
            var acmp = EqualityComparer<AnyT>.Default;
            // Act & Assert
            Assert.Equal(0, ((IStructuralEquatable)Ø).GetHashCode(icmp));
            Assert.Equal(0, ((IStructuralEquatable)ØL).GetHashCode(lcmp));
            Assert.Equal(0, ((IStructuralEquatable)NoText).GetHashCode(scmp));
            Assert.Equal(0, ((IStructuralEquatable)NoUri).GetHashCode(ucmp));
            Assert.Equal(0, ((IStructuralEquatable)AnyT.None).GetHashCode(acmp));
        }

        [Fact]
        public static void GetHashCode_Structural_None_WithCustomComparer()
        {
            // Arrange
            var cmp = new AnagramEqualityComparer();
            // Act & Assert
            Assert.Equal(0, ((IStructuralEquatable)NoText).GetHashCode(cmp));
        }

        [Fact]
        public static void GetHashCode_Structural_Some_WithDefaultComparer()
        {
            // Arrange
            var icmp = EqualityComparer<int>.Default;
            var lcmp = EqualityComparer<long>.Default;
            var scmp = EqualityComparer<string>.Default;
            var ucmp = EqualityComparer<Uri>.Default;
            var acmp = EqualityComparer<AnyT>.Default;
            // Act & Assert
            Assert.Equal(icmp.GetHashCode(1), ((IStructuralEquatable)One).GetHashCode(icmp));
            Assert.Equal(icmp.GetHashCode(2), ((IStructuralEquatable)Two).GetHashCode(icmp));
            Assert.Equal(lcmp.GetHashCode(2L), ((IStructuralEquatable)TwoL).GetHashCode(lcmp));
            Assert.Equal(scmp.GetHashCode(MyText), ((IStructuralEquatable)SomeText).GetHashCode(scmp));
            Assert.Equal(ucmp.GetHashCode(MyUri), ((IStructuralEquatable)SomeUri).GetHashCode(ucmp));

            var anyT = AnyT.New();
            Assert.Equal(acmp.GetHashCode(anyT.Value), ((IStructuralEquatable)anyT.Some).GetHashCode(acmp));
        }

        [Fact]
        public static void GetHashCode_Structural_Some_WithCustomComparer()
        {
            // Arrange
            var cmp = new AnagramEqualityComparer();
            // Act & Assert
            Assert.Equal(cmp.GetHashCode(MyText), ((IStructuralEquatable)SomeText).GetHashCode(cmp));
        }
    }

    // Equality w/ composite objects.
    public partial class MaybeTests
    {
        [Fact]
        public static void Equality_CompositeObject()
        {
            // Arrange
            var v1 = AnyT.Value;
            var v2 = AnyT.Value;
            var v3 = AnyT.Value;
            var v4 = AnyT.Value;
            var xs = new List<Maybe<AnyT>>
            {
                Maybe.SomeOrNone(v1),
                Maybe.SomeOrNone(v2),
                Maybe.SomeOrNone(v3),
                Maybe.SomeOrNone(v4),
            };
            var ys = new List<Maybe<AnyT>>
            {
                Maybe.SomeOrNone(v1),
                Maybe.SomeOrNone(v2),
                Maybe.SomeOrNone(v3),
                Maybe.SomeOrNone(v4),
            };
            // Assert
            // The object references are different.
            Assert.NotSame(xs, ys);
            // The objets are different too using the types's default comparer.
            Assert.NotStrictEqual(xs, ys);
            // The objets are equal using the default comparer.
            Assert.Equal(xs, ys);
        }
    }
}

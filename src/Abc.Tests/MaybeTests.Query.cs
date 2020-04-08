// See LICENSE in the project root for license information.

namespace Abc
{
    using Xunit;

    using Assert = AssertEx;

    // Query Expression Pattern.

    public partial class MaybeTests
    {
        private struct MyItem
        {
            public int Id;
            public string Name;
        }

        private struct MyInfo
        {
            public int Id;
            public string Description;
        }

        private struct MyData
        {
            public int Id;
            public string Name;
            public string Description;
        }

        private struct MyDataGroup
        {
            public int Id;
            public string Name;
            public Maybe<MyInfo> Info;
        }
    }

    // Select()
    public partial class MaybeTests
    {
        [Fact]
        public static void Select_None_NullSelector()
        {
            Assert.ThrowsAnexn("selector", () => Ø.Select(Funk<int, AnyResult>.Null));
            Assert.ThrowsAnexn("selector", () => AnyT.None.Select(Funk<AnyT, AnyResult>.Null));
        }

        [Fact]
        public static void Select_Some_NullSelector()
        {
            Assert.ThrowsAnexn("selector", () => One.Select(Funk<int, AnyResult>.Null));
            Assert.ThrowsAnexn("selector", () => AnyT.Some.Select(Funk<AnyT, AnyResult>.Null));
        }

        [Fact]
        public static void Select_None()
        {
            Assert.None(Ø.Select(Funk<int, int>.Any));
            Assert.None(from x in Ø select x);
        }

        [Fact]
        public static void Select_SomeInt32()
        {
            Assert.Some(6, Two.Select(Times3));
            Assert.Some(6, from x in Two select 3 * x);
        }

        [Fact]
        public static void Select_SomeInt64()
        {
            Assert.Some(8L, TwoL.Select(Times4));
            Assert.Some(8L, from x in TwoL select 4L * x);
        }

        [Fact]
        public static void Select_SomeUri()
        {
            Assert.Some(MyUri.AbsoluteUri, SomeUri.Select(GetAbsoluteUri));
            Assert.Some(MyUri.AbsoluteUri, from x in SomeUri select x.AbsoluteUri);
        }
    }

    // Where()
    public partial class MaybeTests
    {
        [Fact]
        public static void Where_None_NullPredicate()
        {
            Assert.ThrowsAnexn("predicate", () => Ø.Where(null!));
            Assert.ThrowsAnexn("predicate", () => AnyT.None.Where(null!));
        }

        [Fact]
        public static void Where_Some_NullPredicate()
        {
            Assert.ThrowsAnexn("predicate", () => One.Where(null!));
            Assert.ThrowsAnexn("predicate", () => AnyT.Some.Where(null!));
        }

        [Fact]
        public static void Where_None()
        {
            Assert.None(Ø.Where(Funk<int, bool>.Any));

            Assert.None(from x in Ø where true select x);
            Assert.None(from x in Ø where false select x);
        }

        [Fact]
        public static void Where_Some()
        {
            // Some.Where(false) -> None
            Assert.None(One.Where(x => x == 2));
            Assert.None(from x in One where x == 2 select x);

            // Some.Where(true) -> Some
            Assert.Some(1, One.Where(x => x == 1));
            Assert.Some(1, from x in One where x == 1 select x);
        }
    }

    // SelectMany()
    public partial class MaybeTests
    {
        #region Args check

        [Fact]
        public static void SelectMany_None_NullSelector()
        {
            Assert.ThrowsAnexn("selector", () => Ø.SelectMany(Kunc<int, AnyT1>.Null, Funk<int, AnyT1, AnyResult>.Any));
            Assert.ThrowsAnexn("selector", () => AnyT.None.SelectMany(Kunc<AnyT, AnyT1>.Null, Funk<AnyT, AnyT1, AnyResult>.Any));
        }

        [Fact]
        public static void SelectMany_Some_NullSelector()
        {
            Assert.ThrowsAnexn("selector", () => One.SelectMany(Kunc<int, AnyT1>.Null, Funk<int, AnyT1, AnyResult>.Any));
            Assert.ThrowsAnexn("selector", () => AnyT.Some.SelectMany(Kunc<AnyT, AnyT1>.Null, Funk<AnyT, AnyT1, AnyResult>.Any));
        }

        [Fact]
        public static void SelectMany_None_NullResultSelector()
        {
            Assert.ThrowsAnexn("resultSelector", () => Ø.SelectMany(Kunc<int, AnyT1>.Any, Funk<int, AnyT1, AnyResult>.Null));
            Assert.ThrowsAnexn("resultSelector", () => AnyT.None.SelectMany(Kunc<AnyT, AnyT1>.Any, Funk<AnyT, AnyT1, AnyResult>.Null));
        }

        [Fact]
        public static void SelectMany_Some_NullResultSelector()
        {
            Assert.ThrowsAnexn("resultSelector", () => One.SelectMany(Kunc<int, AnyT1>.Any, Funk<int, AnyT1, AnyResult>.Null));
            Assert.ThrowsAnexn("resultSelector", () => AnyT.Some.SelectMany(Kunc<AnyT, AnyT1>.Any, Funk<AnyT, AnyT1, AnyResult>.Null));
        }

        #endregion

        [Fact]
        public static void SelectMany_None_WithNone()
        {
            Assert.None(Ø.SelectMany(_ => Ø, (i, j) => i + j));
            Assert.None(from i in Ø from j in Ø select i + j);
        }

        [Fact]
        public static void SelectMany_None_WithSome()
        {
            Assert.None(Ø.SelectMany(i => Maybe.Some(2 * i), (i, j) => i + j));
            Assert.None(from i in Ø from j in Maybe.Some(2 * i) select i + j);
        }

        [Fact]
        public static void SelectMany_Some_WithNone()
        {
            Assert.None(One.SelectMany(_ => Ø, (i, j) => i + j));
            Assert.None(from i in One from j in Ø select i + j);
        }

        [Fact]
        public static void SelectMany_Some_WithSome()
        {
            Assert.Some(3, One.SelectMany(i => Maybe.Some(2 * i), (i, j) => i + j));
            Assert.Some(3, from i in One from j in Maybe.Some(2 * i) select i + j);
        }
    }

    // Join()
    public partial class MaybeTests
    {
        #region Args check

        [Fact]
        public static void Join_None_NullOuterKeySelector()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                Ø.Join(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<int, AnyT1, AnyResult>.Any));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.None.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, AnyT1, AnyResult>.Any));
        }

        [Fact]
        public static void Join_None_NullOuterKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                Ø.Join(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<int, AnyT1, AnyResult>.Any, null));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.None.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, AnyT1, AnyResult>.Any, null));
        }

        [Fact]
        public static void Join_Some_NullOuterKeySelector()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                One.Join(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<int, AnyT1, AnyResult>.Any));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, AnyT1, AnyResult>.Any));
        }

        [Fact]
        public static void Join_Some_NullOuterKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                One.Join(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<int, AnyT1, AnyResult>.Any, null));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, AnyT1, AnyResult>.Any, null));
        }

        [Fact]
        public static void Join_None_NullInnerKeySelector()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                Ø.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, AnyT1, AnyResult>.Any));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.None.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, AnyT1, AnyResult>.Any));
        }

        [Fact]
        public static void Join_None_NullInnerKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                Ø.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, AnyT1, AnyResult>.Any, null));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.None.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, AnyT1, AnyResult>.Any, null));
        }

        [Fact]
        public static void Join_Some_NullInnerKeySelector()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                One.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, AnyT1, AnyResult>.Any));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, AnyT1, AnyResult>.Any));
        }

        [Fact]
        public static void Join_Some_NullInnerKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                One.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, AnyT1, AnyResult>.Any, null));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, AnyT1, AnyResult>.Any, null));
        }

        [Fact]
        public static void Join_None_NullResultSelector()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                Ø.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, AnyT1, AnyResult>.Null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, AnyT1, AnyResult>.Null));
        }

        [Fact]
        public static void Join_None_NullResultSelector_WithComparer()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                Ø.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, AnyT1, AnyResult>.Null, null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, AnyT1, AnyResult>.Null, null));
        }

        [Fact]
        public static void Join_Some_NullResultSelector()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                One.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, AnyT1, AnyResult>.Null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, AnyT1, AnyResult>.Null));
        }

        [Fact]
        public static void Join_Some_NullResultSelector_WithComparer()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                One.Join(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, AnyT1, AnyResult>.Null, null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.Some.Join(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, AnyT1, AnyResult>.Null, null));
        }

        #endregion

        [Fact]
        public static void Join_None()
        {
            Assert.None(Ø.Join(One, Ident, Ident, (i, j) => i + j));
            Assert.None(from i in Ø join j in One on i equals j select i + j);

            // With SelectMany().
            Assert.None(from i in Ø from j in One where i == j select i + j);
        }

        [Fact]
        public static void Join_Some_WithNone()
        {
            Assert.None(One.Join(Ø, Ident, Ident, (i, j) => i + j));
            Assert.None(from i in One join j in Ø on i equals j select i + j);

            // With SelectMany().
            Assert.None(from i in One from j in Ø where i == j select i + j);
        }

        [Fact]
        public static void Join_Some_WithSome_Unmatched()
        {
            Assert.None(One.Join(Two, Ident, Ident, (i, j) => i + j));
            Assert.None(from i in One join j in Two on i equals j select i + j);

            // With SelectMany().
            Assert.None(from i in One from j in Two where i == j select i + j);
        }

        [Fact]
        public static void Join_Some_WithSome_Matched()
        {
            Assert.Some(2, One.Join(One, Ident, Ident, (i, j) => i + j));
            Assert.Some(2, from i in One join j in One on i equals j select i + j);

            Assert.Some(3, One.Join(Two, x => 2 * x, Ident, (i, j) => i + j));
            Assert.Some(3, from i in One join j in Two on 2 * i equals j select i + j);

            var outer = Maybe.Some(3);
            var inner = Maybe.Some(5);
            Assert.Some(8, outer.Join(inner, x => 5 * x, x => 3 * x, (i, j) => i + j));
            Assert.Some(8, from i in outer join j in inner on 5 * i equals 3 * j select i + j);

            // With SelectMany().
            Assert.Some(2, from i in One from j in One where i == j select i + j);
            Assert.Some(3, from i in One from j in Two where 2 * i == j select i + j);
            Assert.Some(8, from i in outer from j in inner where 5 * i == 3 * j select i + j);
        }

        [Fact]
        public static void Join_WithNullComparer()
        {
            // Arrange
            var outer = Maybe.SomeOrNone("XXX");
            var inner = Maybe.SomeOrNone("YYY");
            // Act
            var q = outer.Join(inner, Ident, Ident, (x, y) => $"{x} = {y}", null);
            // Assert
            Assert.None(q);

            // With SelectMany().
            Assert.None(
                from x in outer
                from y in inner
                where x == y
                select $"{x} == {y}");
        }

        [Fact]
        public static void Join_WithComparer()
        {
            // Arrange
            var outer = Maybe.SomeOrNone(Anagram);
            var inner = Maybe.SomeOrNone(Margana);
            var cmp = new AnagramEqualityComparer();
            string expected = $"{Anagram} est un anagramme de {Margana}";
            // Act
            var q = outer.Join(inner, Ident, Ident,
                (x, y) => $"{x} est un anagramme de {y}",
                cmp);
            // Assert
            Assert.Some(expected, q);

            // With SelectMany().
            Assert.Some(expected,
                from x in outer
                from y in inner
                where cmp.Equals(x, y)
                select $"{x} est un anagramme de {y}");
        }

        [Fact]
        public static void Join_Some_WithSome_ComplexType_Unmatched()
        {
            // Arrange
            var item = new MyItem { Id = 1, Name = "Name" };
            var info = new MyInfo { Id = 2, Description = "Description" };
            var outer = Maybe.Some(item);
            var inner = Maybe.Some(info);
            // Act
            var q = from x in outer
                    join y in inner on x.Id equals y.Id
                    select new MyData
                    {
                        Id = x.Id,
                        Name = x.Name,
                        Description = y.Description
                    };
            // Assert
            Assert.None(q);

            // With SelectMany().
            Assert.None(
                from x in outer
                from y in inner
                where x.Id == y.Id
                select new MyData
                {
                    Id = x.Id,
                    Name = x.Name,
                    Description = y.Description
                });
        }

        [Fact]
        public static void Join_Some_WithSome_ComplexType_Matched()
        {
            // Arrange
            var item = new MyItem { Id = 1, Name = "Name" };
            var info = new MyInfo { Id = 1, Description = "Description" };
            var outer = Maybe.Some(item);
            var inner = Maybe.Some(info);
            var expected = new MyData { Id = 1, Name = "Name", Description = "Description" };
            // Act
            var q = from x in outer
                    join y in inner on x.Id equals y.Id
                    select new MyData
                    {
                        Id = x.Id,
                        Name = x.Name,
                        Description = y.Description
                    };
            // Assert
            Assert.Some(expected, q);

            // With SelectMany().
            Assert.Some(expected,
                from x in outer
                from y in inner
                where x.Id == y.Id
                select new MyData
                {
                    Id = x.Id,
                    Name = x.Name,
                    Description = y.Description
                });
        }
    }

    // GroupJoin()
    public partial class MaybeTests
    {
        #region Args check

        [Fact]
        public static void GroupJoin_None_NullOuterKeySelector()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                Ø.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<int, Maybe<AnyT1>, AnyResult>.Any));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.None.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any));
        }

        [Fact]
        public static void GroupJoin_None_NullOuterKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                Ø.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<int, Maybe<AnyT1>, AnyResult>.Any, null));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.None.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any, null));
        }

        [Fact]
        public static void GroupJoin_Some_NullOuterKeySelector()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                One.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<int, Maybe<AnyT1>, AnyResult>.Any));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.Some.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any));
        }

        [Fact]
        public static void GroupJoin_Some_NullOuterKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("outerKeySelector", () =>
                One.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<int, Maybe<AnyT1>, AnyResult>.Any, null));
            Assert.ThrowsAnexn("outerKeySelector", () =>
                AnyT.Some.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Null, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any, null));
        }

        [Fact]
        public static void GroupJoin_None_NullInnerKeySelector()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                Ø.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, Maybe<AnyT1>, AnyResult>.Any));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.None.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any));
        }

        [Fact]
        public static void GroupJoin_None_NullInnerKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                Ø.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, Maybe<AnyT1>, AnyResult>.Any, null));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.None.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any, null));
        }

        [Fact]
        public static void GroupJoin_Some_NullInnerKeySelector()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                One.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, Maybe<AnyT1>, AnyResult>.Any));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.Some.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any));
        }

        [Fact]
        public static void GroupJoin_Some_NullInnerKeySelector_WithComparer()
        {
            Assert.ThrowsAnexn("innerKeySelector", () =>
                One.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<int, Maybe<AnyT1>, AnyResult>.Any, null));
            Assert.ThrowsAnexn("innerKeySelector", () =>
                AnyT.Some.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Null, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Any, null));
        }

        [Fact]
        public static void GroupJoin_None_NullResultSelector()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                Ø.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, Maybe<AnyT1>, AnyResult>.Null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.None.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Null));
        }

        [Fact]
        public static void GroupJoin_None_NullResultSelector_WithComparer()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                Ø.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, Maybe<AnyT1>, AnyResult>.Null, null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.None.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Null, null));
        }

        [Fact]
        public static void GroupJoin_Some_NullResultSelector()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                One.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, Maybe<AnyT1>, AnyResult>.Null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.Some.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Null));
        }

        [Fact]
        public static void GroupJoin_Some_NullResultSelector_WithComparer()
        {
            Assert.ThrowsAnexn("resultSelector", () =>
                One.GroupJoin(AnyT1.Some, Funk<int, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<int, Maybe<AnyT1>, AnyResult>.Null, null));
            Assert.ThrowsAnexn("resultSelector", () =>
                AnyT.Some.GroupJoin(AnyT1.Some, Funk<AnyT, AnyT2>.Any, Funk<AnyT1, AnyT2>.Any, Funk<AnyT, Maybe<AnyT1>, AnyResult>.Null, null));
        }

        #endregion

        [Fact]
        public static void GroupJoin_WithNullComparer()
        {
            // Arrange
            var outer = Maybe.SomeOrNone("XXX");
            var inner = Maybe.SomeOrNone("YYY");
            // Act
            var q = outer.GroupJoin(inner, Ident, Ident,
                (x, y) => y.Switch(s => $"{x} = {s}",
                Funk<string>.Any),
                null);
            // Assert
            Assert.None(q);
        }

        [Fact]
        public static void GroupJoin_WithComparer()
        {
            // Arrange
            var outer = Maybe.SomeOrNone(Anagram);
            var inner = Maybe.SomeOrNone(Margana);
            string expected = $"{Anagram} est un anagramme de {Margana}";
            // Act
            var q = outer.GroupJoin(inner, Ident, Ident,
                (x, y) => y.Switch(s => $"{x} est un anagramme de {s}",
                Funk<string>.Any),
                new AnagramEqualityComparer());
            // Assert
            Assert.Some(expected, q);
        }

        [Fact]
        public static void GroupJoin_Some_WithSome_ComplexType_Unmatched()
        {
            // Arrange
            var item = new MyItem { Id = 1, Name = "Name" };
            var info = new MyInfo { Id = 2, Description = "Description" };
            var outer = Maybe.Some(item);
            // Act
            var q = from x in outer
                    join y in Maybe.Some(info) on x.Id equals y.Id into g
                    select new MyDataGroup
                    {
                        Id = x.Id,
                        Name = x.Name,
                        Info = g
                    };
            // Assert
            Assert.None(q);
        }

        [Fact]
        public static void GroupJoin_Some_WithSome_ComplexType_Matched()
        {
            // Arrange
            var item = new MyItem { Id = 1, Name = "Name" };
            var info = new MyInfo { Id = 1, Description = "Description" };
            var outer = Maybe.Some(item);
            var expected = new MyDataGroup { Id = 1, Name = "Name", Info = Maybe.Some(info) };
            // Act
            var q = from x in outer
                    join y in Maybe.Some(info) on x.Id equals y.Id into g
                    select new MyDataGroup
                    {
                        Id = x.Id,
                        Name = x.Name,
                        Info = g
                    };
            // Assert
            Assert.Some(expected, q);
        }
    }

    // More Query Expression Patterns.
    public partial class MaybeTests
    {
        [Fact]
        public static void Query_PythagoreanTriple_KO()
        {
            // Arrange
            var none = from i in Maybe.Some(1)
                       from j in Maybe.Some(2)
                       from k in Maybe.Some(3)
                       where i * i + j * j == k * k
                       select (i, j, k);
            // Assert
            Assert.None(none);
        }

        [Fact]
        public static void Query_PythagoreanTriple_OK()
        {
            // Arrange
            var some = from i in Maybe.Some(17)
                       from j in Maybe.Some(144)
                       from k in Maybe.Some(145)
                       where i * i + j * j == k * k
                       select (i, j, k);
            // Assert
            Assert.Some(some);
        }
    }
}

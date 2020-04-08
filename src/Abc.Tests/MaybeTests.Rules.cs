// See LICENSE in the project root for license information.

namespace Abc
{
    using System;

    using Xunit;

    using Assert = AssertEx;

    // Rules, sanity checks.
    // REVIEW: A bit limited, we could use fuzz testing.

    public partial class MaybeTests
    {
        private static readonly Maybe<int> NONE = Maybe<int>.None;
    }

    // Functor rules.
    public partial class MaybeTests
    {
        // First Functor Law: the identity map is a fixed point for Select.
        //   fmap id  ==  id
        [Fact]
        public static void Functor_FirstLaw()
        {
            // Arrange
            var some = AnyT.Some;
            // Act & Assert
            Assert.Equal(AnyT.None, AnyT.None.Select(Ident));
            Assert.Equal(some, some.Select(Ident));
        }

        // Second Functor Law: Select preserves the composition operator.
        //   fmap (f . g)  ==  fmap f . fmap g
        [Fact]
        public static void Functor_SecondLaw()
        {
            Func<int, long> g = x => 2L * x;
            Func<long, string> f = x => $"{x}";

            Assert.Equal(
                Ø.Select(x => f(g(x))),
                Ø.Select(g).Select(f));

            Assert.Equal(
                One.Select(x => f(g(x))),
                One.Select(g).Select(f));
        }
    }

    // Monoid rules.
    // We use additive notations: + is OrElse(), zero is None.
    // 1) zero + x = x
    // 2) x + zero = x
    // 3) x + (y + z) = (x + y) + z
    // TODO: fourth law
    // mconcat = foldr '(<>)' mempty
    public partial class MaybeTests
    {
        // First Monoid Law: None is a left identity for OrElse().
        [Fact]
        public static void OrElse_LeftIdentity()
        {
            Assert.Equal(Ø, NONE.OrElse(Ø));
            Assert.Equal(One, NONE.OrElse(One));
        }

        // Second Monoid Law: None is a right identity for OrElse().
        [Fact]
        public static void OrElse_RightIdentity()
        {
            Assert.Equal(Ø, Ø.OrElse(NONE));
            Assert.Equal(One, One.OrElse(NONE));
        }

        // Third Monoid Law: OrElse() is associative.
        [Fact]
        public static void OrElse_Associativity()
        {
            Assert.Equal(
                Ø.OrElse(One.OrElse(Two)),
                Ø.OrElse(One).OrElse(Two));

            Assert.Equal(
                One.OrElse(Two.OrElse(Ø)),
                One.OrElse(Two).OrElse(Ø));

            Assert.Equal(
                Two.OrElse(Ø.OrElse(One)),
                Two.OrElse(Ø).OrElse(One));
        }
    }

    // MonadZero rules.
    public partial class MaybeTests
    {
        // MonadZero: None is a left zero for Bind().
        //   mzero >>= f = mzero
        [Fact]
        public static void Bind_LeftZero()
        {
            Func<int, Maybe<int>> f = x => Maybe.Some(2 * x);

            Assert.Equal(NONE, NONE.Bind(f));
        }
    }

    // MonadMore: None is a right zero for Bind() or equivalently None is a
    // right zero for AndThen().

    // MonadMore: None is a right zero for AndThen(), implied by the
    // definition of AndThen() and the MonadMore rule.

    // MonadPlus: Bind() is right distributive over OrElse().

    // MonadOr: Unit is a left zero for OrElse().

    // Unit is a right zero for OrElse().

    public partial class MaybeTests
    {
        // AndThen() is associative, implied by the definition of AndThen() and
        // the third monad law.
        //   (m >> n) >> o = m >> (n >> o)
        [Fact]
        public static void AndThen_Associativity()
        {
            Assert.Equal(
                Ø.AndThen(One.AndThen(Two)),
                Ø.AndThen(One).AndThen(Two));

            Assert.Equal(
                One.AndThen(Two.AndThen(Ø)),
                One.AndThen(Two).AndThen(Ø));

            Assert.Equal(
                Two.AndThen(Ø.AndThen(One)),
                Two.AndThen(Ø).AndThen(One));
        }
    }
}

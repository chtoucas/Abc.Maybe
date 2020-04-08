// See LICENSE in the project root for license information.

namespace Abc.Edu.Fx
{
    using System;

    // Functor
    // =======
    //
    // Functors: uniform action over a parameterized type, generalizing the map
    // function on lists.
    // The Functor class is used for types that can be mapped over.
    //
    // References:
    // - https://wiki.haskell.org/Functor
    // - https://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Functor.html
    //
    // Methods
    // -------
    // Bare minimum:
    // - fmap   Mayhap.Map()
    //
    // Standard API:
    // - <$     Mayhap.ReplaceWith()
    // - $>     obj.ReplaceWith()
    // - <$>    func.Invoke()
    // - <&>    obj.Map()
    // - void   obj.Skip()
    //
    public partial class Mayhap
    {
        /// <summary>
        /// fmap
        /// <para>a = TSource, b = TResult</para>
        /// <para>Create a new f b from an f a using the results of calling a
        /// function on every value in the f a.</para>
        /// </summary>
        public static Mayhap<TResult> Map<TSource, TResult>(
            Func<TSource, TResult> mapper,
            Mayhap<TSource> mayhap)
        {
            // fmap :: (a -> b) -> f a -> f b
            //
            // Examples:
            //   fmap (+1) (Just 1)  ==  Just 2
            //   fmap (+1) Nothing   ==  Nothing

#if STRICT_HASKELL
            throw new NotImplementedException("Functor fmap");
#else
            return mayhap.Select(mapper);
#endif
        }

        /// <summary>(&lt;&amp;&gt;)</summary>
        public static Mayhap<TResult> Map<TSource, TResult>(
            this Mayhap<TSource> @this,
            Func<TSource, TResult> mapper)
        {
            // [Functor]
            //   (<&>) :: Functor f => f a -> (a -> b) -> f b | infixl 1 |
            //   (<&>) = flip fmap
            //
            //    Flipped version of <$>.
            //
            // Examples:
            //   Just 1  <&> (+1)  ==  Just 2
            //   Nothing <&> (+1)  ==  Nothing

#if STRICT_HASKELL
            return Map(mapper, @this);
#else
            return @this.Select(mapper);
#endif
        }

        /// <summary>
        /// (&lt;$)
        /// <para>a = TResult, b = TSource</para>
        /// <para>Create a new f a from an f b by replacing all of the values in
        /// the f b by a given value of type a.</para>
        /// </summary>
        public static Mayhap<TResult> ReplaceWith<TSource, TResult>(
            TResult value,
            Mayhap<TSource> mayhap)
            where TResult : notnull
        {
            // (<$) :: Functor f => a -> f b -> f a | infixl 4 |
            //
            // (<$) :: a -> f b -> f a
            // (<$) =  fmap . const
            //
            // Replace all locations in the input with the same value. The
            // default definition is fmap . const, but this may be overridden
            // with a more efficient version.
            //
            // Examples:
            //   "xxx" <$ Nothing == Nothing
            //   "xxx" <$ Just 1  == Just "xxx"

#if STRICT_HASKELL
            return Map(__const, mayhap);

            // NB: this is just (_ => value).
            TResult __const(TSource x) => Stubs<TResult, TSource>.Const1(value, x);
#else
            return mayhap.Select(_ => value);
#endif
        }

        /// <summary>
        /// ($&gt;)
        /// <para>a = TSource, b = TResult</para>
        /// <para>Create a new f b, from an f a by replacing all of the values
        /// in the f a by a given value of type b.</para>
        /// </summary>
        public static Mayhap<TResult> ReplaceWith<TSource, TResult>(
            this Mayhap<TSource> @this,
            TResult value)
            where TResult : notnull
        {
            // ($>) :: Functor f => f a -> b -> f b | infixl 4 |
            // ($>) = flip (<$)
            //
            // Flipped version of <$.
            //
            // Examples:
            //   Nothing $> "xxx" == Nothing
            //   Just 1 $> "xxx"  == Just "xxx"

#if STRICT_HASKELL
            return ReplaceWith(value, @this);
#else
            return @this.Select(_ => value);
#endif
        }

        /// <summary>
        /// void
        /// <para>a = TSource, () = Unit</para>
        /// <para>Create a new f () from an f a by replacing all of the values
        /// in the f a by ().</para>
        /// </summary>
        public static Mayhap<Unit> Skip<TSource>(
            this Mayhap<TSource> @this)
        {
            // void :: Functor f => f a -> f ()
            // void x = () <$ x
            //
            // void value discards or ignores the result of evaluation, such as
            // the return value of an IO action.

#if STRICT_HASKELL
            return ReplaceWith(Abc.Unit.Default, @this);
#else
            return @this.Select(_ => Abc.Unit.Default);
#endif
        }
    }

    // Extension methods for Mayhap<T> where T is a func.
    public partial class Mayhap
    {
        /// <summary>
        /// (&lt;$&gt;>
        /// <para>An infix synonym for fmap.</para>
        /// </summary>
        public static Mayhap<TResult> Invoke<TSource, TResult>(
            this Func<TSource, TResult> @this,
            Mayhap<TSource> mayhap)
        {
            // (<$>) :: Functor f => (a -> b) -> f a -> f b | infixl 4 |
            // (<$>) = fmap
            //
            // The name of this operator is an allusion to $.
            //
            // Examples:
            //   (+1) <$> Just 1   ==  Just 2
            //   (+1) <$> Nothing  ==  Nothing

#if STRICT_HASKELL
            return Map(@this, mayhap);
#else
            Require.NotNull(@this, nameof(@this));

            return mayhap.Select(@this);
#endif
        }
    }

    // Functor rules.
    public partial class Mayhap
    {
        internal static class FunctorRules
        {
            // First law: the identity map is a fixed point for Select.
            //   fmap id  ==  id
            public static bool IdentityRule<T>(Mayhap<T> mayhap)
            {
#if STRICT_HASKELL
                return Map(Stubs<T>.Ident, mayhap)
                    == Stubs<Mayhap<T>>.Ident(mayhap);
#else
                return mayhap.Select(Stubs<T>.Ident)
                    == Stubs<Mayhap<T>>.Ident(mayhap);
#endif
            }

            // Second law: Select preserves the composition operator.
            //   fmap (f . g)  ==  fmap f . fmap g
            public static bool CompositionRule<T1, T2, T3>(
                Mayhap<T1> mayhap, Func<T2, T3> f, Func<T1, T2> g)
            {
#if STRICT_HASKELL
                return Map(x => f(g(x)), mayhap)
                    == Map(f, Map(g, mayhap));
#else
                return mayhap.Select(x => f(g(x)))
                    == mayhap.Select(g).Select(f);
#endif
            }
        }
    }
}

// See LICENSE in the project root for license information.

namespace Abc.Edu.Fx
{
#if STRICT_HASKELL
    using System;
#endif
    using System.Collections.Generic;
    using System.Linq;

    // Alternative / MonadPlus
    // =======================
    //
    // A monoid on applicative functors.
    // Associative operation <|> and identity element "empty".
    //
    // References:
    // - https://en.wikibooks.org/wiki/Haskell/Alternative_and_MonadPlus
    // - http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Applicative.html
    //
    // Methods
    // -------
    // Bare minimum:
    // - empty      Mayhap.Zero<T>()
    // - <|>        ext.Otherwise()
    //
    // Standard API:
    // - some       Mayhap.Some()
    // - many       Mayhap.Many()
    // - optional   ext.Optional()
    //
    public partial class Mayhap
    {
        /// <summary>
        /// empty
        /// </summary>
        public static Mayhap<T> Zero<T>()
        {
            // The identity of <|>.

#if STRICT_HASKELL
            throw new NotImplementedException("Alternative empty");
#else
            return Mayhap<T>.None;
#endif
        }

        /// <summary>
        /// (&lt;|&gt;)
        /// </summary>
        public static Mayhap<T> Otherwise<T>(this Mayhap<T> @this, Mayhap<T> other)
        {
            // (<|>) :: f a -> f a -> f a | infixl 3 |
            //
            // An associative binary operation.
            //
            // Examples:
            //   Nothing <|> Nothing == Nothing
            //   Just 1  <|> Nothing == Just 1
            //   Nothing <|> Just 1  == Just 1
            //   Just 1  <|> Just 2  == Just 1

#if STRICT_HASKELL
            throw new NotImplementedException("Alternative <|>");
#else
            return @this.OrElse(other);
#endif
        }

        // FIXME: infinite recursive calls. Clean up
        // https://stackoverflow.com/questions/7671009/some-and-many-functions-from-the-alternative-type-class
        // https://www.reddit.com/r/haskell/comments/b71oje/i_dont_understand_how_some_and_many_from_the/

        /// <summary>some</summary>
        public static Mayhap<IEnumerable<T>> Some<T>(Mayhap<T> mayhap)
        {
            // some :: f a -> f [a]
            // some v = some_v
            //   where
            //     many_v = some_v <|> pure []
            //     some_v = liftA2 (:) v many_v
            //
            // some v = (:) <$> v <*> many v
            //
            // One or more.

            Func<T, IEnumerable<T>, IEnumerable<T>> prepend = (x, y) => y.Prepend(x);
            return Pure(prepend).Invoke(mayhap, Many(mayhap));
        }

        /// <summary>many</summary>
        public static Mayhap<IEnumerable<T>> Many<T>(Mayhap<T> mayhap)
        {
            // many :: f a -> f [a]
            // many v = many_v
            //   where
            //     many_v = some_v <|> pure []
            //     some_v = liftA2 (:) v many_v
            //
            // many v = some v <|> pure []
            //
            // Zero or more.

            return Some(mayhap).Otherwise(EmptyEnumerable<T>());
        }

        public static Mayhap<Mayhap<T>> Optional<T>(this Mayhap<T> @this)
        {
            // optional :: Alternative f => f a -> f (Maybe a)
            // optional v = Just <$> v <|> pure Nothing
            //
            // One or none.

#if STRICT_HASKELL
            return Map(Mayhap<T>.Some, @this).Otherwise(Pure(Mayhap<T>.None));
#else
            return @this.Select(Mayhap<T>.Some).OrElse(Pure(Mayhap<T>.None));
#endif
        }
    }

    // mzero >>= f  =  mzero
    // v >> mzero   =  mzero
    public partial class Mayhap
    {
    }
}

// See LICENSE in the project root for license information.

namespace Abc.Edu.Fx
{
    using System;
    using System.Collections.Generic;
    using System.Linq;

    using Abc.Utilities;

    // Monad
    // =====
    //
    // References:
    // - http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Monad.html
    // - https://downloads.haskell.org/~ghc/latest/docs/html/libraries/base-4.13.0.0/Control-Monad.html
    // - https://wiki.haskell.org/MonadPlus_reform_proposal
    //
    // Methods
    // -------
    // Bare minimum (>>= or fmap):
    // - >>=                        obj.Bind()
    // - fmap                       obj.Select()
    // - >>                         ext.ContinueWith() in Applicative
    // - return                     Mayhap<T>.η()
    // - fail
    //
    // Standard API:
    // - mapM & mapM_               enumerable.SelectAny()
    // - forM & forM_
    // - sequence & sequence_
    // - <<=                        Func$.Invoke()
    // - >=>                        Func$.Compose()
    // - <=<                        Func$.ComposeBack()
    // - forever
    // - void                       obj.Skip() in Functor
    //
    // - join                       Mayhap<T>.μ()
    // - msum                       Mayhap.Sum()
    // - mfilter                    ext.Where()
    // - filterM                    enumerable.WhereAny()
    // - mapAndUnzipM
    // - zipWithM & zipWithM_
    // - foldM & foldM_
    // - replicateM & replicateM_   ext.Replicate()
    //
    // - guard                      Mayhap.Guard()
    // - when
    // - unless
    //
    // - liftM
    // - liftM2
    // - liftM3
    // - liftM4
    // - liftM5
    // - ap
    //
    // - <$!>
    public partial class Mayhap
    {
        public static Mayhap<IEnumerable<T>> EmptyEnumerable<T>()
            => MayhapEnumerable_<T>.Empty;

        private static class MayhapEnumerable_<T>
        {
            internal static readonly Mayhap<IEnumerable<T>> Empty
                = Mayhap<IEnumerable<T>>.η(Enumerable.Empty<T>());
        }

        /// <summary>mapM</summary>
        public static Mayhap<IEnumerable<TResult>> SelectAny<TSource, TResult>(
            this IEnumerable<TSource> source,
            Func<TSource, Mayhap<TResult>> selector)
        {
            // mapM :: (Traversable t, Monad m) => (a -> m b) -> t a -> m (t b)
            // mapM = traverse
            //
            // See Data.Traversable
            // traverse :: Applicative f => (a -> f b) -> t a -> f (t b)
            // traverse f = sequenceA . fmap f
            //
            // sequenceA :: Applicative f => t (f a) -> f (t a)
            // sequenceA = traverse id
            //
            // Map each element of a structure to a monadic action, evaluate
            // these actions from left to right, and collect the results. For a
            // version that ignores the results see mapM_.

            return __collectAny(source.Select(selector));

            // sequenceA
            static Mayhap<IEnumerable<T>> __collectAny<T>(IEnumerable<Mayhap<T>> source)
            {
                var seed = MayhapEnumerable_<T>.Empty;
                return source.Aggregate(seed, (x, y) => x.ZipWith(y, Enumerable.Append));
            }
        }

        /// <summary>(=&lt;&lt;)</summary>
        public static Mayhap<TResult> Invoke<TSource, TResult>(
            this Func<TSource, Mayhap<TResult>> @this, Mayhap<TSource> value)
        {
            // (=<<) :: Monad m => (a -> m b) -> m a -> m b | infixr 1 |
            // f =<< x = x >>= f

            return value.Bind(@this);
        }

        /// <summary>(&gt;=&gt;)</summary>
        public static Func<TSource, Mayhap<TResult>> Compose<TSource, TMiddle, TResult>(
            this Func<TSource, Mayhap<TMiddle>> @this, Func<TMiddle, Mayhap<TResult>> other)
        {
            // (>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c | infixr 1 |
            // f >=> g = \x -> f x >>= g

            Require.NotNull(@this, nameof(@this));

            return x => @this(x).Bind(other);
        }

        /// <summary>(&lt;=&lt;)</summary>
        public static Func<TSource, Mayhap<TResult>> ComposeBack<TSource, TMiddle, TResult>(
            this Func<TMiddle, Mayhap<TResult>> @this, Func<TSource, Mayhap<TMiddle>> other)
        {
            // (<=<) :: Monad m => (b -> m c) -> (a -> m b) -> a -> m c | infixr 1 |
            // (<=<) = flip (>=>)

            Require.NotNull(other, nameof(other));

            return x => other(x).Bind(@this);
        }
    }

    public partial class Mayhap
    {
        /// <summary>msum</summary>
        public static Mayhap<T> Sum<T>(IEnumerable<Mayhap<T>> source)
        {
            // msum :: (Foldable t, MonadPlus m) => t (m a) -> m a
            // msum = asum
            //
            // asum :: (Foldable t, Alternative f) => t (f a) -> f a
            // asum = foldr (<|>) empty

            return source.Aggregate(Zero<T>(), (m, n) => m.Otherwise(n));
        }

        /// <summary>mfilter</summary>
        public static Mayhap<T> Where<T>(this Mayhap<T> @this, Func<T, bool> predicate)
        {
            // mfilter :: (MonadPlus m) => (a -> Bool) -> m a -> m a
            // mfilter p ma = do
            //   a <- ma
            //   if p a then return a else mzero
            //
            // Direct MonadPlus equivalent of filter (for lists).

            Require.NotNull(predicate, nameof(predicate));

            // NB: x is never null.
            return @this.Bind(x => predicate(x) ? Mayhap<T>.Some(x) : Mayhap<T>.None);
        }

        /// <summary>filterM</summary>
        public static Mayhap<IEnumerable<TSource>> WhereAny<TSource>(
            this IEnumerable<TSource> source, Func<TSource, Mayhap<bool>> predicate)
        {
            // filterM :: Applicative m => (a -> m Bool) -> [a] -> m [a]
            // filterM p = foldr (\ x -> liftA2 (\ flg -> if flg then (x:) else id) (p x)) (pure [])
            //
            // This generalizes the list-based filter function.

            return source.Aggregate(
                EmptyEnumerable<TSource>(),
                (m, x) => predicate(x).ZipWith(m, __zipper(x)));

            Func<bool, IEnumerable<TSource>, IEnumerable<TSource>> __zipper(TSource item)
                => (b, seq) => b ? seq.Append(item) : seq;
        }

        /// <summary>replicateM</summary>
        public static Mayhap<IEnumerable<T>> Replicate<T>(this Mayhap<T> @this, int count)
        {
            // replicateM :: Applicative m => Int -> m a -> m [a]
            // replicateM cnt0 f =
            //     loop cnt0
            //   where
            //     loop cnt
            //       | cnt <= 0 = pure []
            //       | otherwise = liftA2 (:) f (loop (cnt - 1))
            //
            // replicateM n act performs the action n times, gathering the results.

            return @this.Select(x => Enumerable.Repeat(x, count));
        }
    }

    public partial class Mayhap
    {
        public static readonly Mayhap<Unit> Unit = Mayhap<Unit>.Some(default);

        public static readonly Mayhap<Unit> None = Mayhap<Unit>.None;

        public static Mayhap<Unit> Guard(bool predicate)
            => predicate ? Unit : None;
    }

    // ZipWith
    //   Promote a function to a monad, scanning the monadic arguments from
    //   left to right.
    public partial class Mayhap
    {
        /// <summary>liftM2</summary>
        // [Monad]
        //   liftM2 :: Monad m => (a1 -> a2 -> r) -> m a1 -> m a2 -> m r
        //   liftM2 f m1 m2 = do { x1 <- m1; x2 <- m2; return (f x1 x2) }
        //
        //   Promote a function to a monad, scanning the monadic arguments from
        //   left to right.
        public static Mayhap<TResult> ZipWith<TSource, TOther, TResult>(
            this Mayhap<TSource> @this,
            Mayhap<TOther> other,
            Func<TSource, TOther, TResult> zipper)
        {
            Require.NotNull(zipper, nameof(zipper));

            return @this.Bind(
                x => other.Bind(
                    y => Mayhap<TResult>.η(zipper(x, y))));
        }

        ///// <summary>liftM3</summary>
        //// [Monad]
        ////   liftM3 :: (Monad m) => (a1 -> a2 -> a3 -> r) -> m a1 -> m a2 -> m a3 -> m r
        ////   liftM3 f m1 m2 m3 = do { x1 <- m1; x2 <- m2; x3 <- m3; return (f x1 x2 x3) }
        ////
        ////   Promote a function to a monad, scanning the monadic arguments from
        ////   left to right.
        //public static Mayhap<TResult> ZipWith<TSource, T1, T2, TResult>(
        //    this Mayhap<TSource> @this,
        //    Mayhap<T1> m1,
        //    Mayhap<T2> m2,
        //    Func<TSource, T1, T2, TResult> zipper)
        //{
        //    Require.NotNull(zipper, nameof(zipper));

        //    return @this.Bind(
        //        x => m1.ZipWith(m2, (y, z) => zipper(x, y, z)));
        //}

        /// <summary>liftM4</summary>
        // [Monad]
        //   liftM4 :: (Monad m) => (a1 -> a2 -> a3 -> a4 -> r) -> m a1 -> m a2 -> m a3 -> m a4 -> m r
        //   liftM4 f m1 m2 m3 m4 = do { x1 <- m1; x2 <- m2; x3 <- m3; x4 <- m4; return (f x1 x2 x3 x4) }
        public static Func<Mayhap<T1>, Mayhap<T2>, Mayhap<T3>, Mayhap<T4>, Mayhap<TResult>>
            Lift<T1, T2, T3, T4, TResult>(
            Func<T1, T2, T3, T4, TResult> func)
        {
            return (m1, m2, m3, m4) =>
                m1.Bind(
                    x1 => m2.Bind(
                        x2 => m3.Bind(
                            x3 => m4.Bind(
                                x4 => Mayhap<TResult>.η(func(x1, x2, x3, x4))))));
        }

        //public static Mayhap<TResult> ZipWith<TSource, T1, T2, T3, TResult>(
        //    this Mayhap<TSource> @this,
        //     Mayhap<T1> first,
        //     Mayhap<T2> second,
        //     Mayhap<T3> third,
        //     Func<TSource, T1, T2, T3, TResult> zipper)
        //{
        //    Require.NotNull(zipper, nameof(zipper));

        //    return @this.Bind(
        //        x => first.ZipWith(
        //            second,
        //            third,
        //            (y, z, a) => zipper(x, y, z, a)));
        //}

        /// <summary>liftM5</summary>
        // [Monad]
        //   liftM5 :: (Monad m) => (a1 -> a2 -> a3 -> a4 -> a5 -> r) -> m a1 -> m a2 -> m a3 -> m a4 -> m a5 -> m r
        //   liftM5 f m1 m2 m3 m4 m5 = do { x1 <- m1; x2 <- m2; x3 <- m3; x4 <- m4; x5 <- m5; return (f x1 x2 x3 x4 x5) }
        public static Func<Mayhap<T1>, Mayhap<T2>, Mayhap<T3>, Mayhap<T4>, Mayhap<T5>, Mayhap<TResult>>
            Lift<T1, T2, T3, T4, T5, TResult>(Func<T1, T2, T3, T4, T5, TResult> func)
        {
            return (m1, m2, m3, m4, m5) =>
                m1.Bind(
                    x1 => m2.Bind(
                        x2 => m3.Bind(
                            x3 => m4.Bind(
                                x4 => m5.Bind(
                                    x5 => Mayhap<TResult>.η(func(x1, x2, x3, x4, x5)))))));
        }
    }
}

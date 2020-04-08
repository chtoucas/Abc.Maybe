// See LICENSE in the project root for license information.

namespace Abc.Edu.Fx
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;

    using Abc.Utilities;

    // TODO: clean up Mayhap.

    /// <summary>
    /// Represents the Maybe monad.
    /// </summary>
    public readonly partial struct Mayhap<T> : IEquatable<Mayhap<T>>
    {
        private readonly bool _isSome;
        private readonly T _value;

        private Mayhap(T value)
        {
            _isSome = true;
            _value = value;
        }

        public override string ToString()
            => match(
                some: x => $"Mayhap({x})",
                none: "Mayhap(None)");

        public IEnumerable<T> ToEnumerable()
            => _isSome ? Enumerable.Repeat(_value, 1) : Enumerable.Empty<T>();

        public bool Contains(T value)
            => match(
                some: x => EqualityComparer<T>.Default.Equals(x, value),
                none: false);

        private TResult match<TResult>(Func<T, TResult> some, TResult none)
            => _isSome ? some(_value) : none;
    }

    // Core methods.
    public partial struct Mayhap<T>
    {
#pragma warning disable CA1000 // Do not declare static members on generic types
        /// <summary>Nothing / mzero</summary>
        public static Mayhap<T> None { get; } = default;
#pragma warning restore CA1812

        /// <summary>Just</summary>
        public static Mayhap<T> Some(T value)
            => new Mayhap<T>(value);

        /// <summary>return</summary>
        public static Mayhap<T> η(T value)
            // return :: a -> m a
            //
            // Inject a value into the monadic type.
            => value is null ? Mayhap<T>.None : Mayhap<T>.Some(value);

        /// <summary>join</summary>
        public static Mayhap<T> μ(Mayhap<Mayhap<T>> square)
            // join :: Monad m => m (m a) -> m a
            //
            // The join function is the conventional monad join operator. It is
            // used to remove one level of monadic structure, projecting its
            // bound argument into the outer level.
            => square._value;

        /// <summary>fmap / liftM</summary>
        public Mayhap<TResult> Select<TResult>(Func<T, TResult> selector)
        {
            //   fmap :: (a -> b) -> f a -> f b
            //
            //   liftM :: (Monad m) => (a1 -> r) -> m a1 -> m r
            //   liftM f m1 = do { x1 <- m1; return (f x1) }
            //
            //   Promote a function to a monad.

            Require.NotNull(selector, nameof(selector));

#if MONADS_VIA_MAP_MULTIPLY
            return _isSome ? Mayhap<TResult>.η(selector(_value)) : Mayhap<TResult>.None;
#else
            return Bind(x => Mayhap<TResult>.η(selector(x)));
#endif
        }

        /// <summary>(&gt;&gt;=)</summary>
        public Mayhap<TResult> Bind<TResult>(Func<T, Mayhap<TResult>> binder)
        {
            // (>>=) :: forall a b. m a -> (a -> m b) -> m b
            //
            // Sequentially compose two actions, passing any value produced by
            // the first as an argument to the second.

            Require.NotNull(binder, nameof(binder));

#if MONADS_VIA_MAP_MULTIPLY
            return Mayhap<TResult>.μ(Select(binder));
#else
            return _isSome ? binder(_value) : Mayhap<TResult>.None;
#endif
        }

        /// <summary>mplus</summary>
        public Mayhap<T> OrElse(Mayhap<T> other)
            => _isSome ? this : other;
    }

    // Async methods.
    public partial struct Mayhap<T>
    {
        public async Task<Mayhap<TResult>> SelectAsync<TResult>(
            Func<T, Task<TResult>> selector)
        {
            Require.NotNull(selector, nameof(selector));

#if MONADS_VIA_MAP_MULTIPLY
            return _isSome ? Mayhap<TResult>.η(await selector(_value).ConfigureAwait(false))
                : Mayhap<TResult>.None;
#else
            return await BindAsync(__binder).ConfigureAwait(false);

            async Task<Mayhap<TResult>> __binder(T x)
                => Mayhap<TResult>.η(await selector(x).ConfigureAwait(false));
#endif
        }

        public async Task<Mayhap<TResult>> BindAsync<TResult>(
            Func<T, Task<Mayhap<TResult>>> binder)
        {
            Require.NotNull(binder, nameof(binder));

#if MONADS_VIA_MAP_MULTIPLY
            return Mayhap<TResult>.μ(await SelectAsync(binder).ConfigureAwait(false));
#else
            return _isSome ? await binder(_value).ConfigureAwait(false)
                : Mayhap<TResult>.None;
#endif
        }

        public async Task<Mayhap<T>> OrElseAsync(Task<Mayhap<T>> other)
        {
            Require.NotNull(other, nameof(other));

            return _isSome ? this : await other.ConfigureAwait(false);
        }
    }

    // Interface IEquatable<>.
    public partial struct Mayhap<T>
    {
        public static bool operator ==(Mayhap<T> left, Mayhap<T> right)
            => left.Equals(right);

        public static bool operator !=(Mayhap<T> left, Mayhap<T> right)
            => !left.Equals(right);

        public bool Equals(Mayhap<T> other)
            => match(
                some: x => other.Contains(x),
                none: !other._isSome);

        public override bool Equals(object? obj)
            => obj is Mayhap<T> maybe && Equals(maybe);

        public override int GetHashCode()
            => match(
                // BONSANG! When "some", x is NOT null.
                some: x => x!.GetHashCode(),
                none: 0);
    }
}

// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Collections.Generic;
    using System.Diagnostics.CodeAnalysis;
    using System.Threading.Tasks;

    using Anexn = System.ArgumentNullException;

    public partial class AssertEx
    {
        /// <summary>
        /// Verifies that <paramref name="maybe"/> is empty.
        /// </summary>
        public static void None<T>(Maybe<T> maybe)
        {
            True(maybe.IsNone, "The maybe should be empty.");

#if VISIBLE_INTERNALS
            False(maybe.IsSome, "The maybe should be empty.");
#if !DEBUG
            var x = default(T);
            if (x is null)
            {
                Null(maybe.Value);
            }
            else
            {
                // BONSANG! If Value is null, the test will fail.
                Equal(x, maybe.Value!);
            }
#endif
#endif

            Equal(Maybe<T>.None, maybe);
        }

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is NOT empty.
        /// </summary>
        public static void Some<T>(Maybe<T> maybe)
        {
            // IsNone rather than IsSome because it is the public property.
            False(maybe.IsNone, "The maybe should not be empty.");

#if VISIBLE_INTERNALS
            True(maybe.IsSome, "The maybe should not be empty.");
#if !DEBUG
            if (default(T) is null)
            {
                NotNull(maybe.Value);
            }
#endif
#endif

#if !PATCH_EQUALITY
            NotEqual(Maybe<T>.None, maybe);
#endif
        }

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is NOT empty and contains
        /// <paramref name="expected"/>.
        /// </summary>
        public static void Some<T>([DisallowNull] T expected, Maybe<T> maybe)
        {
            False(maybe.IsNone, "The maybe should not be empty.");

#if VISIBLE_INTERNALS
            True(maybe.IsSome, "The maybe should not be empty.");
            // BONSANG! When IsSome is true, Value is NOT null.
            Equal(expected, maybe.Value!);
#else
            if (maybe.TryGetValue(out T value))
            {
                Equal(expected, value);
            }
            else
            {
                Failure("The maybe should not be empty.");
            }
#endif

#if !PATCH_EQUALITY
            NotEqual(Maybe<T>.None, maybe);
#endif

            // We also test Contains().
            True(maybe.Contains(expected));
        }

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is NOT empty and contains
        /// <paramref name="expected"/>.
        /// <para>This overload checks that the enclosed sequence is equivalent
        /// to <paramref name="expected"/>.</para>
        /// </summary>
        public static void Some<T>(IEnumerable<T> expected, Maybe<IEnumerable<T>> maybe)
        {
            False(maybe.IsNone, "The maybe should not be empty.");

#if VISIBLE_INTERNALS
            True(maybe.IsSome, "The maybe should not be empty.");
            // BONSANG! When IsSome is true, Value is NOT null.
            Equal(expected, maybe.Value!);
#else
            if (maybe.TryGetValue(out IEnumerable<T>? value))
            {
                Equal(expected, value);
            }
            else
            {
                Failure("The maybe should not be empty.");
            }
#endif

#if !PATCH_EQUALITY
            NotEqual(Maybe<IEnumerable<T>>.None, maybe);
#endif
        }

        /// <summary>
        /// Verifies that <paramref name="maybe"/> evaluates to true in a
        /// boolean context.
        /// </summary>
        public static void LogicalTrue<T>(Maybe<T> maybe)
#if VISIBLE_INTERNALS
            => True(maybe.ToBoolean(), "The maybe should evaluate to true.");
#else
            => False(maybe.IsNone, "The maybe should evaluate to true.");
#endif

        /// <summary>
        /// Verifies that <paramref name="maybe"/> evaluates to false in a
        /// boolean context.
        /// </summary>
        public static void LogicalFalse<T>(Maybe<T> maybe)
#if VISIBLE_INTERNALS
            => False(maybe.ToBoolean(), "The maybe should evaluate to false.");
#else
            => True(maybe.IsNone, "The maybe should evaluate to false.");
#endif

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is <see cref="Maybe.Unknown"/>.
        /// </summary>
        public static void Unknown(Maybe<bool> maybe)
        {
            True(maybe.IsNone, "The maybe should be empty.");
            Equal(Maybe.Unknown, maybe);
        }
    }

    // Async.
    public partial class AssertEx
    {
        public partial class Async
        {
            /// <summary>
            /// Verifies that the result of <paramref name="task"/> is empty.
            /// </summary>
            public static async Task None<T>(Task<Maybe<T>> task)
            {
                if (task is null) { throw new Anexn(nameof(task)); }

                AssertEx.None(await task);
            }

            /// <summary>
            /// Verifies that the result of <paramref name="task"/> is NOT empty.
            /// </summary>
            public static async Task Some<T>(Task<Maybe<T>> task)
            {
                if (task is null) { throw new Anexn(nameof(task)); }

                AssertEx.Some(await task);
            }

            /// <summary>
            /// Verifies that the result of <paramref name="task"/> is NOT empty
            /// and contains <paramref name="expected"/>.
            /// </summary>
            public static async Task Some<T>([DisallowNull] T expected, Task<Maybe<T>> task)
            {
                if (task is null) { throw new Anexn(nameof(task)); }

                AssertEx.Some(expected, await task);
            }
        }
    }
}

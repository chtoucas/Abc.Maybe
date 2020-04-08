// See LICENSE in the project root for license information.

namespace Abc
{
    using System.Collections.Generic;
    using System.Threading.Tasks;

    using Anexn = System.ArgumentNullException;

    public partial class AssertEx
    {
        /// <summary>
        /// Verifies that <paramref name="maybe"/> is empty.
        /// </summary>
        public static void None<T>(Maybe<T> maybe)
            => True(maybe.IsNone, "The maybe should be empty.");

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is NOT empty.
        /// </summary>
        public static void Some<T>(Maybe<T> maybe)
            // IsNone rather than IsSome because it is the public property.
            => False(maybe.IsNone, "The maybe should not be empty.");

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is NOT empty and contains
        /// <paramref name="expected"/>.
        /// </summary>
        public static void Some<T>(T expected, Maybe<T> maybe)
        {
            False(maybe.IsNone, "The maybe should not be empty.");

            if (maybe.IsSome)
            {
                // BONSANG! When IsSome is true, Value is NOT null.
                Equal(expected, maybe.Value!);
            }

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

            if (maybe.IsSome)
            {
                // BONSANG! When IsSome is true, Value is NOT null.
                Equal(expected, maybe.Value!);
            }

            // REVIEW: We also test Contains().
            True(maybe.Contains(expected));
        }

        /// <summary>
        /// Verifies that <paramref name="maybe"/> evaluates to true in a
        /// boolean context.
        /// </summary>
        public static void LogicalTrue<T>(Maybe<T> maybe)
            => True(maybe.ToBoolean(), "The maybe should evaluate to true.");

        /// <summary>
        /// Verifies that <paramref name="maybe"/> evaluates to false in a
        /// boolean context.
        /// </summary>
        public static void LogicalFalse<T>(Maybe<T> maybe)
            => False(maybe.ToBoolean(), "The maybe should evaluate to false.");

        /// <summary>
        /// Verifies that <paramref name="maybe"/> is <see cref="Maybe.Unknown"/>.
        /// </summary>
        public static void Unknown(Maybe<bool> maybe)
            => True(maybe.IsNone, "The maybe should be empty.");
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
            public static async Task Some<T>(T expected, Task<Maybe<T>> task)
            {
                if (task is null) { throw new Anexn(nameof(task)); }

                AssertEx.Some(expected, await task);
            }
        }
    }
}

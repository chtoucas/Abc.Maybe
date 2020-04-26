// See LICENSE in the project root for license information.

#if NETFRAMEWORK // Enumerable.Append & Enumerable.Prepend
namespace Abc.Edu.Fx
{
    using System.Collections.Generic;

    using Abc.Utilities;

    public static class EnumerableX
    {
        public static IEnumerable<TSource> Append<TSource>(
            this IEnumerable<TSource> source,
            TSource element)
        {
            Require.NotNull(source, nameof(source));

            return iterator();

            IEnumerable<TSource> iterator()
            {
                foreach (var item in source)
                {
                    yield return item;
                }

                yield return element;
            }
        }

        public static IEnumerable<TSource> Prepend<TSource>(
            this IEnumerable<TSource> source,
            TSource element)
        {
            Require.NotNull(source, nameof(source));

            return iterator();

            IEnumerable<TSource> iterator()
            {
                yield return element;

                foreach (var item in source)
                {
                    yield return item;
                }
            }
        }
    }
}
#endif
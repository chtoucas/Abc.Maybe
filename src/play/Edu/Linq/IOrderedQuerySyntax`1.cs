// See LICENSE in the project root for license information.

namespace Abc.Edu.Linq
{
    using System;

    public interface IOrderedQuerySyntax<T> : IQuerySyntax<T>
    {
        IOrderedQuerySyntax<T> ThenBy<TKey>(Func<T, TKey> keySelector);

        IOrderedQuerySyntax<T> ThenByDescending<TKey>(Func<T, TKey> keySelector);
    }
}

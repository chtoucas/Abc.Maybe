// See LICENSE in the project root for license information.

namespace Abc.Edu.Linq
{
    using System;

    public interface IQuerySyntax
    {
        IQuerySyntax<T> Cast<T>();
    }

    public interface IQuerySyntax<T> : IQuerySyntax
    {
        IQuerySyntax<T> Where(Func<T, bool> predicate);

#pragma warning disable CA1716 // Identifiers should not match keywords
        IQuerySyntax<TResult> Select<TResult>(Func<T, TResult> selector);
#pragma warning restore CA1716

        IQuerySyntax<TResult> SelectMany<TMiddle, TResult>(
            Func<T, IQuerySyntax<TMiddle>> selector,
            Func<T, TMiddle, TResult> resultSelector);

        IQuerySyntax<TResult> Join<TInner, TKey, TResult>(
            IQuerySyntax<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, TInner, TResult> resultSelector);

        IQuerySyntax<TResult> GroupJoin<TInner, TKey, TResult>(
            IQuerySyntax<TInner> inner,
            Func<T, TKey> outerKeySelector,
            Func<TInner, TKey> innerKeySelector,
            Func<T, IQuerySyntax<TInner>, TResult> resultSelector);

        IOrderedQuerySyntax<T> OrderBy<TKey>(Func<T, TKey> keySelector);

        IOrderedQuerySyntax<T> OrderByDescending<TKey>(Func<T, TKey> keySelector);

        IQuerySyntax<IGroupingQuerySyntax<TKey, T>> GroupBy<TKey>(Func<T, TKey> keySelector);

        IQuerySyntax<IGroupingQuerySyntax<TKey, TElement>> GroupBy<TKey, TElement>(
            Func<T, TKey> keySelector,
            Func<T, TElement> elementSelector);
    }
}

// See LICENSE in the project root for license information.

namespace Abc.Edu.Linq
{
    public interface IGroupingQuerySyntax<TKey, T> : IQuerySyntax<T>
    {
        TKey Key { get; }
    }
}

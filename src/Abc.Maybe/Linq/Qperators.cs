// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using System.Collections.Generic;

    /// <summary>
    /// Provides a set of extension methods for querying objects that implement
    /// <see cref="IEnumerable{T}"/>.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    ///
    /// <_text><![CDATA[
    /// Overview of the new LINQ operators.
    ///
    /// Projecting:
    /// - SelectAny()       deferred streaming execution
    ///
    /// Filtering:
    /// - WhereAny()        deferred streaming execution
    ///
    /// Element operations:
    /// - ElementAtOrNone() immediate execution
    /// - FirstOrNone()     immediate execution
    /// - LastOrNone()      immediate execution
    /// - SingleOrNone()    immediate execution
    ///
    /// Reference:
    /// https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/classification-of-standard-query-operators-by-manner-of-execution
    /// ]]></_text>
    public static partial class Qperators { }
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Linq
{
    using System.Collections.Generic;

    // TODO (doc): ElementAtOrNone(), how do we handle null? TSource? and Maybe<TSource>.
    // For the others, it is simpler: we don't and if we wanted to, the solution
    // is to use the overload with a predicate.

    /// <summary>
    /// Provides a set of extension methods for querying objects that implement
    /// <see cref="IEnumerable{T}"/>.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    ///
    /// <remarks><![CDATA[
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
    /// ]]></remarks>
    public static partial class Qperators { }
}

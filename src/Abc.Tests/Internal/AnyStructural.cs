// See LICENSE in the project root for license information.

using System;
using System.Collections;
using System.Diagnostics.CodeAnalysis;
using System.Diagnostics.Contracts;

using Anexn = System.ArgumentNullException;

internal sealed class AnyStructural //: IStructuralEquatable
{
    private static readonly AnagramEqualityComparer s_Comparer =
        new AnagramEqualityComparer();

    public string Value = String.Empty;

    // Structural equality to simplify deserialization tests.
    public bool Equals([AllowNull] AnyStructural other)
    {
        if (other is null) { return false; }
        if (ReferenceEquals(this, other)) { return true; }
        return s_Comparer.Equals(Value, other.Value);
    }

    public override bool Equals(object? obj) => Equals(obj as AnyStructural);

    public override int GetHashCode() => s_Comparer.GetHashCode(Value);

    //[Pure]
    //bool IStructuralEquatable.Equals(object? other, IEqualityComparer comparer)
    //{
    //    if (comparer is null) { throw new Anexn(nameof(comparer)); }

    //    if (other is null || !(other is AnyStructural any)) { return false; }

    //    return comparer.Equals(Value, any.Value);
    //}

    //[Pure]
    //int IStructuralEquatable.GetHashCode(IEqualityComparer comparer)
    //{
    //    if (comparer is null) { throw new Anexn(nameof(comparer)); }

    //    return comparer.GetHashCode(Value);
    //}
}

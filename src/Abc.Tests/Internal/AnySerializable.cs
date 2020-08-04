// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

#if !NETSTANDARD1_x // System.Runtime.Serialization

using System;
using System.Diagnostics.CodeAnalysis;

[Serializable]
internal sealed class AnySerializable : IEquatable<AnySerializable>
{
    public short Item1;
    public int Item2;
    public long Item3;

    // Structural equality to simplify deserialization tests.
    public bool Equals([AllowNull] AnySerializable other)
    {
        if (other is null) { return false; }
        if (ReferenceEquals(this, other)) { return true; }
        return Item1 == other.Item1 && Item2 == other.Item2 && Item3 == other.Item3;
    }

    public override bool Equals(object? obj) => Equals(obj as AnySerializable);

    public override int GetHashCode() => HashCode.Combine(Item1, Item2, Item3);
}

#endif

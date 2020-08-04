// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

using Abc;

/// <summary>
/// Represents a singleton reference type.
/// </summary>
internal sealed class AnyResult
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyResult"/> class.
    /// </summary>
    public static readonly Maybe<AnyResult> None = Maybe<AnyResult>.None;

    private AnyResult() { }

    /// <summary>
    /// Gets the unique instance of the <see cref="AnyResult"/> class.
    /// </summary>
    public static AnyResult Value => Instance_.Value;

    public static Maybe<AnyResult> Some { get; }
        = Maybe.SomeOrNone(Instance_.Value);

    private static class Instance_
    {
        public static readonly AnyResult Value = new AnyResult();
    }
}
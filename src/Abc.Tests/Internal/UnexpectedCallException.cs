// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

#pragma warning disable CA1032 // Implement standard exception constructors
#pragma warning disable CA1303 // Do not pass literals as localized parameters.

using System;

internal sealed class UnexpectedCallException : InvalidOperationException
{
    public UnexpectedCallException() : base("Unexpected call.") { }
}

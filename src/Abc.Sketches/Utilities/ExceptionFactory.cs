﻿// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

#pragma warning disable CA1303 // Do not pass literals as localized parameters.

namespace Abc.Utilities
{
    using System;

    /// <summary>
    /// Provides static methods to create exceptions.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    internal static class ExceptionFactory
    {
        public static readonly InvalidOperationException EmptySequence
            = new InvalidOperationException("The sequence was empty.");

        public static InvalidOperationException ControlFlow
            => new InvalidOperationException(
                "The flow of execution just reached a section of the code that should have been unreachable."
                + $"{Environment.NewLine}Most certainly signals a coding error. Please report.");

        public static readonly ArgumentException MaybeComparer_InvalidType
            = new ArgumentException("Type of argument is not compatible with MaybeComparer<T>.");
    }
}

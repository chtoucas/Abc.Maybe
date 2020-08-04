// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

#pragma warning disable CA1303 // Do not pass literals as localized parameters.

namespace Abc.Utilities
{
    using System;

    internal partial class ExceptionFactory
    {
        public static InvalidOperationException Maybe_NoValue =>
            new InvalidOperationException("The object does not contain any value.");

        public static InvalidCastException FromMaybe_NoValue =>
            new InvalidCastException("The object does not contain any value.");
    }
}

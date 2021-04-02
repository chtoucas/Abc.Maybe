// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Utilities
{
    using System;

    internal partial class ExceptionFactory
    {
        public static InvalidOperationException Maybe_NoValue =>
            new("The object does not contain any value.");

        public static InvalidCastException FromMaybe_NoValue =>
            new("The object does not contain any value.");
    }
}

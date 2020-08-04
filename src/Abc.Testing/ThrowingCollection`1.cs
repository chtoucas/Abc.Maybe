// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;
    using System.Collections;
    using System.Collections.Generic;

    /// <summary>
    /// Class to help for deferred execution tests: it throw an exception
    /// when <see cref="GetEnumerator"/> is called.
    /// </summary>
    public sealed class ThrowingCollection<T> : IEnumerable<T>
    {
        public IEnumerator<T> GetEnumerator() => throw new InvalidOperationException();

        IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
    }
}
﻿// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.Extensions
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.Contracts;

    /// <summary>
    /// Provides extension methods for <see cref="IDictionary{T,U}"/>.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    public static class DictionaryX
    {
        [Pure]
        public static Maybe<TValue> MayGetValue<TKey, TValue>(
            this IDictionary<TKey, TValue> @this, TKey key)
            where TKey : notnull
        {
            if (@this is null) { throw new ArgumentNullException(nameof(@this)); }

            return key is not null && @this.TryGetValue(key, out TValue? value)
                ? Maybe.Of(value)
                : Maybe<TValue>.None;
        }
    }
}

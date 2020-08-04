// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;
    using System.Collections.Generic;

    using Anexn = System.ArgumentNullException;

    public partial class AssertEx
    {
        public static void ThrowsOnNext<T>(IEnumerable<T> seq)
        {
            if (seq is null) { throw new Anexn(nameof(seq)); }

            using var iter = seq.GetEnumerator();
            Throws<InvalidOperationException>(() => iter.MoveNext());
        }

        public static void ThrowsAfter<T>(IEnumerable<T> seq, int count)
        {
            if (seq is null) { throw new Anexn(nameof(seq)); }

            int i = 0;
            using var iter = seq.GetEnumerator();
            while (i < count) { True(iter.MoveNext()); i++; }
            Throws<InvalidOperationException>(() => iter.MoveNext());
        }

        public static void CalledOnNext<T>(IEnumerable<T> seq, ref bool called)
        {
            if (seq is null) { throw new Anexn(nameof(seq)); }

            using var iter = seq.GetEnumerator();
            iter.MoveNext();
            True(called);
        }

        public static void CalledAfter<T>(IEnumerable<T> seq, int count, ref bool called)
        {
            if (seq is null) { throw new Anexn(nameof(seq)); }

            int i = 0;
            using var iter = seq.GetEnumerator();
            while (i < count) { True(iter.MoveNext()); i++; }
            iter.MoveNext();
            True(called);
        }
    }
}

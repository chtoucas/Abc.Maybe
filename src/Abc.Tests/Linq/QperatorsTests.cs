// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#region License
// The MIT License (MIT)
//
// Copyright (c) .NET Foundation and Contributors
//
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
#endregion

// Adapted from https://github.com/dotnet/runtime/blob/master/src/libraries/System.Linq/tests/EnumerableTests.cs

namespace Abc.Linq
{
    using System.Collections.Generic;

    public abstract class QperatorsTests
    {
        protected QperatorsTests() { }

        protected static readonly IEnumerable<int> NullSeq = null!;
        protected static readonly IEnumerable<int> AnySeq = new ThrowingCollection<int>();

        protected static bool IsEven(int num) => num % 2 == 0;

        private protected static IEnumerable<T> ForceNotCollection<T>(IEnumerable<T> source)
        {
            foreach (T item in source)
            {
                yield return item;
            }
        }

        private protected static IEnumerable<int> NumberRangeGuaranteedNotCollectionType(int num, int count)
        {
            for (int i = 0; i < count; i++)
            {
                yield return num + i;
            }
        }

        private protected static IEnumerable<int> RepeatedNumberGuaranteedNotCollectionType(int num, long count)
        {
            for (long i = 0; i < count; i++)
            {
                yield return num;
            }
        }
    }
}

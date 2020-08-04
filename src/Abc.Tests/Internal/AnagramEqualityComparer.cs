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

using System.Collections.Generic;
using System.Linq;

// Beware, with .NET Standard 1.x, we must call ToCharArray() explicitly.

internal sealed class AnagramEqualityComparer : EqualityComparer<string>
{
    public override bool Equals(string? x, string? y)
    {
        if (ReferenceEquals(x, y)) { return true; }
        if (x is null || y is null) { return false; }
        int length = x.Length;
        if (length != y.Length) { return false; }
        using (var en = x.ToCharArray().OrderBy(c => c).GetEnumerator())
        {
            foreach (char c in y.ToCharArray().OrderBy(c => c))
            {
                en.MoveNext();
                if (c != en.Current) { return false; }
            }
        }
        return true;
    }

    public override int GetHashCode(string obj)
    {
        if (obj is null) { return 0; }
        int hash = obj.Length;
        foreach (char c in obj.ToCharArray())
        {
            hash ^= c;
        }
        return hash;
    }
}

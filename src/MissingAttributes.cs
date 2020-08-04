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

#if NETSTANDARD1_x // SerializableAttribute

namespace System
{
    using System;
    using System.Reflection;

    [AttributeUsage(
        AttributeTargets.Class
        | AttributeTargets.Struct
        | AttributeTargets.Enum
        | AttributeTargets.Delegate,
        Inherited = false)]
    internal sealed class SerializableAttribute : Attribute { }
}

#endif

#if NETSTANDARD1_x || NETCOREAPP1_x // ExcludeFromCodeCoverageAttribute

namespace System.Diagnostics.CodeAnalysis
{
    [AttributeUsage(
        AttributeTargets.Class
        | AttributeTargets.Constructor
        | AttributeTargets.Event
        | AttributeTargets.Method
        | AttributeTargets.Property
        | AttributeTargets.Struct,
        Inherited = false,
        AllowMultiple = false)]
    internal sealed class ExcludeFromCodeCoverageAttribute : Attribute { }
}

#endif

#if NETSTANDARD1_x || NETCOREAPP1_x // PureAttribute

namespace System.Diagnostics.Contracts
{
    using System;

    [Conditional("CONTRACTS_FULL")]
    [AttributeUsage(
        AttributeTargets.Constructor
        | AttributeTargets.Method
        | AttributeTargets.Property
        | AttributeTargets.Event
        | AttributeTargets.Delegate
        | AttributeTargets.Class
        | AttributeTargets.Parameter,
        Inherited = true,
        AllowMultiple = false)]
    internal sealed class PureAttribute : Attribute { }
}

#endif

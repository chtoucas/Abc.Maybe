// See LICENSE.dotnet in the project root for license information.

#if (NETSTANDARD1_6 || NETSTANDARD1_5 || NETSTANDARD1_4 || NETSTANDARD1_3 || NETSTANDARD1_2 || NETSTANDARD1_1 || NETSTANDARD1_0) // Missing attributes

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
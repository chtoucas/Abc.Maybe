// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc
{
    using System;

    [AttributeUsage(
        AttributeTargets.Class
        | AttributeTargets.Struct
        | AttributeTargets.Enum
        | AttributeTargets.Constructor
        | AttributeTargets.Method
        | AttributeTargets.Property
        | AttributeTargets.Field
        | AttributeTargets.Event
        | AttributeTargets.Interface
        | AttributeTargets.Delegate,
        Inherited = false)]
    internal sealed class RejectedApiAttribute : Attribute
    {
        public RejectedApiAttribute() { }

        public RejectedApiAttribute(string message)
        {
            Message = message;
        }

        public string Message { get; } = String.Empty;
    }
}

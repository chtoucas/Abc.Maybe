// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

using System;

[Flags]
internal enum AnyFlagEnum
{
    None = 0,
    One = 1 << 0,
    Two = 1 << 1,
    Four = 1 << 2,

    OneTwo = One | Two,
    OneTwoFour = One | Two | Four
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

// The algorithm used by .NET to auto-increment the assembly version is as
// follows:
// - The default build number increments daily.
// - The default revision number is the number of seconds since midnight local
//   time (without taking into account time zone adjustments for daylight
//   saving time), divided by 2.
//
// Remarks:
// - This feature is only available to AssemblyVersion, not to
//   AssemblyFileVersion.
// - During the same day, two builds may end up with the same assembly version.
// - Build and revision numbers must be less than or equal to 65534
//   (UInt16.MaxValue - 1).
//
// Here we implement a slighty different algorithm:
// - We use it for AssemblyFileVersion not for AssemblyVersion.
// - Use UTC time.
// - The build number is the number of half-days since 2020-01-01 00:00:00.
// - The revision number is the number of seconds since midnight in the morning
//   and since midday in the afternoon.
//
// This way, there is less chance of getting the same numbers during a single
// day on the same build machine. The schema will break in approximately 89
// years...
//
// Worth reminding, if we used a schema that simply incremented the build
// numbers, we would generate a lot of unecessary holes in the sequence. Indeed
// due to incremental batching a build might not do anything. That's a good
// reason to use an algorithm depending only on the date and the time.

open System

let orig = new DateTime(2020, 1, 1, 0, 0, 0, DateTimeKind.Utc)

let now  = DateTime.UtcNow
let am   = now.Hour < 12

// Midnight or noon.
let mon = new DateTime(now.Year, now.Month, now.Day, (if am then 0 else 12), 0, 0, DateTimeKind.Utc)

let halfdays = 2 * (now - orig).Days + (if am then 0 else 1)
let seconds  = (now - mon).TotalSeconds

let buildnum = uint16(halfdays)
let revnum   = uint16(seconds)

// revnum is left padded with 0 to ensure it has a length of 5.
//let serialnum = sprintf "%i%05i" buildnum revnum

// Format "YYYYMMDD.Thhmmss".
// Weird thing, NuGet.targets doesn't like a prerelease label which contains
// the string ".0". To avoid the problem we prefix the time part with "T".
let timestamp = sprintf "%i%02i%02i.T%02i%02i%02i" now.Year now.Month now.Day now.Hour now.Minute now.Second

printfn "%i;%i;%s" buildnum revnum timestamp

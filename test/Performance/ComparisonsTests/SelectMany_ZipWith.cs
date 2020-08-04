// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2019 Narvalo.Org. All rights reserved.

namespace Abc.ComparisonsTests
{
    using System;

    using BenchmarkDotNet.Attributes;

    [MemoryDiagnoser]
    public partial class SelectMany_ZipWith
    {
        private static readonly Maybe<MyVal> s_OuterVal = Maybe.Some(new MyVal(314));
        private static readonly Maybe<MyVal> s_InnerVal = Maybe.Some(new MyVal(271));

        private static readonly Maybe<MyObj> s_OuterObj = Maybe.SomeOrNone(new MyObj(314));
        private static readonly Maybe<MyObj> s_InnerObj = Maybe.SomeOrNone(new MyObj(271));

        public struct MyVal : IEquatable<MyVal>
        {
            public MyVal(int value) => Value = value;

            public int Value { get; }

            public static bool operator ==(MyVal left, MyVal right) => left.Value == right.Value;
            public static bool operator !=(MyVal left, MyVal right) => left.Value != right.Value;
            public bool Equals(MyVal other) => Value == other.Value;
            public override bool Equals(object? obj) => obj is MyVal myVal && Equals(myVal);
            public override int GetHashCode() => Value;
        }

        public sealed class MyObj
        {
            public MyObj(int value) => Value = value;

            public int Value { get; }
        }
    }

    public partial class SelectMany_ZipWith
    {
        [Benchmark]
        public Maybe<MyVal> SelectMany_Struct() =>
            from x in s_OuterVal
            from y in s_InnerVal
            select new MyVal(x.Value + y.Value);

        [Benchmark(Baseline = true)]
        public Maybe<MyVal> ZipWith_Struct() =>
            s_OuterVal.ZipWith(s_InnerVal, (x, y) => new MyVal(x.Value + y.Value));

        [Benchmark]
        public Maybe<MyObj> SelectMany_Class() =>
            from x in s_OuterObj
            from y in s_InnerObj
            select new MyObj(x.Value + y.Value);

        [Benchmark]
        public Maybe<MyObj> ZipWith_Class() =>
            s_OuterObj.ZipWith(s_InnerObj, (x, y) => new MyObj(x.Value + y.Value));
    }
}

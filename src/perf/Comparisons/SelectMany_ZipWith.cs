// See LICENSE in the project root for license information.

namespace PerfTool.Comparisons
{
    using System;

    using Abc;

    using BenchmarkDotNet.Attributes;

    [MemoryDiagnoser]
    public partial class SelectMany_ZipWith
    {
        private static readonly Maybe<MyVal> s_OuterVal = Maybe.Some(new MyVal { Value = 314 });
        private static readonly Maybe<MyVal> s_InnerVal = Maybe.Some(new MyVal { Value = 271 });

        private static readonly Maybe<MyObj> s_OuterObj = Maybe.SomeOrNone(new MyObj { Value = 314 });
        private static readonly Maybe<MyObj> s_InnerObj = Maybe.SomeOrNone(new MyObj { Value = 271 });

        public struct MyVal : IEquatable<MyVal>
        {
            public int Value;

            public static bool operator ==(MyVal left, MyVal right) => left.Value == right.Value;
            public static bool operator !=(MyVal left, MyVal right) => left.Value != right.Value;
            public bool Equals(MyVal other) => Value == other.Value;
            public override bool Equals(object? obj) => obj is MyVal myVal && Equals(myVal);
            public override int GetHashCode() => Value;
        }

        public sealed class MyObj
        {
            public int Value;
        }
    }

    public partial class SelectMany_ZipWith
    {
        [Benchmark]
        public Maybe<MyVal> SelectMany_Struct() =>
            from x in s_OuterVal
            from y in s_InnerVal
            select new MyVal { Value = x.Value + y.Value };

        [Benchmark(Baseline = true)]
        public Maybe<MyVal> ZipWith_Struct() =>
            s_OuterVal.ZipWith(s_InnerVal, (x, y) => new MyVal { Value = x.Value + y.Value });

        [Benchmark]
        public Maybe<MyObj> SelectMany_Class() =>
            from x in s_OuterObj
            from y in s_InnerObj
            select new MyObj { Value = x.Value + y.Value };

        [Benchmark]
        public Maybe<MyObj> ZipWith_Class() =>
            s_OuterObj.ZipWith(s_InnerObj, (x, y) => new MyObj { Value = x.Value + y.Value });
    }
}

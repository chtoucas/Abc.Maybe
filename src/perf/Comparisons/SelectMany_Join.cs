// See LICENSE in the project root for license information.

namespace PerfTool.Comparisons
{
    using System;

    using Abc;

    using BenchmarkDotNet.Attributes;

    [MemoryDiagnoser]
    public partial class SelectMany_Join
    {
        private static readonly Maybe<MyItem> s_OuterObj =
            Maybe.SomeOrNone(new MyItem { Id = 1, Name = "Name" });

        private static readonly Maybe<MyInfo> s_InnerObj =
            Maybe.SomeOrNone(new MyInfo { Id = 1, Description = "Description" });

        public sealed class MyItem
        {
            public int Id;
            public string Name = String.Empty;
        }

        public sealed class MyInfo
        {
            public int Id;
            public string Description = String.Empty;
        }

        public sealed class MyData
        {
            public int Id;
            public string Name = String.Empty;
            public string Description = String.Empty;
        }
    }

    public partial class SelectMany_Join
    {
        [Benchmark]
        public Maybe<MyData> SelectMany_Class() =>
            from x in s_OuterObj
            from y in s_InnerObj
            where x.Id == y.Id
            select new MyData
            {
                Id = x.Id,
                Name = x.Name,
                Description = y.Description
            };

        [Benchmark(Baseline = true)]
        public Maybe<MyData> Join_Class() =>
            from x in s_OuterObj
            join y in s_InnerObj on x.Id equals y.Id
            select new MyData
            {
                Id = x.Id,
                Name = x.Name,
                Description = y.Description
            };
    }
}

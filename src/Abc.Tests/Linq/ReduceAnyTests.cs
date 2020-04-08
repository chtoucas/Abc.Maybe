// See LICENSE in the project root for license information.

namespace Abc.Linq
{
    using Xunit;

    using Assert = AssertEx;

    public sealed partial class ReduceAnyTests : QperatorsTests { }

    // Arg check.
    public partial class ReduceAnyTests
    {
        [Fact]
        public static void NullSource() =>
            Assert.ThrowsAnexn("source", () =>
                NullSeq.ReduceAny(Kunc<int, int, int>.Any));

        [Fact]
        public static void NullAccumulator() =>
            Assert.ThrowsAnexn("accumulator", () =>
                AnySeq.ReduceAny(Kunc<int, int, int>.Null));

        [Fact]
        public static void NullSource_WithPredicate() =>
            Assert.ThrowsAnexn("source", () =>
                NullSeq.ReduceAny(Kunc<int, int, int>.Any, Funk<Maybe<int>, bool>.Any));

        [Fact]
        public static void NullAccumulator_WithPredicate() =>
            Assert.ThrowsAnexn("accumulator", () =>
                AnySeq.ReduceAny(Kunc<int, int, int>.Null, Funk<Maybe<int>, bool>.Any));

        [Fact]
        public static void NullPredicate() =>
            Assert.ThrowsAnexn("predicate", () =>
                AnySeq.ReduceAny(Kunc<int, int, int>.Any, Funk<Maybe<int>, bool>.Null));
    }
}

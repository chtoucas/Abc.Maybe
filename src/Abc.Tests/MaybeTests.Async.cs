// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Threading.Tasks;

    using Xunit;

    using Assert = AssertEx;

    // Async methods.
    // Notes:
    // - do not append ConfigureAwait(false), this is not necessary; see
    //   https://github.com/xunit/xunit/issues/1215
    // - use Task.Yield() to force asynchronicity.
    public partial class MaybeTests { }

    // Instance methods (eager validation).
    public partial class MaybeTests
    {
        #region BindAsync()

        [Fact]
        public static void BindAsync_None_NullBinder()
        {
            Assert.ThrowsAnexn("binder", () => Ø.BindAsync(Kunc<int, AnyResult>.NullAsync));
            Assert.ThrowsAnexn("binder", () => AnyT.None.BindAsync(Kunc<AnyT, AnyResult>.NullAsync));
        }

        [Fact]
        public static void BindAsync_Some_NullBinder()
        {
            Assert.ThrowsAnexn("binder", () => One.BindAsync(Kunc<int, AnyResult>.NullAsync));
            Assert.ThrowsAnexn("binder", () => AnyT.Some.BindAsync(Kunc<AnyT, AnyResult>.NullAsync));
        }

        [Fact]
        public static async Task BindAsync_None()
        {
            await Assert.Async.None(Ø.BindAsync(Kunc<int, AnyResult>.AnyAsync));
            await Assert.Async.None(NoText.BindAsync(Kunc<string, AnyResult>.AnyAsync));
            await Assert.Async.None(NoUri.BindAsync(Kunc<Uri, AnyResult>.AnyAsync));
            await Assert.Async.None(AnyT.None.BindAsync(Kunc<AnyT, AnyResult>.AnyAsync));
        }

        [Fact]
        public static async Task BindAsync_None_Sync()
        {
            await Assert.Async.None(Ø.BindAsync(Kunc<int, AnyResult>.AnySync));
            await Assert.Async.None(NoText.BindAsync(Kunc<string, AnyResult>.AnySync));
            await Assert.Async.None(NoUri.BindAsync(Kunc<Uri, AnyResult>.AnySync));
            await Assert.Async.None(AnyT.None.BindAsync(Kunc<AnyT, AnyResult>.AnySync));
        }

        [Fact]
        public static async Task BindAsync_Some_WithBinderReturningNone()
        {
            await Assert.Async.None(One.BindAsync(ReturnNoneAsync));
            await Assert.Async.None(SomeText.BindAsync(ReturnNoneAsync));
            await Assert.Async.None(SomeUri.BindAsync(ReturnNoneAsync));
            await Assert.Async.None(AnyT.Some.BindAsync(ReturnNoneAsync));
        }

        [Fact]
        public static async Task BindAsync_Some_WithBinderReturningNone_Sync()
        {
            await Assert.Async.None(One.BindAsync(ReturnNoneSync));
            await Assert.Async.None(SomeText.BindAsync(ReturnNoneSync));
            await Assert.Async.None(SomeUri.BindAsync(ReturnNoneSync));
            await Assert.Async.None(AnyT.Some.BindAsync(ReturnNoneSync));
        }

        [Fact]
        public static async Task BindAsync_Some_WithBinderReturningSome()
        {
            await Assert.Async.Some(AnyResult.Value, One.BindAsync(ReturnSomeAsync));
            await Assert.Async.Some(AnyResult.Value, SomeText.BindAsync(ReturnSomeAsync));
            await Assert.Async.Some(AnyResult.Value, SomeUri.BindAsync(ReturnSomeAsync));
            await Assert.Async.Some(AnyResult.Value, AnyT.Some.BindAsync(ReturnSomeAsync));
        }

        [Fact]
        public static async Task BindAsync_Some_WithBinderReturningSome_Sync()
        {
            await Assert.Async.Some(AnyResult.Value, One.BindAsync(ReturnSomeSync));
            await Assert.Async.Some(AnyResult.Value, SomeText.BindAsync(ReturnSomeSync));
            await Assert.Async.Some(AnyResult.Value, SomeUri.BindAsync(ReturnSomeSync));
            await Assert.Async.Some(AnyResult.Value, AnyT.Some.BindAsync(ReturnSomeSync));
        }

        [Fact]
        public static async Task BindAsync_SomeInt32() =>
            await Assert.Async.Some(6, Two.BindAsync(Times3Async_));

        [Fact]
        public static async Task BindAsync_SomeInt32_Sync() =>
            await Assert.Async.Some(6, Two.BindAsync(Times3Sync_));

        [Fact]
        public static async Task BindAsync_SomeInt64() =>
            await Assert.Async.Some(8L, TwoL.BindAsync(Times4Async_));

        [Fact]
        public static async Task BindAsync_SomeInt64_Sync() =>
            await Assert.Async.Some(8L, TwoL.BindAsync(Times4Sync_));

        [Fact]
        public static async Task BindAsync_SomeUri() =>
            await Assert.Async.Some(MyUri.AbsoluteUri, SomeUri.BindAsync(GetAbsoluteUriAsync_));

        [Fact]
        public static async Task BindAsync_SomeUri_Sync() =>
            await Assert.Async.Some(MyUri.AbsoluteUri, SomeUri.BindAsync(GetAbsoluteUriSync_));

        #endregion

        #region SelectAsync()

        [Fact]
        public static void SelectAsync_None_NullSelector()
        {
            Assert.ThrowsAnexn("selector", () => Ø.SelectAsync(Funk<int, AnyResult>.NullAsync));
            Assert.ThrowsAnexn("selector", () => AnyT.None.SelectAsync(Funk<AnyT, AnyResult>.NullAsync));
        }

        [Fact]
        public static void SelectAsync_Some_NullSelector()
        {
            Assert.ThrowsAnexn("selector", () => One.SelectAsync(Funk<int, AnyResult>.NullAsync));
            Assert.ThrowsAnexn("selector", () => AnyT.Some.SelectAsync(Funk<AnyT, AnyResult>.NullAsync));
        }

        [Fact]
        public static async Task SelectAsync_None()
        {
            await Assert.Async.None(Ø.SelectAsync(Funk<int, AnyResult>.AnyAsync));
            await Assert.Async.None(NoText.SelectAsync(Funk<string, AnyResult>.AnyAsync));
            await Assert.Async.None(NoUri.SelectAsync(Funk<Uri, AnyResult>.AnyAsync));
            await Assert.Async.None(AnyT.None.SelectAsync(Funk<AnyT, AnyResult>.AnyAsync));
        }

        [Fact]
        public static async Task SelectAsync_None_Sync()
        {
            await Assert.Async.None(Ø.SelectAsync(Funk<int, AnyResult>.AnySync));
            await Assert.Async.None(NoText.SelectAsync(Funk<string, AnyResult>.AnySync));
            await Assert.Async.None(NoUri.SelectAsync(Funk<Uri, AnyResult>.AnySync));
            await Assert.Async.None(AnyT.None.SelectAsync(Funk<AnyT, AnyResult>.AnySync));
        }

        [Fact]
        public static async Task SelectAsync_SomeInt32() =>
            await Assert.Async.Some(6, Two.SelectAsync(Times3Async));

        [Fact]
        public static async Task SelectAsync_SomeInt32_Sync() =>
            await Assert.Async.Some(6, Two.SelectAsync(Times3Sync));

        [Fact]
        public static async Task SelectAsync_SomeInt64() =>
            await Assert.Async.Some(8L, TwoL.SelectAsync(Times4Async));

        [Fact]
        public static async Task SelectAsync_SomeInt64_Sync() =>
            await Assert.Async.Some(8L, TwoL.SelectAsync(Times4Sync));

        [Fact]
        public static async Task SelectAsync_SomeUri() =>
            await Assert.Async.Some(MyUri.AbsoluteUri, SomeUri.SelectAsync(GetAbsoluteUriAsync));

        [Fact]
        public static async Task SelectAsync_SomeUri_Sync() =>
            await Assert.Async.Some(MyUri.AbsoluteUri, SomeUri.SelectAsync(GetAbsoluteUriSync));

        #endregion

        #region OrElseAsync()

        [Fact]
        public static void OrElseAsync_None_NullOther()
        {
            Assert.ThrowsAnexn("other", () => Ø.OrElseAsync(null!));
            Assert.ThrowsAnexn("other", () => AnyT.None.OrElseAsync(null!));
        }

        [Fact]
        public static void OrElseAsync_Some_NullOther()
        {
            Assert.ThrowsAnexn("other", () => One.OrElseAsync(null!));
            Assert.ThrowsAnexn("other", () => AnyT.Some.OrElseAsync(null!));
        }

        [Fact]
        public static async Task OrElseAsync_None()
        {
            await Assert.Async.Some(3, Ø.OrElseAsync(ReturnAsync_(3)));
            await Assert.Async.Some("other", NoText.OrElseAsync(ReturnAsync_("other")));

            var otherUri = new Uri("https://source.dot.net/");
            await Assert.Async.Some(otherUri, NoUri.OrElseAsync(ReturnAsync_(otherUri)));

            var otherAnyT = AnyT.Value;
            await Assert.Async.Some(otherAnyT, AnyT.None.OrElseAsync(ReturnAsync_(otherAnyT)));
        }

        [Fact]
        public static async Task OrElseAsync_None_Sync()
        {
            await Assert.Async.Some(3, Ø.OrElseAsync(ReturnSync_(3)));
            await Assert.Async.Some("other", NoText.OrElseAsync(ReturnSync_("other")));

            var otherUri = new Uri("https://source.dot.net/");
            await Assert.Async.Some(otherUri, NoUri.OrElseAsync(ReturnSync_(otherUri)));

            var otherAnyT = AnyT.Value;
            await Assert.Async.Some(otherAnyT, AnyT.None.OrElseAsync(ReturnSync_(otherAnyT)));
        }

        [Fact]
        public static async Task OrElseAsync_Some()
        {
            var anyT = AnyT.New();
            await Assert.Async.Some(anyT.Value, anyT.Some.OrElseAsync(ReturnAsync_(AnyT.Value)));
        }

        [Fact]
        public static async Task OrElseAsync_Some_Sync()
        {
            var anyT = AnyT.New();
            await Assert.Async.Some(anyT.Value, anyT.Some.OrElseAsync(ReturnSync_(AnyT.Value)));
        }

        [Fact]
        public static async Task OrElseAsync_SomeInt32() =>
            await Assert.Async.Some(1, One.OrElseAsync(ReturnAsync_(3)));

        [Fact]
        public static async Task OrElseAsync_SomeInt32_Sync() =>
            await Assert.Async.Some(1, One.OrElseAsync(ReturnSync_(3)));

        [Fact]
        public static async Task OrElseAsync_SomeText() =>
            await Assert.Async.Some(MyText, SomeText.OrElseAsync(ReturnAsync_("other")));

        [Fact]
        public static async Task OrElseAsync_SomeText_Sync() =>
            await Assert.Async.Some(MyText, SomeText.OrElseAsync(ReturnSync_("other")));

        [Fact]
        public static async Task OrElseAsync_SomeUri()
        {
            var otherUri = new Uri("https://source.dot.net/");
            await Assert.Async.Some(MyUri, SomeUri.OrElseAsync(ReturnAsync_(otherUri)));
        }

        [Fact]
        public static async Task OrElseAsync_SomeUri_Sync()
        {
            var otherUri = new Uri("https://source.dot.net/");
            await Assert.Async.Some(MyUri, SomeUri.OrElseAsync(ReturnSync_(otherUri)));
        }

        #endregion
    }

    // Extension methods (delayed validation).
    public partial class MaybeTests
    {
        public static class HelperClass
        {
            #region BindAsync()

            [Fact]
            public static async Task BindAsync_None_NullBinder()
            {
                await Assert.Async.ThrowsAnexn("binder", () => MaybeEx.BindAsync(Ø, Kunc<int, AnyResult>.NullAsync));
                await Assert.Async.ThrowsAnexn("binder", () => MaybeEx.BindAsync(AnyT.None, Kunc<AnyT, AnyResult>.NullAsync));
            }

            [Fact]
            public static async Task BindAsync_Some_NullBinder()
            {
                await Assert.Async.ThrowsAnexn("binder", () => MaybeEx.BindAsync(One, Kunc<int, AnyResult>.NullAsync));
                await Assert.Async.ThrowsAnexn("binder", () => MaybeEx.BindAsync(AnyT.Some, Kunc<AnyT, AnyResult>.NullAsync));
            }

            [Fact]
            public static async Task BindAsync_None()
            {
                await Assert.Async.None(MaybeEx.BindAsync(Ø, Kunc<int, AnyResult>.AnyAsync));
                await Assert.Async.None(MaybeEx.BindAsync(NoText, Kunc<string, AnyResult>.AnyAsync));
                await Assert.Async.None(MaybeEx.BindAsync(NoUri, Kunc<Uri, AnyResult>.AnyAsync));
                await Assert.Async.None(MaybeEx.BindAsync(AnyT.None, Kunc<AnyT, AnyResult>.AnyAsync));
            }

            [Fact]
            public static async Task BindAsync_None_Sync()
            {
                await Assert.Async.None(MaybeEx.BindAsync(Ø, Kunc<int, AnyResult>.AnySync));
                await Assert.Async.None(MaybeEx.BindAsync(NoText, Kunc<string, AnyResult>.AnySync));
                await Assert.Async.None(MaybeEx.BindAsync(NoUri, Kunc<Uri, AnyResult>.AnySync));
                await Assert.Async.None(MaybeEx.BindAsync(AnyT.None, Kunc<AnyT, AnyResult>.AnySync));
            }

            [Fact]
            public static async Task BindAsync_Some_WithBinderReturningNone()
            {
                await Assert.Async.None(MaybeEx.BindAsync(One, ReturnNoneAsync));
                await Assert.Async.None(MaybeEx.BindAsync(SomeText, ReturnNoneAsync));
                await Assert.Async.None(MaybeEx.BindAsync(SomeUri, ReturnNoneAsync));
                await Assert.Async.None(MaybeEx.BindAsync(AnyT.Some, ReturnNoneAsync));
            }

            [Fact]
            public static async Task BindAsync_Some_WithBinderReturningNone_Sync()
            {
                await Assert.Async.None(MaybeEx.BindAsync(One, ReturnNoneSync));
                await Assert.Async.None(MaybeEx.BindAsync(SomeText, ReturnNoneSync));
                await Assert.Async.None(MaybeEx.BindAsync(SomeUri, ReturnNoneSync));
                await Assert.Async.None(MaybeEx.BindAsync(AnyT.Some, ReturnNoneSync));
            }

            [Fact]
            public static async Task BindAsync_Some_WithBinderReturningSome()
            {
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(One, ReturnSomeAsync));
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(SomeText, ReturnSomeAsync));
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(SomeUri, ReturnSomeAsync));
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(AnyT.Some, ReturnSomeAsync));
            }

            [Fact]
            public static async Task BindAsync_Some_WithBinderReturningSome_Sync()
            {
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(One, ReturnSomeSync));
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(SomeText, ReturnSomeSync));
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(SomeUri, ReturnSomeSync));
                await Assert.Async.Some(AnyResult.Value, MaybeEx.BindAsync(AnyT.Some, ReturnSomeSync));
            }

            [Fact]
            public static async Task BindAsync_SomeInt32() =>
                await Assert.Async.Some(6, MaybeEx.BindAsync(Two, Times3Async_));

            [Fact]
            public static async Task BindAsync_SomeInt32_Sync() =>
                await Assert.Async.Some(6, MaybeEx.BindAsync(Two, Times3Sync_));

            [Fact]
            public static async Task BindAsync_SomeInt64() =>
                await Assert.Async.Some(8L, MaybeEx.BindAsync(TwoL, Times4Async_));

            [Fact]
            public static async Task BindAsync_SomeInt64_Sync() =>
                await Assert.Async.Some(8L, MaybeEx.BindAsync(TwoL, Times4Sync_));

            [Fact]
            public static async Task BindAsync_SomeUri() =>
                await Assert.Async.Some(MyUri.AbsoluteUri,
                    MaybeEx.BindAsync(SomeUri, GetAbsoluteUriAsync_));

            [Fact]
            public static async Task BindAsync_SomeUri_Sync() =>
                await Assert.Async.Some(MyUri.AbsoluteUri,
                    MaybeEx.BindAsync(SomeUri, GetAbsoluteUriSync_));

            #endregion

            #region SelectAsync()

            [Fact]
            public static async Task SelectAsync_None_NullSelector()
            {
                await Assert.Async.ThrowsAnexn("selector", () => MaybeEx.SelectAsync(Ø, Funk<int, AnyResult>.NullAsync));
                await Assert.Async.ThrowsAnexn("selector", () => MaybeEx.SelectAsync(AnyT.None, Funk<AnyT, AnyResult>.NullAsync));
            }

            [Fact]
            public static async Task SelectAsync_Some_NullSelector()
            {
                await Assert.Async.ThrowsAnexn("selector", () => MaybeEx.SelectAsync(One, Funk<int, AnyResult>.NullAsync));
                await Assert.Async.ThrowsAnexn("selector", () => MaybeEx.SelectAsync(AnyT.Some, Funk<AnyT, AnyResult>.NullAsync));
            }

            [Fact]
            public static async Task SelectAsync_None()
            {
                await Assert.Async.None(MaybeEx.SelectAsync(Ø, Funk<int, AnyResult>.AnyAsync));
                await Assert.Async.None(MaybeEx.SelectAsync(NoText, Funk<string, AnyResult>.AnyAsync));
                await Assert.Async.None(MaybeEx.SelectAsync(NoUri, Funk<Uri, AnyResult>.AnyAsync));
                await Assert.Async.None(MaybeEx.SelectAsync(AnyT.None, Funk<AnyT, AnyResult>.AnyAsync));
            }

            [Fact]
            public static async Task SelectAsync_None_Sync()
            {
                await Assert.Async.None(MaybeEx.SelectAsync(Ø, Funk<int, AnyResult>.AnySync));
                await Assert.Async.None(MaybeEx.SelectAsync(NoText, Funk<string, AnyResult>.AnySync));
                await Assert.Async.None(MaybeEx.SelectAsync(NoUri, Funk<Uri, AnyResult>.AnySync));
                await Assert.Async.None(MaybeEx.SelectAsync(AnyT.None, Funk<AnyT, AnyResult>.AnySync));
            }

            [Fact]
            public static async Task SelectAsync_SomeInt32() =>
                await Assert.Async.Some(6, MaybeEx.SelectAsync(Two, Times3Async));

            [Fact]
            public static async Task SelectAsync_SomeInt32_Sync() =>
                await Assert.Async.Some(6, MaybeEx.SelectAsync(Two, Times3Sync));

            [Fact]
            public static async Task SelectAsync_SomeInt64() =>
                await Assert.Async.Some(8L, MaybeEx.SelectAsync(TwoL, Times4Async));

            [Fact]
            public static async Task SelectAsync_SomeInt64_Sync() =>
                await Assert.Async.Some(8L, MaybeEx.SelectAsync(TwoL, Times4Sync));

            [Fact]
            public static async Task SelectAsync_SomeUri() =>
                await Assert.Async.Some(MyUri.AbsoluteUri,
                    MaybeEx.SelectAsync(SomeUri, GetAbsoluteUriAsync));

            [Fact]
            public static async Task SelectAsync_SomeUri_Sync() =>
                await Assert.Async.Some(MyUri.AbsoluteUri,
                    MaybeEx.SelectAsync(SomeUri, GetAbsoluteUriSync));

            #endregion

            #region OrElseAsync()

            [Fact]
            public static async Task OrElseAsync_None_NullOther()
            {
                await Assert.Async.ThrowsAnexn("other", () => MaybeEx.OrElseAsync(Ø, null!));
                await Assert.Async.ThrowsAnexn("other", () => MaybeEx.OrElseAsync(AnyT.None, null!));
            }

            [Fact]
            public static async Task OrElseAsync_Some_NullOther()
            {
                await Assert.Async.ThrowsAnexn("other", () => MaybeEx.OrElseAsync(One, null!));
                await Assert.Async.ThrowsAnexn("other", () => MaybeEx.OrElseAsync(AnyT.Some, null!));
            }

            [Fact]
            public static async Task OrElseAsync_None()
            {
                await Assert.Async.Some(3, MaybeEx.OrElseAsync(Ø, ReturnAsync_(3)));
                await Assert.Async.Some("other", MaybeEx.OrElseAsync(NoText, ReturnAsync_("other")));

                var otherUri = new Uri("https://source.dot.net/");
                await Assert.Async.Some(otherUri, MaybeEx.OrElseAsync(NoUri, ReturnAsync_(otherUri)));

                var otherAnyT = AnyT.Value;
                await Assert.Async.Some(otherAnyT, MaybeEx.OrElseAsync(AnyT.None, ReturnAsync_(otherAnyT)));
            }

            [Fact]
            public static async Task OrElseAsync_None_Sync()
            {
                await Assert.Async.Some(3, MaybeEx.OrElseAsync(Ø, ReturnSync_(3)));
                await Assert.Async.Some("other", MaybeEx.OrElseAsync(NoText, ReturnSync_("other")));

                var otherUri = new Uri("https://source.dot.net/");
                await Assert.Async.Some(otherUri, MaybeEx.OrElseAsync(NoUri, ReturnSync_(otherUri)));

                var otherAnyT = AnyT.Value;
                await Assert.Async.Some(otherAnyT, MaybeEx.OrElseAsync(AnyT.None, ReturnSync_(otherAnyT)));
            }

            [Fact]
            public static async Task OrElseAsync_Some()
            {
                var anyT = AnyT.New();
                await Assert.Async.Some(anyT.Value, MaybeEx.OrElseAsync(anyT.Some, ReturnAsync_(AnyT.Value)));
            }

            [Fact]
            public static async Task OrElseAsync_Some_Sync()
            {
                var anyT = AnyT.New();
                await Assert.Async.Some(anyT.Value, MaybeEx.OrElseAsync(anyT.Some, ReturnSync_(AnyT.Value)));
            }

            [Fact]
            public static async Task OrElseAsync_SomeInt32() =>
                await Assert.Async.Some(1, MaybeEx.OrElseAsync(One, ReturnAsync_(3)));

            [Fact]
            public static async Task OrElseAsync_SomeInt32_Sync() =>
                await Assert.Async.Some(1, MaybeEx.OrElseAsync(One, ReturnSync_(3)));

            [Fact]
            public static async Task OrElseAsync_SomeText() =>
                await Assert.Async.Some(MyText, MaybeEx.OrElseAsync(SomeText, ReturnAsync_("other")));

            [Fact]
            public static async Task OrElseAsync_SomeText_Sync() =>
                await Assert.Async.Some(MyText, MaybeEx.OrElseAsync(SomeText, ReturnSync_("other")));

            [Fact]
            public static async Task OrElseAsync_SomeUri()
            {
                var otherUri = new Uri("https://source.dot.net/");
                await Assert.Async.Some(MyUri, MaybeEx.OrElseAsync(SomeUri, ReturnAsync_(otherUri)));
            }

            [Fact]
            public static async Task OrElseAsync_SomeUri_Sync()
            {
                var otherUri = new Uri("https://source.dot.net/");
                await Assert.Async.Some(MyUri, MaybeEx.OrElseAsync(SomeUri, ReturnSync_(otherUri)));
            }

            #endregion
        }
    }
}

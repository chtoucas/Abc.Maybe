// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Threading.Tasks;

    public partial class MaybeTests
    {
        private const string Anagram = "chicane";
        private const string Margana = "caniche";

        private static readonly Maybe<int> Ø = Maybe<int>.None;
        private static readonly Maybe<long> ØL = Maybe<long>.None;

        private static readonly Maybe<int> One = Maybe.Some(1);
        private static readonly Maybe<int> Two = Maybe.Some(2);
        private static readonly Maybe<long> TwoL = Maybe.Some(2L);

        private const string MyText = "text";
        private static readonly Maybe<string> NoText = Maybe<string>.None;
        private static readonly Maybe<string> SomeText = Maybe.SomeOrNone(MyText);

        private static readonly Uri MyUri = My_.Uri;
        private static readonly Maybe<Uri> NoUri = Maybe<Uri>.None;
        private static readonly Maybe<Uri> SomeUri = Maybe.SomeOrNone(My_.Uri);

        private static class My_
        {
            internal static readonly Uri Uri = new Uri("http://www.narvalo.org");
        }
    }

    public partial class MaybeTests
    {
        [Pure]
        public static Func<Task<Maybe<T>>> ReturnSync_<T>(T result) where T : notnull
            => () => Task.FromResult(Maybe.Of(result));

        [Pure]
        public static Func<Task<Maybe<T>>> ReturnAsync_<T>(T result) where T : notnull
            => async () => { await Task.Yield(); return Maybe.Of(result); };

        [Pure] private static T Ident<T>(T x) where T : notnull => x;

        [Pure] private static int Times3(int x) => 3 * x;
        [Pure] private static Task<int> Times3Sync(int x) => Task.FromResult(3 * x);
        [Pure] private static async Task<int> Times3Async(int x) { await Task.Yield(); return 3 * x; }

        [Pure] private static Maybe<int> Times3_(int x) => Maybe.Some(3 * x);
        [Pure] private static Task<Maybe<int>> Times3Sync_(int x) => Task.FromResult(Maybe.Some(3 * x));
        [Pure] private static async Task<Maybe<int>> Times3Async_(int x) { await Task.Yield(); return Maybe.Some(3 * x); }

        [Pure] private static long Times4(long x) => 4L * x;
        [Pure] private static Task<long> Times4Sync(long x) => Task.FromResult(4L * x);
        [Pure] private static async Task<long> Times4Async(long x) { await Task.Yield(); return 4L * x; }

        [Pure] private static Maybe<long> Times4_(long x) => Maybe.Some(4L * x);
        [Pure] private static Task<Maybe<long>> Times4Sync_(long x) => Task.FromResult(Maybe.Some(4L * x));
        [Pure] private static async Task<Maybe<long>> Times4Async_(long x) { await Task.Yield(); return Maybe.Some(4L * x); }

        [Pure] private static string GetAbsoluteUri(Uri x) => x.AbsoluteUri;
        [Pure] private static Task<string> GetAbsoluteUriSync(Uri x) => Task.FromResult(x.AbsoluteUri);
        [Pure] private static async Task<string> GetAbsoluteUriAsync(Uri x) { await Task.Yield(); return x.AbsoluteUri; }

        [Pure] private static Maybe<string> GetAbsoluteUri_(Uri x) => Maybe.SomeOrNone(x.AbsoluteUri);
        [Pure] private static Task<Maybe<string>> GetAbsoluteUriSync_(Uri x) => Task.FromResult(Maybe.SomeOrNone(x.AbsoluteUri));
        [Pure] private static async Task<Maybe<string>> GetAbsoluteUriAsync_(Uri x) { await Task.Yield(); return Maybe.SomeOrNone(x.AbsoluteUri); }

        [Pure] private static Maybe<AnyResult> ReturnNone<T>(T _) => AnyResult.None;
        [Pure] private static Task<Maybe<AnyResult>> ReturnNoneSync<T>(T _) => Task.FromResult(AnyResult.None);
        [Pure] private static async Task<Maybe<AnyResult>> ReturnNoneAsync<T>(T _) { await Task.Yield(); return AnyResult.None; }

        [Pure] private static Maybe<AnyResult> ReturnSome<T>(T _) => AnyResult.Some;
        [Pure] private static Task<Maybe<AnyResult>> ReturnSomeSync<T>(T _) => Task.FromResult(AnyResult.Some);
        [Pure] private static async Task<Maybe<AnyResult>> ReturnSomeAsync<T>(T _) { await Task.Yield(); return AnyResult.Some; }
    }

    public partial class MaybeTests
    {
        private struct MyItem
        {
            public int Id;
            public string Name;
        }

        private struct MyInfo
        {
            public int Id;
            public string Description;
        }

        private struct MyData
        {
            public int Id;
            public string Name;
            public string Description;
        }

        private struct MyDataGroup
        {
            public int Id;
            public string Name;
            public Maybe<MyInfo> Info;
        }
    }
}

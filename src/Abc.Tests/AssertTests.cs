// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Threading.Tasks;

    using Xunit;

    using Assert = AssertEx;

    public static class AssertTests
    {
        private static Task EagerValidation(string arg)
        {
            if (arg is null) { throw new ArgumentNullException(nameof(arg)); }

            return __();

            static async Task __() => await Task.Yield();
        }

        private static async Task AsyncValidation(string arg)
        {
            if (arg is null) { throw new ArgumentNullException(nameof(arg)); }

            await Task.Yield();
        }

        [Fact]
        public static void EagerValidationTest() =>
            Assert.ThrowsAnexn("arg", () => EagerValidation(null!));

        [Fact]
        public static async Task EagerValidationTestAsync() =>
            await Assert.ThrowsAsync<InvalidOperationException>(() =>
                Assert.Async.ThrowsAnexn("arg", () => EagerValidation(null!)));

        [Fact]
        public static void AsyncValidationTest_NotAwaited_DoesNotThrow() =>
#pragma warning disable CS4014 // Because this call is not awaited, execution of the current method continues before the call is completed
            AsyncValidation(null!);
#pragma warning restore CS4014

        [Fact]
        public static async Task AsyncValidationTest() =>
            await Assert.Async.ThrowsAnexn("arg", () => AsyncValidation(null!));
    }
}

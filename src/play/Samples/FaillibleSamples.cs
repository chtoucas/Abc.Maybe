// See LICENSE in the project root for license information.

#pragma warning disable CA1000 // Do not declare static members on generic types

namespace Abc.Samples
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Runtime.ExceptionServices;

    using Abc.Utilities;

    using Anexn = System.ArgumentNullException;

    public static partial class FaillibleSamples { }

    public partial class FaillibleSamples
    {
        public static int OkOrThrew1(bool pass)
        {
            Faillible<int> exn = GetOkOrThrew(pass);
            return exn.ValueOrRethrow();
        }

        public static string OkOrThrew2(bool pass)
        {
            Faillible<int> exn = GetOkOrThrew(pass);

            if (exn.Threw)
            {
                // Do something with the exception (eg logging),
                Exception ex = exn.InnerException;
                // then rethrow, or swallow it (if within an application) and
                // fail gracefully?
                return Rethrow<string>(ex);
            }
            else
            {
                return $"{exn.Value}";
            }
        }

        public static Faillible<int> GetOkOrThrew(bool pass)
        {
            try
            {
                return Faillible.Succeed(mayThrow(pass));
            }
            catch (DivideByZeroException ex)
            {
                return Faillible.Threw<int>(ex);
            }

            static int mayThrow(bool ok)
                => ok ? 1 : throw new DivideByZeroException();
        }
    }

    public partial class FaillibleSamples
    {
        public static void Rethrow(Exception ex)
        {
            Require.NotNull(ex, nameof(ex));
            ExceptionDispatchInfo.Capture(ex).Throw();
        }

        [Pure]
        public static TResult Rethrow<TResult>(Exception ex)
        {
            Require.NotNull(ex, nameof(ex));
            ExceptionDispatchInfo.Capture(ex).Throw();
            return default;
        }

#pragma warning disable CA1031 // Do not catch general exception types

        [Pure]
        [Obsolete("Do not use as it, catching general exception types is an antipattern.")]
        public static Faillible<Unit> TryWith(Action action)
        {
            if (action is null) { throw new Anexn(nameof(action)); }

            try
            {
                action();
                return Faillible.Unit;
            }
            catch (Exception ex)
            {
                return Faillible.Threw<Unit>(ex);
            }
        }

        [Pure]
        [Obsolete("Do not use as it, catching general exception types is an antipattern.")]
        public static Faillible<TResult> TryWith<TResult>(Func<TResult> func)
        {
            if (func is null) { throw new Anexn(nameof(func)); }

            try
            {
                return Faillible.Succeed(func());
            }
            catch (Exception ex)
            {
                return Faillible.Threw<TResult>(ex);
            }
        }

        [Pure]
        [Obsolete("Do not use as it, catching general exception types is an antipattern.")]
        public static Faillible<Unit> TryFinally(Action action, Action finallyAction)
        {
            if (action is null) { throw new Anexn(nameof(action)); }
            if (finallyAction is null) { throw new Anexn(nameof(finallyAction)); }

            try
            {
                action();
                return Faillible.Unit;
            }
            catch (Exception ex)
            {
                return Faillible.Threw<Unit>(ex);
            }
            finally
            {
                finallyAction();
            }
        }

        [Pure]
        [Obsolete("Do not use as it, catching general exception types is an antipattern.")]
        public static Faillible<TResult> TryFinally<TResult>(
            Func<TResult> func, Action finallyAction)
        {
            if (func is null) { throw new Anexn(nameof(func)); }
            if (finallyAction is null) { throw new Anexn(nameof(finallyAction)); }

            try
            {
                return Faillible.Succeed(func());
            }
            catch (Exception ex)
            {
                return Faillible.Threw<TResult>(ex);
            }
            finally
            {
                finallyAction();
            }
        }

#pragma warning restore CA1031
    }
}

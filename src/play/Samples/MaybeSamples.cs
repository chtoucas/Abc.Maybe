// See LICENSE in the project root for license information.

namespace Abc.Samples
{
    using System;

    public static class MaybeSamples
    {
        public static void PatternMatching1()
        {
            var some = Maybe.SomeOrNone("Bla bla bla");

            string msg = some.Switch(
                caseSome: x => $"I received: {x}",
                caseNone: "No message");

            Console.WriteLine(msg);
        }

        public static void PatternMatching2()
        {
            var some = Maybe.SomeOrNone("Bla bla bla");

            var iter = some.GetEnumerator();
            string msg = iter.MoveNext() ? $"I received: {iter.Current}" : "No message";

            Console.WriteLine(msg);
        }
    }
}

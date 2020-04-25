// See LICENSE in the project root for license information.

namespace Abc.Samples
{
    using System;

    public static class ForMaybe
    {
        public static class NRT
        {
            public static void Equality()
            {
                // Value type.
                Maybe<int> x1 = Maybe.Some(0);
                // Nullable value type.
                // NB: this is normally a job for SomeOrNone(), not for Of(),
                // but we want to demonstrate what kind of problem we may
                // encounter when we compare a mix of value types and nullable
                // value types.
                Maybe<int?> x2 = Maybe.Of((int?)0);

                // x1 and x2 truely have different types.
                // We can not write:
                //   bool xequ1 = x1 == x2;
                // instead, we must resort to the slow Equals(object)
                bool xequ2 = x1.Equals(x2);     // <-- boxing
                // Of course, the result is false. What we should really do is,
                // first get rid of the int?, then do the comparison.
                Maybe<int> x3 = x2.Squash();
                bool xequ3 = x1 == x3;

                Console.WriteLine($"xequ2 = {xequ2}."); // false
                Console.WriteLine($"xequ3 = {xequ3}."); // true

                // Reference type.
                Maybe<string> y1 = Maybe.SomeOrNone("bla");
                // Nullable reference type.
                Maybe<string?> y2 = Maybe.Of((string?)"bla");

                // y1 and y2 have exactly the same types, but we have to use
                // the damnit op, otherwise we get a warning...
                bool yequ1 = y1 == y2!;
                bool yequ2 = y1.Equals(y2!);    // <-- no boxing

                Console.WriteLine($"yequ1 = {yequ1}."); // true
                Console.WriteLine($"yequ2 = {yequ2}."); // true
            }
        }

        public static class PatternMatching
        {
            public static void UsingSwitch()
            {
                var some = Maybe.SomeOrNone("Bla bla bla");

                string msg = some.Switch(
                    caseSome: x => $"I received: {x}",
                    caseNone: "No message");

                Console.WriteLine(msg);
            }

            public static void UsingGetEnumerator()
            {
                var some = Maybe.SomeOrNone("Bla bla bla");

                var iter = some.GetEnumerator();
                string msg = iter.MoveNext() ? $"I received: {iter.Current}" : "No message";

                Console.WriteLine(msg);
            }
        }
    }
}

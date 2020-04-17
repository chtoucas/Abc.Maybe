// See LICENSE in the project root for license information.

namespace Abc
{
    using System;
    using System.Diagnostics.Contracts;
    using System.Xml.Linq;

    // Extensions methods for Maybe<T> where T is an XObject.
    public partial class MaybeEx
    {
        [Pure]
        public static Maybe<T> MapValue<T>(
            this Maybe<XElement> @this, Func<string, T> selector)
            => from x in @this select selector(x.Value);

        [Pure]
        public static Maybe<string> ValueOrNone(this Maybe<XElement> @this)
            => from x in @this select x.Value;

        [Pure]
        public static Maybe<T> MapValue<T>(
            this Maybe<XAttribute> @this, Func<string, T> selector)
            => from x in @this select selector(x.Value);

        [Pure]
        public static Maybe<string> ValueOrNone(this Maybe<XAttribute> @this)
            => from x in @this select x.Value;
    }
}

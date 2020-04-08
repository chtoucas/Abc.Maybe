// See LICENSE in the project root for license information.

namespace Abc
{
    using System;

    [Flags]
    public enum BooleanStyles
    {
        Literal = 1 << 0,

        ZeroOrOne = 1 << 1,

        EmptyOrWhiteSpaceIsFalse = 1 << 2,

        HtmlInput = 1 << 3,

        Default = Literal | ZeroOrOne,

        Any = Literal | ZeroOrOne | EmptyOrWhiteSpaceIsFalse | HtmlInput,
    }

    /// <summary>
    /// Provides extension methods for <see cref="BooleanStyles"/>.
    /// <para>This class cannot be inherited.</para>
    /// </summary>
    internal static class BooleanStylesX
    {
        public static bool Contains(this BooleanStyles @this, BooleanStyles styles)
            => (@this & styles) != 0;
    }
}

// See LICENSE in the project root for license information.

using System.Diagnostics.Contracts;

using Abc;

// AnyT is a plain reference type; no special property whatsoever.
internal sealed class AnyT
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyT"/> class.
    /// </summary>
    public static readonly Maybe<AnyT> None = Maybe<AnyT>.None;

    private AnyT() { }

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT"/> class.
    /// </summary>
    public static AnyT Value => new AnyT();

    /// <summary>
    /// Creates a new non-empty "maybe" for the <see cref="AnyT"/> class.
    /// </summary>
    public static Maybe<AnyT> Some => Maybe.SomeOrNone(new AnyT());

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT"/> class and its
    /// "maybe" companion.
    /// </summary>
    [Pure]
    public static (AnyT Value, Maybe<AnyT> Some) New()
    {
        var any = new AnyT();
        return (any, Maybe.SomeOrNone(any));
    }
}
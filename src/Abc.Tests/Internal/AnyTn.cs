// See LICENSE in the project root for license information.

using Abc;

// AnyTn is a plain reference type; no special property whatsoever.

internal sealed class AnyT1
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyT1"/> class.
    /// </summary>
    public static readonly Maybe<AnyT1> None = Maybe<AnyT1>.None;

    private AnyT1() { }

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT1"/> class.
    /// </summary>
    public static AnyT1 Value => new AnyT1();

    /// <summary>
    /// Creates a new non-empty "maybe" for the <see cref="AnyT1"/> class.
    /// </summary>
    public static Maybe<AnyT1> Some => Maybe.SomeOrNone(Value);
}

internal sealed class AnyT2
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyT2"/> class.
    /// </summary>
    public static readonly Maybe<AnyT2> None = Maybe<AnyT2>.None;

    private AnyT2() { }

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT2"/> class.
    /// </summary>
    public static AnyT2 Value => new AnyT2();

    /// <summary>
    /// Creates a new non-empty "maybe" for the <see cref="AnyT2"/> class.
    /// </summary>
    public static Maybe<AnyT2> Some => Maybe.SomeOrNone(Value);
}

internal sealed class AnyT3
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyT3"/> class.
    /// </summary>
    public static readonly Maybe<AnyT3> None = Maybe<AnyT3>.None;

    private AnyT3() { }

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT3"/> class.
    /// </summary>
    public static AnyT3 Value => new AnyT3();

    /// <summary>
    /// Creates a new non-empty "maybe" for the <see cref="AnyT3"/> class.
    /// </summary>
    public static Maybe<AnyT3> Some => Maybe.SomeOrNone(Value);
}

internal sealed class AnyT4
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyT4"/> class.
    /// </summary>
    public static readonly Maybe<AnyT4> None = Maybe<AnyT4>.None;

    private AnyT4() { }

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT4"/> class.
    /// </summary>
    public static AnyT4 Value => new AnyT4();

    /// <summary>
    /// Creates a new non-empty "maybe" for the <see cref="AnyT4"/> class.
    /// </summary>
    public static Maybe<AnyT4> Some => Maybe.SomeOrNone(Value);
}

internal sealed class AnyT5
{
    /// <summary>
    /// Represents the empty "maybe" for the <see cref="AnyT5"/> class.
    /// </summary>
    public static readonly Maybe<AnyT5> None = Maybe<AnyT5>.None;

    private AnyT5() { }

    /// <summary>
    /// Creates a new instance of the <see cref="AnyT5"/> class.
    /// </summary>
    public static AnyT5 Value => new AnyT5();

    /// <summary>
    /// Creates a new non-empty "maybe" for the <see cref="AnyT5"/> class.
    /// </summary>
    public static Maybe<AnyT5> Some => Maybe.SomeOrNone(Value);
}

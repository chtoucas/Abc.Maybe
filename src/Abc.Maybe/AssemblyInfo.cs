// See LICENSE in the project root for license information.

using System;
using System.Runtime.InteropServices;

[assembly: CLSCompliant(true)]
[assembly: ComVisible(false)]

#if INTERNALS_VISIBLE_TO

// Only Abc.Testing gets access to internals, the actual test project does NOT.
[assembly: System.Runtime.CompilerServices.InternalsVisibleTo("Abc.Testing" + Abc.AssemblyInfo.PublicKeySuffix)]

namespace Abc
{
    /// <summary>
    /// Provides constants used to write Assembly's attributes.
    /// </summary>
    internal static partial class AssemblyInfo
    {
        /// <summary>
        /// Gets the public key suffix suitable for use with
        /// <see cref="System.Runtime.CompilerServices.InternalsVisibleToAttribute"/>.
        /// </summary>
        public const string PublicKeySuffix =
#if SIGNED_ASSEMBLY
            ",PublicKey="
            + "002400000480000094000000060200000024000052534131000400000100010035be34bb95fa97"
            + "d1c07f9de86e623f31c779743228dea6babfcd0fb568e59e4c6db4035c05867f50666cc087221d"
            + "a11b7354bc2d3ccc082db2bf7625bfc646e7f8343724160cdccc321f27e7f3766ecd0b40901379"
            + "b0f12790fd90461b68b5f2e407e2321cd3959bafb35717460900beaa99730a348f00b80bc9e5be"
            + "ef26bfc9";
#else
            "";
#endif
    }
}

#endif

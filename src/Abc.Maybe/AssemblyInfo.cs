// See LICENSE in the project root for license information.

using System;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[assembly: CLSCompliant(true)]
[assembly: ComVisible(false)]

// Only Abc.Testing gets access to the internals, the test project Abc.Tests
// does NOT.
[assembly: InternalsVisibleTo("Abc.Testing")]

A word of caution
-----------------
The classes found here exist for the sole purpose of my own education.
API and documentation are **adapted** (copied) from the Haskell sources.
The port from Haskell is quite loose, the result is NOT meant for efficiency
and does NOT reflect best practice.

[The Haskell 98 Report](https://www.haskell.org/onlinereport/monad.html)

Overview
--------
- Functor
- Functor > Applicative
- Functor > Applicative > Alternative
- Functor > Applicative > Monad
- Functor > Applicative > Alternative + Monad > MonadPlus

Compiler switches
-----------------
- `STRICT_HASKELL`.
  Follow as closely as possible the Haskell code.
- `MONADS_VIA_MAP_MULTIPLY`.
  The default behaviour is to define monads via Bind.
- `COMONADS_VIA_MAP_COMULTIPLY`.
  The default behaviour is to define comonads via cobind.

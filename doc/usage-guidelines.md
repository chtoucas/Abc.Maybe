Usage Guidelines (WIP)
================

Your mantra should be "**_maybe do not abuse the maybe_**".

First and foremost,
- **DO apply all guidelines for `ValueTuple<>` and, if they contradict what I
  say here, follow your own wisdom.**

The `Maybe<T>` type is a _value type_. Even if it is a natural choice, it worried
me and I hesitated for a while. The addition of value tuples to .NET convinced
me that the benefits will outweight the drawbacks.
- **CONSIDER using this type when `T` is a value type or an _immutable_ reference
  type.**
- **AVOID using this type when `T` is a _mutable_ reference type.**
- **DO NOT use a _maybe_ with nullable types, eg `Maybe<int?>`.**

The intended usage is when `T` is a value type, a string, a (read-only?) record,
or a function. For other reference types, it should be fine as long as T is an
_immutable_ reference type.

One can _indirectly_ create a maybe for a nullable (value or reference) type
— maybe I managed to entirely avoid this, but I am not sure —, but all
static factory methods do not permit it. If you end up having to manipulate for
say a `Maybe<int?>`, there is a method `Squash()` to convert it to a `Maybe<int>`.

(TODO: _do not use a maybe when we just have a single nullable value type, and
a if/then is all you need_)

API design
----------

- **DO NOT use `Maybe<T>` as a parameter in public APIs.**

When tempted to do so, we should think harder, most certainly there is a better
design. It is also dubious to see a method returning a _maybe_ when the method
has no reason to fail. On a side note, do not replace exceptions with _maybe_'s
when the error is actually "exceptional".

(TODO: _input not OK -> NRT, output OK_)

In general, I would not even recommend to expose `Maybe<T>` in a general purpose
library. For instance, returning a _maybe_ raises the concern that unexperienced
users may be tempted to progagate the _maybe_ to a higher level even if they can
handle the failure, which would cause unnecessary complications and further
usability problems.

Of course, this does not mean that you should not use this type at all,
otherwise I would not have written this library. _Maybe_'s should be
**ephemeral** and mostly confined inside a method.

Regarding performance
---------------------

- **AVOID using a _maybe_ if the object is expected to be long-lived.** (TODO: _why not?_)
- **AVOID using a _maybe_ in hot code paths.**

(TODO: _be less categorical, struct could imply a ton of copying, what about LINQ
(seq of _maybe_'s)?_)

About the May-Parse pattern
---------------------------

- **DO use the May-Parse pattern instead of the Try-Parse pattern for reference
  types.**
- **DO use the prefix _May_ for methods implementing this pattern.**

For reference types, a _maybe_ offers a better paradigm than a `null` to express
the inability to return a meaningful result.


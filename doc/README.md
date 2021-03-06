Documentation (WIP)
=============

- [Quick start](#quick-start)
  * [Construction](#construct-a-maybe)
  * [Deconstruction](#deconstruct-a-maybe)
  * [Empty or not?](#check-whether-a-maybe-is-empty-or-not)
  * [Map and filter](#map-and-filter-the-enclosed-value-if-any)
  * [Safe extraction](#safely-extract-the-enclosed-value)
  * [Pattern matching](#pattern-matching-extract-and-map-the-enclosed-value-if-any)
  * [Side effects](#side-effects-do-something-with-the-enclosed-value-if-any)
- [Going further](#going-further)
  * [Iterator](#iterator)
  * [Binding](#binding)
  * [Query Expression Pattern](#query-expression-pattern)
  * [Specialized types](#specialized-types)
  * [Advanced usage](#advanced-usage)
  * [More](#more)
  * [Samples](#samples)

An Option type, aka a Maybe type (a better fit for what we use it for), is like
a box containing a value or no value at all.

(TODO: _improve what follows_)

It can help preventing null reference exceptions, but that's not the point, it
really forces us to think about the outcome of a computation. What it is not is
a general replacement for null references. Code quality should also improve since
an algorithm with _maybe_'s is often shorter and closer to the intent, and
therefore simpler to follow and maintain, than the counterpart written without.

An Option type is a very simple sum type `Maybe<T> = Some<T> | None` (exclusive
or, but of course this is not possible in C#), whereas a "nullable" type,
like `string`, is just a string type to which the language adds a special
(sentinel) value, the `null` value. What's the difference? You can't ignore the
fact that an option is either something or nothing, you are forced to handle
both cases.

`Maybe<T>` also differs from a nullable in that it applies to both value types
and reference types; NRTs (Nullable Reference Types) do not count since they are
not actual .NET types but annotations that the compiler can take advantage of.
There are many other small differences. For instance, one can nest _maybe_'s
(`Maybe<Maybe<T>>`) whereas one can't create an `int??`; `Nullable<Nullable<T>>`
is not valid in C#.

Quick Start
-----------

```csharp
using Abc;
```

#### Use case scenarios

(TODO: _untaint data, validate, transform, filter, correctness,
SQL `null`, may-parse pattern, command-line args, HTTP query params_)

### Construct a _maybe_

```csharp
// Maybe of a value type.
Maybe<int> q = Maybe.Some(1);
Maybe<int> q = Maybe.None<int>();                   // The empty maybe of type int.

// Maybe of a nullable value type.
Maybe<int> q = Maybe.SomeOrNone((int?)1);
Maybe<int> q = Maybe.SomeOrNone((int?)null);        // The empty maybe of type int.

// Maybe of a reference type.
Maybe<string> q = Maybe.SomeOrNone("value");
Maybe<string> q = Maybe.SomeOrNone((string?)null);  // The empty maybe of type string.
```
If NRTs are available, `Maybe.SomeOrNone()` with a nullable string does not
create a `Maybe<string?>` but it (correctly) returns a `Maybe<string>`. When
working with unconstrained generic type, you cannot use `Maybe.Some[OrNone]()`
or `Maybe.None<T>()`. Hopefully, `Maybe.Of()` and `Maybe<T>.None` come to the
rescue, they were specifically created to handle this kind of situation;
otherwise there is no reason to use `Maybe.Of()` — with `Maybe<T>.None` it is
more a matter of taste.

In practice (to be completed)
```csharp
// A condition and a value type.
Maybe<int> maybe = condition ? Maybe.Some(1) : Maybe.None<int>();
```

### Deconstruct a _maybe_

No actual built-in C# deconstruction, but something quite similar, even though
this is not really something that you should do (except if you are trying to
extend the capabilities of `Maybe<T>`).
```csharp
// Value type, eg Maybe<int>.
bool isSome = maybe.TryGetValue(out int value);

// Reference type, eg Maybe<string>. Beware, "value" may be null.
bool isSome = maybe.TryGetValue(out string? value);
```
Although the actual signature is `(out string value)`, it's good practice to
add the question mark in order to emphasize the nullability of "value"; C#
allows us to do that with NRTs (remember they are not actual .NET types).

For the right pattern see [below](#safely-extract-the-enclosed-value).

### Check whether a _maybe_ is empty or not

```csharp
var some = Maybe.SomeOrNone("value");
var none = Maybe.None<string>()

bool isNone = some.IsNone             // == false
bool isNone = none.IsNone             // == true

// We can also check whether it contains a specific value or not.
bool b = some.Contains("value")       // == true
bool b = some.Contains("other")       // == false

// Of course, Contains() always returns false if the maybe is empty.
bool b = none.Contains("value")       // == false
bool b = none.Contains("other")       // == false
```

### Map and filter the enclosed value

```csharp
var some = Maybe.Some(4);

// NB: next line is better written with Select(Math.Sqrt).
Maybe<int> q = some.Where(x >= 0).Select(x => Math.Sqrt(x));    // == Maybe(2)

// Or using the query expression syntax.
Maybe<int> q = from x in some where x >= 0 select Math.Sqrt(x); // == Maybe(2)
```
If, instead, we start with an empty _maybe_ or `Maybe.Some(-4)`, the result is
an empty _maybe_, in both cases.

### Safely extract the enclosed value

`Maybe<T>` is a strict Option type, we don't get direct access to the enclosed
value.
```csharp
Maybe<string> maybe = Maybe.SomeOrNone("...");

// First the truely unsafe way of doing things, not recommended but at least
// it is clear from the method's name that the result might be null.
// WARNING: value may be null here! See also the remark we made while explaining
// TryGetValue().
string? value = maybe.ValueOrDefault();

// When the maybe is empty returns the specified replacement value.
string value = maybe.ValueOrElse("other");
// We may delay the creation of the replacement value. Here the example is a bit
// contrive, we should imagine a situation where the creation of the replacement
// value is an expensive operation, for instance when retrieved from a remote
// source.
string value = maybe.ValueOrElse(() => "other");

// If maybe is empty, throw InvalidOperationException.
string value = maybe.ValueOrThrow();
// Throw a custom exception.
string value = maybe.ValueOrThrow(new NotSupportedException("..."));
```
A word of **caution**, the methods may only be considered safe when targetting
.NET Core 3.0 or above, that is your project file should include something like
this:
```xml
<TargetFrameworks>netcoreapp3.0;netstandard2.0</TargetFrameworks>
<Nullable>enable</Nullable>
```
C# 8.0 will then complain if one tries to write `maybe.ValueOrElse(null)`.

### Pattern matching: extract and map the enclosed value

```csharp
Maybe<double> q = from x in maybe where x >= 0 select Math.Sqrt(x);

string message = q.Switch(
    caseSome: x  => $"Square root = {x}."),
    caseNone: () => "The input was strictly negative.");

// But, since caseNone is constant, it is better written:
string message = q.Switch(
    caseSome: x => $"Square root = {x}."),
    caseNone: "The input was strictly negative.");
```

### Side effects: do something with the enclosed value

```csharp
Maybe<double> q = from x in maybe where x >= 0 select Math.Sqrt(x);

q.Do(
    onSome: x  => Console.WriteLine($"Square root = {x}."),
    onNone: () => Console.WriteLine("The input was strictly negative."));

q.OnSome(x => Console.WriteLine($"Square root = {x}.");

if (q.IsNone) { Console.WriteLine("The input was strictly negative."); }
```

Going further
-------------

### Iterator

We provide three ways to convert a _maybe_ to an enumerable,
```csharp
var q = maybe.ToEnumerable();
var q = maybe.Yield(count);
var q = maybe.Yield();
```

```csharp
// Finite loop ("count" iterations) or no loop at all.
foreach (var x in maybe.Yield(count)) {
    // Do something with x (if any).
}

// Infinite loop or no loop at all.
foreach (var x in maybe.Yield()) {
    // Do something with x (if any).
}
```

#### Supporting `foreach`.

`GetEnumerator()` creates an iterator which is resettable and does not need to
be disposed (`using` is not necessary).

(TODO: _perf when compared to `Switch` & `Do`_)

```csharp
// One iteration or no iteration at all.
foreach (var x in maybe) {
    // Do something with x (if any).
}
```

Pattern matching using an iterator.
```csharp
// Instead of
var m = maybe.Switch(caseSome, caseNone);

// We can write
var iter = maybe.GetEnumerator();
var m = iter.MoveNext() ? caseSome(iter.Current) : caseNone();
```

Side effects using an iterator.
```csharp
// Instead of
maybe.Do(onSome, onNone);

// We can write
var iter = maybe.GetEnumerator();
if (iter.MoveNext()) { onSome(iter.Current); } else { onNone(); }
```

### Binding

`Bind()` and `Select()` look very similar, but `Bind()` is for situations where
the "selector" maps a value to a _maybe_ not to another value; the selector is
then said to be a binder.
Let's say that we wish to map a _maybe_ using the method `May.ParseInt32` which
parses a string and returns a `Maybe<int>`, it's not a mapping operation but
rather a binding operation.
```csharp
Maybe<string> maybe = Maybe.Some("12345");

// DO write.
var q = maybe.Bind(May.ParseInt32);     // <-- Maybe<int>

// DO NOT write.
var q = maybe.Select(May.ParseInt32)    // <-- Maybe<Maybe<int>>
    // To get back a Maybe<int>, we MUST then flatten the "double" maybe.
    .Flatten();                         // <-- Maybe<int>
```

### Query Expression Pattern

We already saw `Select` and `Where`, but there is more.
```csharp
// Cross join.
var q = from i in maybe1
        from j in maybe2
        select i + j;
// But it is better written without a (hidden) lambda function.
var q = maybe1.ZipWith(maybe2, (i, j) => i + j);

//
var q = from i in maybe
        from j in Maybe.Some(2 * i)
        select i + j;
```

Binding can be written using the query syntax...
```csharp
var q = from x in maybe
        from y in binder(x)
        select y;
```

### Specialized types

#### `Maybe<bool>` and 3VL

### Advanced usage

#### Extensibility

#### Nullable generic type parameter

#### Equality rules

#### Ordering rules

### More

The public API is not the same for all targets. We currently define two profiles,
one is for the
[platforms implementing .NET Standard 2.1](https://dotnet.microsoft.com/platform/dotnet-standard#versions),
and the other is for those preceding it.

See the XML comments for samples.
- LINQ and collection extensions in `Abc.Linq` and `Abc.Extensions`.
- Parsing helpers provided by the static class `May`.
- XML & SQL data type helpers in `Abc.Extensions`.

#### Custom builds

`PATCH_EQUALITY`

### Samples

#### Processing multiple nullable objects together
`MayGetSingle()` is an extension that returns something only if the key exists and
there is a unique value associated to it.
```csharp
NameValueCollection nvc;

var q = from a in nvc.MayGetSingle("a")
        from b in nvc.MayGetSingle("b")
        from c in nvc.MayGetSingle("c").Bind(May.ParseInt32)
        let x = nvc.MayGetSingle("x")
        where c > 10
        select new {
            A = a,
            B = b,
            X = x.ValueOrElse("Y")
        }
```
In the above query, the result is empty when one of the keys `a`, `b` or `c`
does not exist or is multi-valued, or the single value of `c` is not the string
representation of an integer > 10. Morevover, the result is NOT empty even if
the key `x` does not exist or is multi-valued, in which case we pick a default
value.


# IsPurelyImmutable.jl

[![Build Status](https://travis-ci.com/RelationalAI-oss/IsPurelyImmutable.jl.svg?branch=master)](https://travis-ci.com/RelationalAI-oss/IsPurelyImmutable.jl)

This package simply provides a small trait function, `is_purely_immutable(x)`, which checks
if a value is deeply, purely (i.e. recursively), logically immutable.

A purely immutable value can never change, and thus is safe to use in purely functional
datastructures.

This is needed as a separate concept from `Base.isimmutable()`, since that refers only to
whether a value is an instance of an immutable struct in julia, but this is neither
necessary nor sufficient to determine whether a value can logically change from its current
value.

As shown here, one shouldnt use `isimmutable` to detect whether a value can change:
```julia
julia> struct S x end

julia> s = S([]); s1 = deepcopy(s)
S(Any[])

julia> isimmutable(s1), s1.x == s.x
(true, true)

julia> push!(s.x, 10)
1-element Array{Any,1}:
 10

julia> s1.x == s.x
false
```
Instead, you can use `is_purely_immutable` to accurately check whether a value can ever change:
```julia
julia> struct S x end

julia> is_purely_immutable(S([]))  # false, since S.x can be mutated (as above)
false

julia> is_purely_immutable(S(1))  # true, since S(1) is recursively immutable
true
```
There are also some values implemented as `mutable struct`s, but which can never be modified,
such as Strings (for more: https://github.com/JuliaLang/julia/issues/30210), and
`is_purely_immutable` handles them correctly:
```julia
julia> is_purely_immutable("strings are logically immutable")
true
```

## Extending for custom types

If you have a type whose values aren't handled correctly by the default implementations
(e.g. an immutable struct that is actually somehow mutable (such as FixedSizeArrays), or a
mutable struct whose accessors are all disabled), you should extend this function with a
method for your type. For example:
```julia
IsPurelyImmutable.is_purely_immutable(::MyType) = true
```

## Docstring

    is_purely_immutable(val) :: Bool

A trait function that returns true if a value is purely immutable, meaning its value can
never change in any way from the value it currently holds, and thus is safe to use in purely
functional datastructures. This requires a value to be immutable itself, and _recursively_
purely immutable for all of its fields.

Users should override this function to set the trait for their own types.

NOTE: All methods of this function must be "pure functions", meaning they cannot depend on
any outside state, and must always return the same result for a given value.

The default method returns true if:
- The value is an unmodifiable literal (Int, String, etc), or
- The value's type is a julia `immutable` type, that recursively only contains other
`immutable` types, or
- The value is an empty mutable type (has no fields).

Note that (like
[`Base.isimmutable`](https://docs.julialang.org/en/v1/base/base/#Base.isimmutable))
this function works on _values_, not types. This
may be counter-intuitive, but immutability is indeed a per-instance property: e.g. an
immutable type with an abstract field may be constructed with a mutable or immutable value;
or a user defined type may be able to "freze" and become immutable at runtime (e.g.
Mutable-Until-Shared types); and finally because (like `isimmutable`) it is only meaningful
for concrete types. See the Julia Docs section on [Mutable Composite
Types](https://docs.julialang.org/en/v1/manual/types/#Mutable-Composite-Types-1) for more on
the meaning of `immutable` in Julia.

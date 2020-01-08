module IsPurelyImmutable

export ispure

# TODO:
# - Currently ispure returns true for functions (b/c functions are isimmutable). Is this
#   desirable? Functions are _logically_ mutable in julia, b/c you can add/remove methods.

"""
    ispure(val)

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

Note that (like [`Base.isimmutable`](@ref)) this function works on _values_, not types. This
may be counter-intuitive, but immutability is indeed a per-instance property: e.g. an
immutable type with an abstract field may be constructed with a mutable or immutable value;
or a user defined type may be able to "freze" and become immutable at runtime (e.g.
Mutable-Until-Shared types); and finally because (like `isimmutable`) it is only meaningful
for concrete types. See the Julia Docs section on [Mutable Composite
Types](https://docs.julialang.org/en/v1/manual/types/#Mutable-Composite-Types-1) for more on
the meaning of `immutable` in Julia.
"""
function ispure end

# Default implementation that checks for recursively immutable types
function ispure(@nospecialize(x))
    Base.@_pure_meta  # Allow the compiler to elide this function where possible.
    (isimmutable(x) && all(ispure(getfield(x, f)) for f in fieldnames(typeof(x)))
        || #= is mutable && =# fieldcount(typeof(x)) == 0)
end

# Extension for purely immutable data types that aren't julia `immutable`
ispure(x::Union{String, Symbol}) = true

# Explicitly mark false because because Arrays are _mutable structs w/ no fields_, but
# they have _secret_ fields implemented in C.
ispure(x::Array) = false


end # module

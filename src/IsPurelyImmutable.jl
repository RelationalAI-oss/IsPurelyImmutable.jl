module IsPurelyImmutable

export is_purely_immutable

# TODO:
# - Currently is_purely_immutable returns true for functions (b/c functions are isimmutable). Is this
#   desirable? Functions are _logically_ mutable in julia, b/c you can add/remove methods.

"""
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

Note that (like [`Base.isimmutable`](@ref)) this function works on _values_, not types. This
may be counter-intuitive, but immutability is indeed a per-instance property: e.g. an
immutable type with an abstract field may be constructed with a mutable or immutable value;
or a user defined type may be able to "freze" and become immutable at runtime (e.g.
Mutable-Until-Shared types); and finally because (like `isimmutable`) it is only meaningful
for concrete types. See the Julia Docs section on [Mutable Composite
Types](https://docs.julialang.org/en/v1/manual/types/#Mutable-Composite-Types-1) for more on
the meaning of `immutable` in Julia.
"""
function is_purely_immutable end

# Default implementation that checks for recursively immutable types
function is_purely_immutable(@nospecialize(x))
    isbitstype(typeof(x)) ||
        # If not isbitstype, fall back to the generated function (non-isbits structs)
        _nonisbits_is_purely_immutable(x)
end

# Generated function for non-isbits structs to generate a recursive call over all fields.
@inline @generated function _nonisbits_is_purely_immutable(x)
    :(if isimmutable(x)
        # Recursive call to is_purely_immutable for each field of x.
        $([
            # Check `=== true` to prevent three-valued logic (optimization)
            :(is_purely_immutable(getfield(x, $(QuoteNode(f)))) === true || return false)
            for f in fieldnames(x)
           ]...)
       return true
    else #= is mutable =#
        $(fieldcount(x) === 0)
    end)
end

# Extension for purely immutable data types that aren't julia `immutable`
is_purely_immutable(::Union{String, Symbol}) = true

# Explicitly mark false because because Arrays are _mutable structs w/ no fields_, but
# they have _secret_ fields implemented in C.
is_purely_immutable(::Array) = false

# Add overloads for Types, because you can't take `fieldcount()` of these types
# TODO: Is this right? Are DataTypes not purely immutable? Can they change?
# ... Maybe it's because they can change slightly if the user like adds a constructor or something?
is_purely_immutable(::DataType) = false
is_purely_immutable(::UnionAll) = false

end # module

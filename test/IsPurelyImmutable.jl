using IsPurelyImmutable
using Test

@testset "is_purely_immutable literals" begin
    @test is_purely_immutable(1)
    @test is_purely_immutable(true)
    @test is_purely_immutable(nothing)

    @test is_purely_immutable((2,3))

    @test is_purely_immutable(1:2:10)


    # Test custom extension for strings & symbols
    @test is_purely_immutable("hi")
    @test is_purely_immutable(:hey)

    @test is_purely_immutable((:hi,"hey"))
    @test is_purely_immutable((a=:hi, b="hey"))

    # Things that aren't pure (because they're mutable)
    @test !is_purely_immutable([])
    @test !is_purely_immutable(Int[1,2,3])
    @test !is_purely_immutable(Dict(1=>2))
    @test !is_purely_immutable(:(2+3))
end

struct EmptyImmutable end
mutable struct EmptyMutable end
struct ImmutableStructMutableFields
    x::Vector
end
mutable struct MutableStructMutableFields
    x::Vector
end
struct RecursivelyImmutable
    x::Union{RecursivelyImmutable,Nothing}
    RecursivelyImmutable(x = nothing) = new(x)
end
struct ImmutableStructAbstractField
    x  # Might be mutable, might be immutable
end
@testset "is_purely_immutable() with custom types" begin
    @test is_purely_immutable(EmptyImmutable())
    @test is_purely_immutable(EmptyMutable())
    @test !is_purely_immutable(ImmutableStructMutableFields([]))
    @test !is_purely_immutable(MutableStructMutableFields([]))
    @test is_purely_immutable(RecursivelyImmutable())
    @test is_purely_immutable(RecursivelyImmutable(RecursivelyImmutable()))

    # Purity of immutable types with Abstract Fields deepends on their value.
    @test is_purely_immutable(ImmutableStructAbstractField(1))
    @test is_purely_immutable(ImmutableStructAbstractField("hi"))
    @test !is_purely_immutable(ImmutableStructAbstractField([]))
end

# Overriding is_purely_immutable of custom type: Mutable Until Shared example
mutable struct MutableStructUntilShared
    v::Int
    mutable::Bool
    MutableStructUntilShared(x, mut=true) = new(x, mut)
end

function Base.setproperty!(m::MutableStructUntilShared, f::Symbol, v)
    if !m.mutable
        error("setproperty! Cannot modify MutableStructUntilShard `m` once it's been" *
              " marked immutable")
    else
        setfield!(m,f,v)
    end
end

IsPurelyImmutable.is_purely_immutable(x::MutableStructUntilShared) = !x.mutable

@testset "is_purely_immutable() for Mutable Until Shared struct" begin
    @test !is_purely_immutable(MutableStructUntilShared(1))
    @test is_purely_immutable(MutableStructUntilShared(1, false))

    x = MutableStructUntilShared(0)
    @test !is_purely_immutable(x)
    x.v = 1

    x.mutable = false  # Mark immutable
    @test_throws ErrorException x.v = 2
    @test is_purely_immutable(x)
end

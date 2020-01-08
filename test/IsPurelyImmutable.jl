using IsPurelyImmutable
using Test

@testset "ispure literals" begin
    @test ispure(1)
    @test ispure(true)
    @test ispure(nothing)

    @test ispure((2,3))

    @test ispure(1:2:10)


    # Test custom extension for strings & symbols
    @test ispure("hi")
    @test ispure(:hey)

    @test ispure((:hi,"hey"))
    @test ispure((a=:hi, b="hey"))

    # Things that aren't pure (because they're mutable)
    @test !ispure([])
    @test !ispure(Int[1,2,3])
    @test !ispure(Dict(1=>2))
    @test !ispure(:(2+3))
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
@testset "ispure() with custom types" begin
    @test ispure(EmptyImmutable())
    @test ispure(EmptyMutable())
    @test !ispure(ImmutableStructMutableFields([]))
    @test !ispure(MutableStructMutableFields([]))
    @test ispure(RecursivelyImmutable())
    @test ispure(RecursivelyImmutable(RecursivelyImmutable()))

    # Purity of immutable types with Abstract Fields deepends on their value.
    @test ispure(ImmutableStructAbstractField(1))
    @test ispure(ImmutableStructAbstractField("hi"))
    @test !ispure(ImmutableStructAbstractField([]))
end

# Overriding ispure of custom type: Mutable Until Shared example
mutable struct MutableStructUntilShared
    v::Int
    mutable::Bool
    MutableStructUntilShared(x, mut=true) = new(x, mut)
end

function Base.setproperty!(m::MutableStructUntilShared, f::Symbol, v)
    if !m.mutable
        error("setproperty! Cannot modify MutableStructUntilShard `m` once it's been marked immutable")
    else
        setfield!(m,f,v)
    end
end

IsPurelyImmutable.ispure(x::MutableStructUntilShared) = !x.mutable

@testset "ispure() for Mutable Until Shared struct" begin
    @test !ispure(MutableStructUntilShared(1))
    @test ispure(MutableStructUntilShared(1, false))

    x = MutableStructUntilShared(0)
    @test !ispure(x)
    x.v = 1

    x.mutable = false  # Mark immutable
    @test_throws ErrorException x.v = 2
    @test ispure(x)
end

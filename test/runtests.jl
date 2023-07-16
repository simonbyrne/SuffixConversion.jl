using SuffixConversion
using Test

@testset "defined" begin
    function addhalf(x::FT) where {FT}
        @suffix FT
        return x + 0.5_FT
    end

    @test addhalf(1.0) === 1.5
    @test addhalf(1f0) === 1.5f0
    @test addhalf(Float16(1)) === Float16(1.5)
end

@testset "inline definition" begin
    function addhalf2(x)
        @suffix FT = typeof(x)
        return x + 0.5_FT
    end

    @test addhalf2(1.0) === 1.5
    @test addhalf2(1f0) === 1.5f0
    @test addhalf2(Float16(1)) === Float16(1.5)
end

@testset "BigFloat" begin
    function addpointtwo(x::FT) where {FT}
        @suffix FT
        return x + 0.2_FT
    end

    @test addpointtwo(1.0) === 1.2
    @test addpointtwo(big"1.0") == big"1.2"
end

@testset "broadcasting" begin
    function addhalf_broadcast(X)        
        @suffix FT = eltype(X)
        return @. X + 0.5_FT
    end

    @test eltype(addhalf_broadcast(Float64[1.0, 2.0])) == Float64
    @test eltype(addhalf_broadcast(Float32[1.0, 2.0])) == Float32
    @test eltype(addhalf_broadcast(Float16[1.0, 2.0])) == Float16
end


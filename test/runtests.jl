
using PikaParser
using Test

const P = PikaParser

@testset "PikaParser tests" begin
    include("readme.jl")
    include("clauses.jl")
    include("precedence.jl")
    include("fastmatch.jl")
end

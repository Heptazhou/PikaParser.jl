
import PikaParser as P
using OrderedCollections: OrderedDict
using Test

@testset "PikaParser tests" begin
    include("readme.jl")
    include("clauses.jl")
    include("precedence.jl")
    include("fastmatch.jl")
end

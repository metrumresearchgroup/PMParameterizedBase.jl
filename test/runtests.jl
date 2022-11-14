using PMxSim
using Test
include("testfunctions.jl")
@testset "Check model basics" begin
    @test mdl_basic.parameters == ComponentArray{Float64}(p=2.0)
    @test mdl_basic.model(0,0,ComponentArray(p=-3.0,c=-23),0) == -3.0
end
@testset "Check parameter updates" begin
    p2 = ComponentArray(p = -99.0)
    mdl2 = params(mdl_basic, p2)
    params(mdl_basic, p2); 
    @test mdl2.parameters == ComponentArray{Float64}(p=-99.0)
    @test mdl_basic.parameters == ComponentArray{Float64}(p=2.0)
    params!(mdl_basic, p2);
    @test  mdl_basic.parameters == ComponentArray{Float64}(p=-99.0)
end

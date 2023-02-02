using PMxSim
using Test
using OrdinaryDiffEq: ODEProblem, isinplace
using ComponentArrays
@testset "Check model basics" begin
    include("testfunctions.jl")
    @test mdl_basic.parameters == ComponentArray{Float64}(p=2.0)
    @test mdl_basic.model.f(0,ComponentArray(x = 9.0),ComponentArray(p=-3.0,c=-23),0) == -3.0
    @test mdl_differentorder.parameters == ComponentArray(p = 2.0, z = 3.0, i = 1.0, j = 2.0, k = 3.0, w = 2.0)
    @test mdl_differentorder.states == ComponentArray(x = 9.0, a = 1.0, b = 2.0, c = 3.0, u = -9.0)
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

include("test_dups.jl")

@testset "Check for inplace and OOP derivatives" begin
    include("testfunctions.jl")
    iip_problem = ODEProblem(mdl_basic.model.f, nothing, nothing)
    oop_problem = ODEProblem(mdl_outofplace.model.f, nothing, nothing)
    @test isinplace(iip_problem) == true
    @test mdl_basic.parameters == ComponentVector(p = 2.0)
    @test mdl_basic.states == ComponentVector(x = 9.0)
    @test isinplace(oop_problem) == false
    @test mdl_outofplace.parameters == ComponentVector(p = 2.0)
    @test mdl_outofplace.states == ComponentVector(x = 9.0)
end

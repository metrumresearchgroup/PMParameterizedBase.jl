using PMxSim
using Test
using OrdinaryDiffEq: ODEProblem, isinplace
using ComponentArrays
@testset "Check model basics" begin
    include("testfunctions.jl")
    @test mdl_basic.parameters == ComponentArray{Float64}(p=2.0)
    @test mdl_basic.model.f(ComponentArray(x=0),ComponentArray(x = 9.0),ComponentArray(p=-3.0,c=-23),0) == 0.0
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
    iip_problem = ODEProblem(mdl_basic.model.f, nothing, nothing,input=nothing)
    oop_problem = ODEProblem(mdl_outofplace.model.f, nothing, nothing,input=nothing)
    @test isinplace(iip_problem) == true
    @test mdl_basic.parameters == ComponentVector(p = 2.0)
    @test mdl_basic.states == ComponentVector(x = 9.0)
    @test isinplace(oop_problem) == false
    @test mdl_outofplace.parameters == ComponentVector(p = 2.0)
    @test mdl_outofplace.states == ComponentVector(x = 9.0)
    @test mdl_basic.model.inplace == true
    @test mdl_outofplace.model.inplace == false
    @test mdl_kws_iip.model.inplace == true
    @test mdl_kws_oop.model.inplace ==false
    @test_throws ErrorException("Unrecognized model function protoype: test(du, u, p, t, q; k = 2, foo = -99) Please separate kwargs with a ';'") test_iip_oop()
end

## Derivative Tests
@testset "Check for derivative and state definitions" begin
    include("derivative_tests.jl")
    @test_throws ErrorException("No derivative provided for states(s) R2") deriv_test1()
    @test_throws ErrorException("No derivative provided for states(s) R3") deriv_test2()
end
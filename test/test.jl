using Revise
using ParameterizedModels

bar = @model TestMTK begin
    @IVs t
    @parameters σ=10.0 ρ=28.0 β=8.0/3.0 IC = 1.0
    @variables x(t)=IC y(t)=0.0 z(t)=0.0
    @D(t, x~σ*(y-x))
    @D(t, y~x*(ρ-z)-y)
    @D(t, z~x*y - β*z)
end;

using DifferentialEquations
prob = ODEProblem(bar.model, [], (0.0, 1000.0))
sol = solve(prob);
plot(sol.t,sol[:x])
 
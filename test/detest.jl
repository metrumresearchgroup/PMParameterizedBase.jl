using DifferentialEquations
using BenchmarkTools


mutable struct Lorenz
k
f
# Lorenz6(k, f) = new(k, (du,u,p,t) -> f(du, u, p, t, k))
end

(self_::Lorenz)() = (du,u,p,t) -> self_.f(du,u,p,t,self_.k)
function lorenz!(du, u, p, t, k)
    du[1] = 10.0*k * (u[2] - u[1])
    du[2] = u[1] * (28.0 - u[3]) - u[2]
    du[3] = u[1] * u[2] - (8 / 3) * u[3]
end

lstruct = Lorenz(2.0, lorenz!)

u0 = [1.0; 0.0; 0.0]
tspan = (0.0, 100.0)

ODEProblem(f::Lorenz, u0, tspan, p = SciMLBase.NullParameters();kwargs...) = DifferentialEquations.ODEProblem(f(), u0, tspan, p;kwargs...)
# ODEProblem(f::Lorenz;kwargs) = DifferentialEquations.ODEProblem(f(); kwargs...)

prob = ODEProblem(lstruct, u0, tspan)

lstruct.k = 2.0
@time sol1 = solve(prob);
lstruct.k = 0.0
@time sol2 = solve(prob);

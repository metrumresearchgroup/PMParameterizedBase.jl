using ModelingToolkit, Plots, DifferentialEquations
@parameters t
pars = @parameters σ=10.0 ρ=28.0 β=8.0/3.0 IC = 1.0
vars = @variables x(t)=IC y(t)=0.0 z(t)=0.0
D = Differential(t)

a = x*(ρ-z)

eqs = [D(x) ~ σ*(y-x),
       D(y) ~ a-y,
       D(z) ~ x*y - β*z]

@named de = ODESystem(eqs,t, vars, pars, tspan=(0, 1000.0))
de = structural_simplify(de)
prob = ODEProblem(de)
sol = solve(prob);

plot(sol.t,sol[:a])


de.IC = 100.0

# de.IC = 15.0
# prob2 = ODEProblem(de)
sol2 = solve(prob)

plot(sol2.t,sol2[:x])
using ModelingToolkit
using Plots

@variables t x(t)  # independent and dependent variables
@constants h = 1 q = h+1    # constants

@parameters τ zz = q + 1    # parameters
D = Differential(t) # define an operator for the differentiation w.r.t. time

# your first ODE, consisting of a single equation, indicated by ~
@named fol_model = ODESystem(D(x) ~ (h - x) / τ + zz)
fol_func  = ODEFunction(fol_model, [x], [τ,zz])

prob = ODEProblem(fol_model, [x => 0.0], (0.0, 10.0), [τ => 3.0, h=>ModelingToolkit.getdefault(h), q=>ModelingToolkit.getdefault(q), zz =>  ModelingToolkit.getdefault(zz)])
prob[zz]  # THIS WILL GIVE YOU THE ACTUAL VALUE OF ZZ

sol1 = solve(prob)

plot(sol1)
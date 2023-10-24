using Revise
using PMParameterized
using ModelingToolkit
using Unitful

foo = @model TestMTKODE begin
    @IVs t
    Dt = Differential(t)
    file = "Params.ym"


    @parameters σ =10.0 [unit = u"m^3/s"]
    
    @parameters ρ=28.0 β=8.0/3.0
    @parameters IC [location = "Params.yml"]


    zz = 2.3

    IC2 = IC * 200.0
    @variables x(t)=IC2 y(t)=0.0 z(t)=0.0 q(t) [location="Params.yml"]

    @eq Dt(x) ~ σ*(y-x)
    a = x*(ρ-z)
    @eq Dt(y) ~ a - y
    @eq Dt(z) ~ x*y - β*z
    @eq Dt(q) ~ 0.0
end;






using DifferentialEquations
prob = ODEProblem(foo.model, [], (0.0, 1000.0))
sol = solve(prob);
plot(sol.t,sol[:x])

bar = @model TestMTKPDE begin
    @IVs t q
    @parameters σ=10.0 ρ=28.0 β=8.0/3.0 IC = 1.0
    @variables x(..) y(..) z(..)

    # @D((q,t), x(q,t) ~ σ*(y(q,t)-x(q,t)))
    # @D((q,t), y(q,t) ~ x(q,t)*(ρ-z(q,t))-y(q,t))
    # @D((q,t), z(q,t) ~ x(q,t)*y(q,t) - β*z(q,t))
end;


 
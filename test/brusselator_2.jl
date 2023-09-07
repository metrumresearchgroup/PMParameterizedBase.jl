using ModelingToolkit, MethodOfLines, DomainSets


@parameters x y t
@variables u(..) v(..)
Dt = Differential(t)
Dx = Differential(x)
Dy = Differential(y)
Dxx = Differential(x)^2
Dyy = Differential(y)^2

∇²(u) = Dxx(u) + Dyy(u)

brusselator_f(x, y, t) = (((x-0.3)^2 + (y-0.6)^2) <= 0.1^2) * (t >= 1.1) * 5.

x_min = y_min = t_min = 0.0
x_max = y_max = 1.0
t_max = 11.5

α = 10.

u0(x,y,t) = 22(y*(1-y))^(3/2)
v0(x,y,t) = 27(x*(1-x))^(3/2)




domains = [x ∈ Interval(x_min, x_max),
              y ∈ Interval(y_min, y_max),
              t ∈ Interval(t_min, t_max)]

# Periodic BCs
bcs = [u(x,y,0) ~ u0(x,y,0),
       u(0,y,t) ~ u(1,y,t),
       u(x,0,t) ~ u(x,1,t),

       v(x,y,0) ~ v0(x,y,0),
       v(0,y,t) ~ v(1,y,t),
       v(x,0,t) ~ v(x,1,t)] 

u = u(x,y,t)
v = v(x,y,t)

    eq = [Dt(u) ~ 1. + v*u^2 - 4.4*u + α*∇²(u) + brusselator_f(x, y, t),
    Dt(v) ~ 3.4*u - v*u^2 + α*∇²(v)]

@named pdesys = PDESystem(eq,bcs,domains,[x,y,t],[u,v])

N = 32

order = 2 # This may be increased to improve accuracy of some schemes

# Integers for x and y are interpreted as number of points. Use a Float to directtly specify stepsizes dx and dy.
discretization = MOLFiniteDifference([x=>N, y=>N], t, approx_order=order)


println("Discretization:")
@time prob = discretize(pdesys,discretization)

println("Solve:")
@time sol = solve(prob, TRBDF2(), saveat=0.1)

discrete_x = sol[x];
discrete_y = sol[y];
discrete_t = sol[t];

solu = sol[u];
solv = sol[v];


using Plots
anim = @animate for k in 1:length(discrete_t)
    heatmap(solu[2:end, 2:end, k], title="$(discrete_t[k])"); # 2:end since end = 1, periodic condition
end
gif(anim, "Brusselator2Dsol_u.gif", fps = 8)
#### THIS IS JUST AN EXAMPLE. NEED TO UPDATE!
### SEE HERE FOR INSIPIRATION https://github.com/SciML/DiffEqParamEstim.jl/blob/227ececc2af8b24746e395c88973ad9f7f87e0af/src/multiple_shooting_objective.jl#L58-L64
### BE SURE TO CHECK AND MAKE SURE INPUT AND P UPDATES ARE HANDLED CORRECLTY WHEN DOING THIS!
struct Merged_Solution{T1, T2, T3}
    u::T1
    t::T2
    sol::T3
end;


sol_tmp = Merged_Solution(vcat(sol1.u[1:end-1],sol2.u),vcat(sol1.t[1:end-1],sol2.t), sol2);
sol_new = DiffEqBase.build_solution(lorenz_prob, sol1.alg, sol_tmp.t, sol_tmp.u, retcode = SciMLBase.ReturnCode.Success);
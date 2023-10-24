using PMParameterized
using Plots
using SciMLSensitivity
using GlobalSensitivity
using DifferentialEquations

# define model

mdl = PMParameterized.@model mdl begin
    @IVs t [description = "time", tspan = (0.0, 21.0 * 24.0)]
    D = Differential(t)
    @parameters begin 
        CL_ADC = 0.0043/24.0  # L/h/kg ; central clearance
        CLD_ADC = 0.014/24.0  # L/kg   ; intercompartmental clearance
        V1_ADC = 0.034        # L/h/kg ; central volume
        V2_ADC = 0.04         # L/kg   ; peripheral volume
    end

    @variables begin
        X1_ADC_nmol(t) = (3.6*1e-3*70.0)/(148781/1e9) # [nmol]
        X2_ADC_nmol(t) = 0.0
    end

 @eq D(X1_ADC_nmol) ~ -(CL_ADC/V1_ADC)*X1_ADC_nmol - (CLD_ADC/V1_ADC)*X1_ADC_nmol + (CLD_ADC/V2_ADC)*X2_ADC_nmol
 @eq D(X2_ADC_nmol) ~ (CLD_ADC/V1_ADC)*X1_ADC_nmol - (CLD_ADC/V2_ADC)*X2_ADC_nmol
end;

mdl.tspan = (0.0, 21.0*24.0);

sol = PMParameterized.solve(mdl, saveat = 1.0);

plot(sol.t, sol.X1_ADC_nmol, label="X1_ADC_nmol")
plot!(sol.t, sol.X2_ADC_nmol, label = "X2_ADC_nmol")

tspan = mdl.tspan
prob_sens = PMParameterized.ODEForwardSensitivityProblem(mdl, mdl.states, mdl.tspan, mdl.parameters);
sol_sens = solve(prob_sens, Tsit5())


tmp_mod = deepcopy(mdl);
f_globsens = function(p, nms)
    pin = NamedTuple{nms}(p)
    tmp_mod.parameters = pin
    tmp_sol = PMParameterized.solve(tmp_mod, saveat = sol.t)
    [maximum(tmp_sol.X1_ADC_nmol)]
end

n = 1000
using ComponentArrays
lb = ComponentArray(CL_ADC = 0.1, CLD_ADC = 1.0, V1_ADC = 0.5, V2_ADC = 0.1)
ub = ComponentArray(CL_ADC = 5.0, CLD_ADC = 10.0, V1_ADC = 5.0, V2_ADC = 5.0)
using GlobalSensitivity
sampler = GlobalSensitivity.SobolSample()
A, B = GlobalSensitivity.QuasiMonteCarlo.generate_design_matrices(n, lb, ub, sampler)
s = GlobalSensitivity.gsa((p) -> f_globsens(p, keys(lb)), Sobol(order = [0, 1, 2]), A, B);
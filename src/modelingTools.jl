using DifferentialEquations
using SciMLSensitivity


Base.@kwdef struct partialSol
    partialsolution
    observed::ModelValues
    parameters::ModelValues
    states::ModelValues
end



function (sol::MRGSolution)(in)
    if length(in) == 1
        in = [in]
    end
    stmp = sol._solution(in)
    psol = partialSol(partialsolution = stmp, observed = sol._observed, parameters = sol._parameters, states = sol._states)
    return psol
end





function solve(mdl::MRGModel, alg::Union{DEAlgorithm,Nothing} = nothing ; kwargs...)
    regenerateODEProblem!(mdl)
    sol = DifferentialEquations.solve(mdl._odeproblem, alg; kwargs...)
    solution = MRGSolution(_solution = sol,
                            _states = mdl.states,
                            _parameters = mdl.parameters,
                            _constants = mdl._constants, 
                            _observed = mdl.observed,
                            _names = vcat(collect(keys(mdl.observed._values)),mdl.parameters.names,mdl.states.names))
    return solution
end


function solve!(mdl::MRGModel, alg::Union{DEAlgorithm,Nothing} = nothing ; kwargs...)
    regenerateODEProblem!(mdl)
    sol = DifferentialEquations.solve(mdl._odeproblem, alg; kwargs...)
    solution = MRGSolution(_solution = sol,
                            _states = mdl.states,
                            _parameters = mdl.parameters,
                            _constants = mdl._constants, 
                            _observed = mdl.observed, 
                            _names = vcat(collect(keys(mdl.observed._values)),mdl.parameters.names,mdl.states.names))
    mdl._solution = solution
    return nothing
end



function ODEForwardSensitivityProblem(mdl::MRGModel, u0::ModelValues, tspan, p::ModelValues, sensealg::SciMLSensitivity.AbstractForwardSensitivityAlgorithm = ForwardSensitivity();
    kwargs... )
    regenerateODEProblem!(mdl)
    f = mdl._odeproblem.f
    u0 = mdl._odeproblem.u0
    p = mdl._odeproblem.p
    sens_prob = SciMLSensitivity.ODEForwardSensitivityProblem(f, u0, tspan, p, sensealg; kwargs...)
    return sens_prob
end

using DifferentialEquations
using SciMLSensitivity



Base.@kwdef struct partialSol
    partialsolution
    observed::ModelValues
    parameters::ModelValues
    states::ModelValues
end



function (sol::PMSolution)(in)
    if length(in) == 1
        in = [in]
    end
    stmp = sol._solution(in)
    psol = partialSol(partialsolution = stmp, observed = sol._observed, parameters = sol._parameters, states = sol._states)
    return psol
end





function solve(mdl::PMModel, alg::Union{DEAlgorithm,Nothing} = nothing ; kwargs...)
    mdl_internal = deepcopy(mdl)
    regenerateODEProblem!(mdl_internal)
    sol = DifferentialEquations.solve(mdl_internal._odeproblem, alg; kwargs...)
    solution = PMSolution(_solution = sol,
                            _states = mdl_internal.states,
                            _parameters = mdl_internal.parameters,
                            _constants = mdl_internal._constants, 
                            _observed = mdl_internal.observed,
                            _names = vcat(collect(keys(mdl_internal.observed._values)),mdl_internal.parameters.names,mdl_internal.states.names))
    return solution
end


function solve!(mdl::PMModel, alg::Union{DEAlgorithm,Nothing} = nothing ; kwargs...)
    mdl_internal = deepcopy(mdl)
    regenerateODEProblem!(mdl_internal)
    sol = DifferentialEquations.solve(mdl_internal._odeproblem, alg; kwargs...)
    solution = PMSolution(_solution = sol,
                            _states = mdl_internal.states,
                            _parameters = mdl_internal.parameters,
                            _constants = mdl_internal._constants, 
                            _observed = mdl_internal.observed, 
                            _names = vcat(collect(keys(mdl_internal.observed._values)),mdl_internal.parameters.names,mdl_internal.states.names))
    mdl_internal._solution = solution
    return nothing
end


# function solve(mdl::PMModel, alg::Union{DEAlgorithm,Nothing} = nothing ; evs::Vector{Union}, kwargs...)


function ODEForwardSensitivityProblem(mdl::PMModel, u0::ModelValues, tspan, p::ModelValues, sensealg::SciMLSensitivity.AbstractForwardSensitivityAlgorithm = ForwardSensitivity();
    kwargs... )
    regenerateODEProblem!(mdl)
    f = mdl._odeproblem.f
    u0 = mdl._odeproblem.u0
    p = mdl._odeproblem.p
    sens_prob = SciMLSensitivity.ODEForwardSensitivityProblem(f, u0, tspan, p, sensealg; kwargs...)
    return sens_prob
end

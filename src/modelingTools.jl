using DifferentialEquations


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
    cb = nothing
    if :evs in keys(kwargs)
        
        # evs = pop!(kwargs,:evs) 
        evs = kwargs[:evs]
        # delete!(kwargs, :evs)
        # kwargs = kwargs[keys(kwargs) != :evs]
        # if isa(evs, Vector{Ball})
    end
    regenerateODEProblem!(mdl)
    sol = DifferentialEquations.solve(mdl._odeproblem, alg; callback = cb, kwargs...)
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



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


@inline function Base.propertynames(x::partialSol)
    names = vcat(x.states.names, x.parameters.names, x.observed.names)
    return names
end

@inline function Base.getproperty(x::partialSol, sym::Symbol)
    if sym in [:parameters, :states, :observed, :partialsolution]
        out = getfield(x, sym)
    else
        if sym in vcat(x.states.names, x.parameters.names)
            out = x.partialsolution[sym]
        elseif sym in x.observed.names
            obs = x.observed._values[sym]._valmap[x.observed._values[sym].value]
            out = x.partialsolution[obs]
        else
            error("Unknown error")
        end
    end
    return out
end

@inline function Base.getindex(x::partialSol, sym::Symbol)
    if sym in [:parameters, :states, :observed, :partialsolution]
        out = getfield(x, sym)
    else
        if sym in vcat(x.states.names, x.parameters.names)
            out = x.partialsolution[sym]
        elseif sym in x.observed.names
            obs = x.observed._values[sym]._valmap[x.observed._values[sym].value]
            out = x.partialsolution[obs]
        else
            error("Unknown error")
        end
    end
    return out
end


function solve(mdl::MRGModel, alg::Union{DEAlgorithm,Nothing} = nothing ; kwargs...)
    regenerateODEProblem(mdl)
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
    regenerateODEProblem(mdl)
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


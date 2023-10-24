using Symbolics
using ModelingToolkit

@inline function Base.getindex(x::PMSolution, sym::Symbol)
    sys = getfield(x,:_solution).prob.f.sys
    ivsym = ModelingToolkit.independent_variable(sys).metadata[ModelingToolkit.VariableSource][2]
    if sym in getfield(x, :_names)
        if sym in keys(x._observed._values)
            obs = x._observed._values[sym]._valmap[x._observed._values[sym].value]
            out = x._solution[obs]
        else
            out = x._solution[sym]
        end
        if length(out) == 1
            out = ones(length(x._solution)) .* out
        end
    elseif sym == ivsym
        out = out._solution[sym]
    else
        out = getfield(x, sym)
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
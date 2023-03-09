using MacroTools

# @inline Base.getproperty(obj::MRGModel, s::Symbol) = _getindex(Base.maybeview, x, Val(s))
@inline function Base.getproperty(obj::MRGModel, sym::Symbol)
    if sym === :parsed
        ex = getfield(obj,:raw)
        return MacroTools.striplines(ex)
    else # fallback to getfield
        return getfield(obj, sym)
    end
end


" Function to show parsed model with references to original definition and line numbers"
function show_parsed(mdl::MRGModel)
    getfield(mdl,:raw)
end



function params!(model::MRGModel, params::ComponentArray)
    for k in keys(params)
        if hasproperty(model.parameters, k)
            setproperty!(model.parameters, k, getproperty(params, k))
        else
            error("Parameter(s) ", string(k), " not defined in the model")
        end
    end
end

function params(model::MRGModel, params::ComponentArray)
    mdl_copy = deepcopy(model)
    for k in keys(params)
        if hasproperty(mdl_copy.parameters, k)
            setproperty!(mdl_copy.parameters, k, getproperty(params, k))
        else
            error("Parameter(s) ", string(k), " not defined in the model")
        end
    end
    return mdl_copy
end




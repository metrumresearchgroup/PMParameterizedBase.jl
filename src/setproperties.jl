using Symbolics
using ModelingToolkit

function Base.setproperty!(x::NumValue, sym::Symbol, v::Real)
    if sym == :_defaultExprs
        error("Field $sym is immutable")
    else
        isconst = getfield(x, :_constant)
        if isconst
            error("Constant $sym is immutable")
        else
            setfield!(x, sym, v)
        end
    end
end

## Add functionality for updating parameters!
@inline function Base.setproperty!(x::ModelValues, sym::Symbol, v::Real)
    if sym in getfield(x, :names)
        vals = x._values[sym]
        if vals._constant
            error("Constant $sym is immutable")
        end
        x._uvalues[x._values[sym].value] = v
    else
        if hasfield(typeof(x),sym)
            error("Field $sym is immutable")
        else
            setfield!(x, sym, v)
        end
    end
end


@inline function Base.setproperty!(x::MRGModel, sym::Symbol, v::ComponentArrays)
    if sym == :parameters
        for vk in keys(v)
            setfield(x.parameters, sym, v[vk])
        end
            # setfield(x,setfield(mdl.parameters
    elseif sym == :states
        for vk in keys(v)
            setfield(x.states, sym, v[vk])
        end
    else
        setfield!(x, sym, v)
    end
end

@inline function Base.setproperty!(x::MRGModel, sym::Symbol, v::AbstractArray)
    if !all(isa.(keys(v), Symbol))
        error("Parameter input must have parameter name keys, please see ComponentArrays or LabelledArrays")
    end
    if sym == :parameters
        for vk in keys(v)
            setfield(x.parameters, sym, v[vk])
        end
            # setfield(x,setfield(mdl.parameters
    elseif sym == :states
        for vk in keys(v)
            setfield(x.states, sym, v[vk])
        end
    else
        setfield!(x, sym, v)
    end
end


@inline function Base.setproperty!(x::MRGModel, sym::Symbol, v::NamedTuple)
    if sym == :parameters
        for vk in keys(v)
            setfield(x.parameters, sym, v[vk])
        end
            # setfield(x,setfield(mdl.parameters
    elseif sym == :states
        for vk in keys(v)
            setfield(x.states, sym, v[vk])
        end
    else
        setfield!(x, sym, v)
    end
end


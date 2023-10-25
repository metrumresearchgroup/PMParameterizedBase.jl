using Symbolics
using ModelingToolkit

function Base.setindex!(x::NumValue, v::Real,sym::Symbol)
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
@inline function Base.setindex!(x::ModelValues, v::Real, sym::Symbol)
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



@inline function Base.setindex!(x::PMModel, v::AbstractArray, sym::Symbol)

    if sym == :parameters
        if !all(isa.(keys(v), Symbol))
            error("Parameter input must have parameter name keys, please see ComponentArrays or LabelledArrays")
        end
        for vk in keys(v)
            # setfield!(x.parameters, vk, v[vk])
            x.parameters._uvalues[x.parameters._values[vk].value] = v[vk]

        end
            # setfield(x,setfield(mdl.parameters
    elseif sym == :states
        if !all(isa.(keys(v), Symbol))
            error("Parameter input must have parameter name keys, please see ComponentArrays or LabelledArrays")
        end
        for vk in keys(v)
            x.states._uvalues[x.states._values[vk].value] = v[vk]
            # setfield!(x.states, vk, v[vk])
        end
    else
        setfield!(x, sym, v)
    end
end


@inline function Base.setindex!(x::PMModel, v::NamedTuple, sym::Symbol)
    if sym == :parameters
        for vk in keys(v)
            x.parameters._uvalues[x.parameters._values[vk].value] = v[vk]
        end
            # setfield(x,setfield(mdl.parameters
    elseif sym == :states
        for vk in keys(v)
            x.states._uvalues[x.states._values[vk].value] = v[vk]
        end
    else
        setfield!(x, sym, v)
    end
end

@inline function Base.setindex!(x::PMModel, v::Tuple, sym::Symbol)
    if sym == :tspan
        x._odeproblem = remake(x._odeproblem, tspan = v)
        setfield!(x, sym, v)
    else
        setfield!(x, sym, v)
    end
end




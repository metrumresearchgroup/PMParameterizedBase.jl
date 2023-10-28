# # Change accessor to get parameter value when accessing parameter name

@inline function Base.getproperty(x::Parameters, sym::Symbol)
    if sym in getfield(x, :names)
        valuepair = getfield(x,:values)[getfield(x,:sym_to_val)[sym]]
        mapto = [valuepair]
        mapping = vcat(getfield(x,:values), getfield(getfield(x,:constants),:values))
        return getfield(mapVector(mapto, mapping)[1],:second)
    else
        return getfield(x, sym)
    end
end

@inline function Base.getproperty(x::Variables, sym::Symbol)
    if sym in getfield(x, :names)
        valuepair = getfield(x,:values)[getfield(x,:sym_to_val)[sym]]
        mapto = [valuepair]
        mapping = vcat(getfield(x,:values), getfield(getfield(x,:constants),:values), getfield(getfield(x,:parameters),:values))
        return getfield(mapVector(mapto, mapping)[1],:second)
    else
        return getfield(x, sym)
    end
end

@inline function Base.getproperty(x::Constants, sym::Symbol)
    if sym in getfield(x, :names)
        idx = getindex(getfield(x, :sym_to_val), sym)
        return getfield(getindex(getfield(x, :values),idx),:second)
    else
        return getfield(x, sym)
    end
end

@inline function Base.getproperty(x::PMModel, sym::Symbol)
    if sym == :constants
        return getfield(getfield(x,:parameters), :constants)
    else
        return getfield(x, sym)
    end
end





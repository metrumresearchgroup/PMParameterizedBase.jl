
# # # Change property names to only show parameters


@inline function Base.propertynames(x::ModelValues)
    return getfield(x,:names)
end

@inline function Base.propertynames(x::ModelConstants)
    return getfield(x, :names)
end

@inline function Base.propertynames(x::PMModel)
    return [:parameters, :states, :constants, :tspan, :model, :equations, :observed]
end

using Symbolics
using ModelingToolkit
# # Change property names to only show parameters
@inline function Base.propertynames(x::ModelValues)
    return x.names
end

@inline function Base.propertynames(x::PMModel)
    return [:parameters, :states, :observed, :model, :tspan, :equations, :constants]
end
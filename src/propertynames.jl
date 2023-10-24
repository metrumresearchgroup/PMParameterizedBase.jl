using Symbolics
using ModelingToolkit
# # Change property names to only show parameters
@inline function Base.propertynames(x::ModelValues)
    return x.names
end

@inline function Base.propertynames(x::PMSolution)
    return x._names
end

@inline function Base.propertynames(x::partialSol)
    names = vcat(x.states.names, x.parameters.names, x.observed.names)
    return names
end

@inline function Base.propertynames(x::PMModel)
    return [:parameters, :states, :observed, :model, :tspan]
end
using Symbolics
using ModelingToolkit



# # Change accessor to get parameter value when accessing parameter name
@inline function Base.getproperty(x::ModelValues, sym::Symbol)
    if sym in getfield(x, :names)
        return getfield(x,:_values)[sym]
    else
        return getfield(x, sym)
    end
end

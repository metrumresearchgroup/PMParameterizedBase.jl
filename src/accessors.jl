using Symbolics
using ModelingToolkit


# # Change property names to only show parameters
@inline function Base.propertynames(x::ModelValues)
    return x.names
end

# # Change accessor to get parameter value when accessing parameter name
@inline function Base.getproperty(x::ModelValues, sym::Symbol)
if sym in getfield(x, :names)
    return getfield(x,:_values)[sym]
else
    return getfield(x, sym)
end
end


# TYPE CONVERSION RULES ARE AWESOME.
@inline function Base.convert(::Type{T}, x::NumValue) where {T<:Number}
    if T === NumValue
        out = x
    else
        if !isnothing(x._valmap)
            mergeddict = merge(x._valmap, x._uvalues)
            out = Symbolics.value(substitute(ModelingToolkit.getdefault(x.value), mergeddict))
        else 
            out = x.value
        end
    end
    return out
end


@inline function Base.convert(::Type{T}, x::MRGConst) where {T<:Number}
    if T === MRGConst
        out = x
    else
        out = x.value
    end
    return out
end


function getDefault(value::NumValue)
    return Symbolics.value(substitute(ModelingToolkit.getdefault(value.value), value._valmap))
end


function getExpr(value::NumValue) # Grab the expression for the parameter
    return ModelingToolkit.getdefault(value.value)
end

function getUnit(value::NumValue)
    return ModelingToolkit.get_unit(value.value)
end


function getDescription(value::NumValue)
    return ModelingToolkit.getdescription(value.value)
end

## Add functionality for updating parameters!
function Base.setproperty!(x::ModelValues, sym::Symbol, v::Real)
    if sym in getfield(x, :names)
        x._uvalues[x._values[sym].value] = v
    else
        error("Field $sym is immutable")
    end
end


## Default for printing parametes is to get the value
Base.show(io::IO, param::NumValue) = print(io, param+0.0) # Use type conversion to print as a Float64




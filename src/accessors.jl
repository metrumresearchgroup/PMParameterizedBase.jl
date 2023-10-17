# TYPE CONVERSION RULES ARE AWESOME.
@inline function Base.convert(::Type{T}, x::NumValue) where {T<:Number}
    if T === NumValue
        out = x
    else
        if !isnothing(x._valmap)
            mergeddict = merge(x._valmap, x._uvalues)
            # out = Symbolics.value(substitute(ModelingToolkit.getdefault(x.value), mergeddict))
            out = Symbolics.value(substitute(x._valmap[x.value], mergeddict))
            if x.value in keys(x._uvalues)
                out = x._uvalues[x.value]
            end
        else 
            out = x.value
        end
    end
    return out
end


function getDefault(value::NumValue)
    return Symbolics.value(substitute(ModelingToolkit.getdefault(value.value), value._valmap))
end


function getDefaultExpr(value::NumValue) # Grab the expression for the parameter
    return ModelingToolkit.getdefault(value._defaultExpr)
end



function getUnit(value::NumValue)
    return ModelingToolkit.get_unit(value.value)
end


function getDescription(value::NumValue)
    return ModelingToolkit.getdescription(value.value)
end


## Default for printing parametes is to get the value
Base.show(io::IO, param::NumValue) = print(io, param+0.0) # Use type conversion to print as a Float64




# TYPE CONVERSION RULES ARE AWESOME.
function Base.convert(::Type{T}, x::MRGVal) where {T<:Number}
    if T === MRGVal
        out = x
    else
        if !isnothing(x._prob)
            out = x._prob[x.name]::T
        else 
            out = x.value
        end
    end
    return out
end


function Base.convert(::Type{T}, x::MRGConst) where {T<:Number}
    if T === MRGConst
        out = x
    else
        out = x.value
    end
    return out
end


function getExpr(param::MRGVal) # Grab the expression for the parameter
    return param.value
end

function getUnit(param::MRGVal)
    return ModelingToolkit.get_unit(param.value)
end


function getDescription(param::MRGVal)
    return ModelingToolkit.getdescription(param.value)
end

## Default for printing parametes is to get the value
Base.show(io::IO, param::MRGVal) = print(io, param+0.0) # Use type conversion to print as a Float64

## ANY OTHER THINGS CAN GO HERE.

#### ADD STUFF FOR ICs








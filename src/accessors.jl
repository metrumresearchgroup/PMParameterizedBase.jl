using Symbolics
using ModelingToolkit


# # Change property names to only show parameters
@inline function Base.propertynames(x::ModelValues)
    return x.names
end

@inline function Base.propertynames(x::MRGSolution)
    return x._names
end

# # Change accessor to get parameter value when accessing parameter name
@inline function Base.getproperty(x::ModelValues, sym::Symbol)
    if sym in getfield(x, :names)
        return getfield(x,:_values)[sym]
    else
        return getfield(x, sym)
    end
end

@inline function Base.getproperty(x::MRGSolution, sym::Symbol)
    # out = Real[]
    sys = getfield(x,:_solution).prob.f.sys
    ivsym = ModelingToolkit.independent_variable(sys).metadata[ModelingToolkit.VariableSource][2]
    if sym in getfield(x, :_names)
        if sym in keys(x._observed._values)
            obs = x._observed._values[sym]._valmap[x._observed._values[sym].value]
            out = x._solution[obs]
        else
            out = x._solution[sym]
        end
        if length(out) == 1
            out = ones(length(x._solution)) .* out
        end
    elseif sym ==  ivsym
        out = x._solution[sym]
    else
        out = getfield(x, sym)
    end
    return out
end

@inline function Base.getindex(x::MRGSolution, sym::Symbol)
    sys = getfield(x,:_solution).prob.f.sys
    ivsym = ModelingToolkit.independent_variable(sys).metadata[ModelingToolkit.VariableSource][2]
    if sym in getfield(x, :_names)
        if sym in keys(x._observed._values)
            obs = x._observed._values[sym]._valmap[x._observed._values[sym].value]
            out = x._solution[obs]
        else
            out = x._solution[sym]
        end
        if length(out) == 1
            out = ones(length(x._solution)) .* out
        end
    elseif sym == ivsym
        out = out._solution[sym]
    else
        out = getfield(x, sym)
    end
    return out
end



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

function getUnit(value::NumValue)
    return ModelingToolkit.get_unit(value.value)
end


function getDescription(value::NumValue)
    return ModelingToolkit.getdescription(value.value)
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
        error("Field $sym is immutable")
    end
end

## Solution Indexing
# @inline function Base.getindex(x::ODESolution, sym::Symbol)




## Default for printing parametes is to get the value
Base.show(io::IO, param::NumValue) = print(io, param+0.0) # Use type conversion to print as a Float64




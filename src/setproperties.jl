using Symbolics
using ModelingToolkit

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
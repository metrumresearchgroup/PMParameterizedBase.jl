# using Symbolics
# using ModelingToolkit

function Base.setproperty!(x::ModelValues, sym::Symbol, v::Real)
    if sym in getfield(x, :names)
        idx = getindex(getfield(x,:sym_to_val), sym)
        num = getindex(getfield(x,:values), idx).first
        return setindex!(getfield(x, :values), Pair(num, v), idx)
    else
        return setfield(x, sym, v)
    end
end



@inline function Base.setindex!(x::ModelValues, v::Real, sym::Symbol)
    idx = x.sym_to_val[sym]
    pair = getindex(getfield(x,:values),idx)
    pairnew = Pair(pair.first, v)
    setindex!(getfield(x,:values),pairnew, idx)
end


@inline function Base.setindex(x::ModelValues, v::Vector{Real}, syms::Vector{Symbol})
    if length(v) != length(syms)
        error("Must provide new values for all model entities")
    else
        for (i, sym) in enumerate(syms)
            idx = x.sym_to_val[sym]
            pair = getindex(getfield(x,:values),idx)
            pairnew = Pair(pair.first, v[i])
            setindex!(getfield(x,:values),pairnew, idx)
        end
    end
end
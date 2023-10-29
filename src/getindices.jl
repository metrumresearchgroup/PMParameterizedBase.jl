@inline function Base.getindex(x::ModelValues, sym::Symbol)
    getproperty(x, sym)
end

@inline function Base.getindex(x::Inputs, sym::Symbol)
    getproperty(x, sym)
end

@inline function Base.getindex(x::ModelValues, syms::Vector{Symbol})
    out = Vector{Real}(undef,length(syms))
    for sym in syms
        push!(out, getproperty(x, sym))
    end
    return out
end



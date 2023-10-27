@inline function mapValue(a::Pair{Symbolics.Num, Number}, map::Vector{Pair{Symbolics.Num, Union{Number, Number}}})
    Pair(a.first, ModelingToolkit.value(substitute(a.second, Dict(map))))
end

@inline function mapVector(mapTo::Vector{Pair{Symbolics.Num, Number}},mapping::Vector{Pair{Symbolics.Num, Number}})
    out = Vector{Pair{Num, Float64}}(undef,length(mapTo))
    for i in 1:lastindex(mapTo)
        out[i] = mapValue(mapTo[i], mapping)
    end
    return out
end


# mapToType = Union{Vector{Pair{Symbolics.Num, T}} where T<:Number, Vector{Pair{Symbolics.Num}}}
mapToType = Vector{Pair{Symbolics.Num, T}} where T<:Number

mapValueType = Pair{Symbolics.Num, T} where T<:Number

@inline function mapValue(a::mapValueType, map::Vector{Pair{Symbolics.Num}})
    Pair(a.first, ModelingToolkit.value(substitute(a.second, Dict(map))))
end


@inline function mapVector(mapTo::mapToType, mapping::Vector{Pair{Symbolics.Num}})
    out = Vector{Pair{Num, Float64}}(undef,length(mapTo))
    for i in 1:lastindex(mapTo)
        out[i] = mapValue(mapTo[i], mapping)
    end
    return out
end

@inline function mapValue(a::mapValueType, map::Vector{Pair{Symbolics.Num, Number}})
    Pair(a.first, ModelingToolkit.value(substitute(a.second, Dict(map))))
end


@inline function mapVector(mapTo::mapToType, mapping::Vector{Pair{Symbolics.Num, Number}})
    out = Vector{Pair{Num, Float64}}(undef,length(mapTo))
    for i in 1:lastindex(mapTo)
        out[i] = mapValue(mapTo[i], mapping)
    end
    return out
end


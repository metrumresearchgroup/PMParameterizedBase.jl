mapToType = Union{Vector{Pair{Symbolics.Num, T}} where T<:Number, Vector{Pair{Symbolics.Num}}}
mapValueType = Pair{Symbolics.Num, T} where T<:Number
mappingType = Union{Vector{Pair{Symbolics.Num}}, Vector{Pair{Symbolics.Num, Symbolics.Num}}}
@inline function mapValue(a::mapValueType, map::mappingType)
    Pair(a.first, ModelingToolkit.value(substitute(a.second, Dict(map))))
end


@inline function mapVector(mapTo::mapToType, mapping::mappingType)
    out = Vector{Pair{Num, Float64}}(undef,length(mapTo))
    for i in 1:lastindex(mapTo)
        out[i] = mapValue(mapTo[i], mapping)
    end
    return out
end

@inline function mapValue(a::mapValueType, map::Vector{Pair{Symbolics.Num, Number}})
    Pair(a.first, ModelingToolkit.value(substitute(a.second, Dict(map))))
end

# @inline function mapValueDefault(a::mapValueType, map::Vector{Pair{Symbolics.Num, Number}})
#     Pair(a.first, ModelingToolkit.value(substitute(a.second, Dict(map))))
# end


@inline function mapVector(mapTo::mapToType, mapping::Vector{Pair{Symbolics.Num, Number}})
    out = Vector{Pair{Num, Float64}}(undef,length(mapTo))
    for i in 1:lastindex(mapTo)
        out[i] = mapValue(mapTo[i], mapping)
    end
    return out
end



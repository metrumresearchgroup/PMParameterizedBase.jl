@inline function Base.getproperty(obj::NamedTuple, sym::Symbol)
    field = getfield(obj, sym)
    if isa(field, MRGVal)
        return field.value
    else
        return field
    end
end
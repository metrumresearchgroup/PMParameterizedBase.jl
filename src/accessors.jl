# # TYPE CONVERSION RULES ARE AWESOME.
# @inline function Base.convert(::Type{T}, x::NumValue) where {T<:Number}
#     if T === NumValue
#         out = x
#     else
#         if !isnothing(x._valmap)
#             mergeddict = merge(x._valmap, x._uvalues)

#             out = Symbolics.value(substitute(x._valmap[x.value], mergeddict))
#             if x.value in keys(x._uvalues)
#                 out = x._uvalues[x.value]
#             end
#         else 
#             out = x.value
#         end
#     end
#     return out
# end


# function getDefault(value::NumValue)
#     return Symbolics.value(substitute(ModelingToolkit.getdefault(value.value), value._valmap))
# end


# function getDefaultExpr(value::NumValue) # Grab the expression for the parameter
#     return ModelingToolkit.getdefault(value._defaultExpr)
# end



# function getUnit(value::NumValue)
#     return ModelingToolkit.get_unit(value.value)
# end


# function getDescription(value::NumValue)
#     return ModelingToolkit.getdescription(value.value)
# end

# function names(mvals::ModelValues; symbolic=true)
#     if symbolic
#         return mvals.names
#     else
#         # return collect(keys(mvals._values[]))
#         return [mvals._values[x].value for x in mvals.names]
#     end
# end

function values(mvals::ModelValues; symbolic=false)
    out = tuple(collect(getproperty(mvals, nm) for nm in mvals.names)...)
    return out
end

function names(mvals::ModelValues)
    out = tuple(collect(nm for nm in mvals.names)...)
    return out
end





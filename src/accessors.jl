function getExpr(mvs::ModelValues, sym::Symbol)::Num
    valuepair = getfield(x,:values)[getfield(x,:sym_to_val)[sym]]
    return ModelingToolkit.getdefault(valuepair.first)
end

function getExprs(mvs::ModelValues, syms::Vector{Symbol})::Num
    out = Vector{Num}(undef, length(syms))
    for (i, sym) in enumerate(syms)
        valuepair = getfield(x,:values)[getfield(x,:sym_to_val)[sym]]
        out[i] = ModelingToolkit.getdefault(valuepair.first)
    end
    return out
end


function getDefault(mvs::ModelValues, sym::Symbol)
    valuepair = getfield(mvs,:values)[getfield(mvs,:sym_to_val)[sym]]
    mapto = [valuepair]
    mapping = vcat(getfield(mvs,:defaults)..., getfield(getfield(mvs,:constants),:values))
    println(mapping)
    return getfield(mapVector(mapto, mapping)[1], :second)
end


function getDefaultExpr(value::Num) # Grab the expression for the parameter
    return ModelingToolkit.getdefault(value)
end



function getUnit(value::Num)
    return ModelingToolkit.get_unit(value)
end


function getDescription(value::Num)
    return ModelingToolkit.getdescription(value.value)
end

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





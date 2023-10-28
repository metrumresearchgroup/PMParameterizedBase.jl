function getDefaultExpr(mvs::ModelValues, sym::Symbol)::Num
    valuepair = getfield(mvs,:values)[getfield(mvs,:sym_to_val)[sym]]
    return ModelingToolkit.getdefault(valuepair.first)
end



function getDefault(mvs::Parameters, sym::Symbol)
    valuepair = getfield(mvs,:defaults)[getfield(mvs,:sym_to_val)[sym]]
    mapto = [valuepair]
    mapping = vcat(getfield(mvs,:defaults)..., getfield(getfield(mvs,:constants),:values))
    return getfield(mapVector(mapto, mapping)[1], :second)
end

function getDefault(mvs::Variables, sym::Symbol)
    valuepair = getfield(mvs,:defaults)[getfield(mvs,:sym_to_val)[sym]]
    mapto = [valuepair]
    mapping = vcat(getfield(mvs,:defaults), getfield(getfield(mvs,:constants),:values), getfield(getfield(mvs,:parameters),:defaults))
    return getfield(mapVector(mapto, mapping)[1], :second)
end

function getUnit(mvs::ModelValues, sym::Symbol)
    value = getfield(mvs, :values)[getfield(mvs,:sym_to_val)[sym]]
    return ModelingToolkit.get_unit(value.first)
end

function getDescription(value::Num)
    value = getfield(mvs, :values)[getfield(mvs,:sym_to_val)[sym]]
    return ModelingToolkit.getdescription(value.first)end

function values(mvals::ModelValues; symbolic=false)
    out = tuple(collect(getproperty(mvals, nm) for nm in mvals.names)...)
    return out
end

function names(mvals::ModelValues)
    out = tuple(collect(nm for nm in mvals.names)...)
    return out
end





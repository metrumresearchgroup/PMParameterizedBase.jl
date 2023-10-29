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

function getDescription(mvs::ModelValues,sym::Symbol)
    value = getfield(mvs, :values)[getfield(mvs,:sym_to_val)[sym]]
    return ModelingToolkit.getdescription(value.first)
end

function Base.values(mvals::ModelValues; symbolic=false)
    out = [getproperty(mvals, nm) for nm in mvals.names]
    return out
end

function Base.names(mvals::ModelValues)
    out = [nm for nm in mvals.names]
    return out
end

function names(mvals::Observed)
    out = [nm for nm in mvals.names]
    return out
end




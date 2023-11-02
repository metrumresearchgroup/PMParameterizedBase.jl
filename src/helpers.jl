indexof(sym::Symbol, syms) = findfirst(isequal(sym), syms)
function getModelIndex(mdl::PMModel, sym::Symbol)
    psyms = Symbol.(parameters(mdl.model))
    ssyms = [x.metadata[ModelingToolkit.VariableSource][2] for x in states(mdl.model)]
    pindex = indexof(sym, psyms)
    sindex = indexof(sym, ssyms)
    if !isnothing(pindex) && !isnothing(sindex)
        error("Found $sym in parameters and states, cannot get index")
    elseif isnothing(pindex) && isnothing(sindex)
        error("Cannot locate $sym in parameters or states")
    end
    indices = [pindex, sindex]
    index = indices[indices.!=nothing][1] # Get only the non-nothing index
    return index
end


@inline function getSymbolicName(x::Union{Num,SymbolicUtils.BasicSymbolic{Real}})
        if hasproperty(x, :val)
            return x.val.metadata[ModelingToolkit.VariableSource][2]
        else
            return x.metadata[ModelingToolkit.VariableSource][2]
        end
    end
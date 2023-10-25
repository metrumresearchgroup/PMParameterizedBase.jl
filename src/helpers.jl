function getNumericValue(x::NumValue)
    mergeddict = merge(x._valmap, x._uvalues)
    out = Symbolics.value(substitute(x._valmap[x.value], mergeddict))
    if x.value in keys(x._uvalues)
        out = x._uvalues[x.value]
    end
    return out
end




function getSymbolicName(x::Union{Num,SymbolicUtils.BasicSymbolic{Real}})
        if hasproperty(x, :val)
            return x.val.metadata[ModelingToolkit.VariableSource][2]
        else
            return x.metadata[ModelingToolkit.VariableSource][2]
        end
    end
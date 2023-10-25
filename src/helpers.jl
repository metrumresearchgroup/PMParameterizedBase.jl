using SciMLBase
# function updateEntities!(mdl::PMMo)
function getNumericValue(x, mdl::PMModel)
    mergeddict = merge(x._valmap, x._uvalues)
    out = Symbolics.value(substitute(x._valmap[x.value], mergeddict))
    if x.value in keys(x._uvalues)
        out = x._uvalues[x.value]
    end
    return out
end


function regenerateODEProblem!(mdl::PMModel)
    p = [getproperty(mdl.parameters, x).value => getNumericValue(getproperty(mdl.parameters,x), mdl) for x in mdl.parameters.names]
    u0 = [getproperty(mdl.states, x).value => getNumericValue(getproperty(mdl.states,x), mdl) for x in mdl.states.names]
    mdl._odeproblem = remake(mdl._odeproblem, p = p, u0 = u0)
end

function getSymbolicName(x::Union{Num,SymbolicUtils.BasicSymbolic{Real}})
        if hasproperty(x, :val)
            return x.val.metadata[ModelingToolkit.VariableSource][2]
        else
            return x.metadata[ModelingToolkit.VariableSource][2]
        end
    end
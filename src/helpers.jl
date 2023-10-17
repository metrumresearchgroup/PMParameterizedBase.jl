using SciMLBase
function regenerateODEProblem(mdl::MRGModel)
    for entry in keys(mdl._uvalues)
        sym = entry.val.metadata[ModelingToolkit.VariableSource][2]
        if sym in mdl.parameters.names
            mdl._odeproblem = remake(mdl._odeproblem, p = [entry => mdl._uvalues[entry]])
        elseif sym in mdl.states.names
            mdl._odeproblem = remake(mdl._odeproblem, u0 = [entry => mdl._uvalues[entry]])
        else
            error("Uh oh, something is borked")
        end
    end
end
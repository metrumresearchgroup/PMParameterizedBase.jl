using PMxSim
function variable_parameter_overlap(modmrg::MRGModel)
    pnames = keys(modmrg.parameters)
    snames = keys(modmrg.states)
    rete = ""
    if !isempty(intersect(pnames, snames))
        overlap = (intersect(pnames, snames))
        # rete = string.("There are both parameters and states named: ", join(overlap,", "))
        error(string.("There are both parameters and states named: ", join(overlap,", ")))
    end
end

function variable_repeat(modmrg::MRGModel)
    snames = keys(modmrg.states)
    unique_states = unique([snames...])
    if length(unique_states) != length(snames)
        error("State(s) $duplicates defined multiple times")
    end
end

function parameter_repeat(modmrg::MRGModel)
    pnames = keys(modmrg.parameters)
    unique_parameters = unique([pnames...])
    if length(unique_parameters) != length(pnames)
        error("Parameter(s) $duplicates defined multiple times")
    end
end

function checkAll(modmrg::MRGModel)
    # rete = variable_parameter_overlap(modmrg)
    variable_parameter_overlap(modmrg)
    # return rete
end


    

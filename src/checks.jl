function icDdtAgreement(icBlock, derivBlock)
    for ic in icBlock.names
        if ic ∉ derivBlock.names
            error("Initial Condition provided for $ic but no derivative found")
        end
    end
    for deriv in derivBlock.names
        if deriv ∉ icBlock.names
            error("No initial condition found for $deriv")
        end
    end
end


function paramOverwrite(paramBlock, algebraicBlock)
    for (i, av) in enumerate(algebraicBlock.names)
        if av ∈ paramBlock.names
            lnn = algebraicBlock.LNNVector[i]
            type  = paramBlock.type
            @warn "Overwriting $type $av in main body of model at $(lnn.file):$(lnn.line)"
        end
    end
end

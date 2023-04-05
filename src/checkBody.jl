function checkOOPDDT(algebraicBlock, arguments)
    dusym = arguments[1]
    if any(algebraicBlock.names .== dusym)
        for nm in algebraicBlock.names
            idxs = findall(nm .== dusym)
            for idx in idxs
                lnn = algebraicBlock.LNNVector[idx]
                error("Derivatives must be defined using @ddt macro. Found '$dusym.' at $(lnn.file):$(lnn.line)")
            end
        end
    end
end
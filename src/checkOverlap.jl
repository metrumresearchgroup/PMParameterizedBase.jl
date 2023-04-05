using StatsBase
nonunique(x) = [k for (k, v) in countmap(x) if v > 1]

function variableRepeat(Block)
    duplicated = nonunique(Block.names)
    if length(duplicated)>0
        for dup in duplicated
            dup_idxs = findall(dup .== Block.names)
            lnns = Block.LNNVector[dup_idxs]
            lnns_mod = [string(lnn.file,":",lnn.line) for lnn in lnns]
            # if length(duplicated) == 1
            errmsg = string(Block.type, " ", dup, " repeated at ", join(lnns_mod, ", "," and "),".")
            error(errmsg)
        end
    end
end

function variableOverlap(B1, B2)

    duplicated = nonunique(vcat(unique(B1.names), unique(B2.names)))
    if length(duplicated)>0
        lnns = vcat(B1.LNNVector, B2.LNNVector)
        for dup in duplicated
            dup_idxs = findall(dup .== vcat(B1.names, B2.names))
            lnns_dup = lnns[dup_idxs]
            lnns_mod = [string(lnn.file,":",lnn.line) for lnn in lnns_dup]
            errmsg = string(dup, " declared as both ",B1.type, " and ", B2.type, " at ", lnns_mod[1], " and ", lnns_mod[2], ", respectively.")
            error(errmsg)
        end
    end
end

    
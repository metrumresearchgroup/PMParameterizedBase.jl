using PMxSim
using ComponentArrays
function buildAlgebraic(algebraic, pnames, snames, svals, psym,)
    pvec = []
    svec = []
    for pnam in pnames
        push!(pvec, :($pnam = $psym.$pnam))
    end

    for (i, snam) in enumerate(snames)
        sval_i = svals[i]
        push!(svec, :($snam = $sval_i))
    end

    algebraic.args[2].args = vcat(pvec, algebraic.args[2].args) # Add parameters at top
    algebraic.args[2].args = vcat(algebraic.args[2].args, svec) # Add states at bottom

    # Build a line of code to return all the state ICs
    return_line = string("return ComponentArray(")
    for sn in snames
        return_line = string(return_line, "$sn = Float64($sn), ")
    end
    return_line = string(return_line,")") # Add a closing parenthesis
    return_line = Meta.parse(return_line) # Parse this string to an expression
    algebraic.args[2].args = vcat(algebraic.args[2].args, [return_line]) # Return this function
    return algebraic
end

function assembleParamArray(pnames, pvals)
    return_line = string("ComponentArray{Float64}(")
    for i in 1:lastindex(pnames)
        pn = pnames[i]
        pv = pvals[i]
        return_line = string(return_line, "$pn = Float64($pv), ")
    end
    return_line = string(return_line,")") # Add a closing parenthesis
    return_line = Meta.parse(return_line) # Parse this string to an expression
    return return_line
end

function assembleInputs(snames)
    return_line = string("ComponentArray{Float64}(")
    for i in 1:lastindex(snames)
        sn = snames[i]
        return_line = string(return_line, "$sn = 0.0, ")
    end
    return_line = string(return_line, ")") # Add a closing parenthesis
    return_line = Meta.parse(return_line) # Parse this string to an expression
    return return_line
end


function insertParameters(modfn, pnames, pvals, pvec_sym; parse = true)
    modExprs = modfn.args[2] # Ignore function call and grab the block containing everything else
    lastline = 0 # Rembember and return the last line of parameter definitions because we want to insert @constants after this.
    for (i, (pn,pv)) in enumerate(zip(reverse(pnames),reverse(pvals))) # Flip this so these are inserted in the same order as they are defined
        if parse
            expr_tmp = :($pn = $pvec_sym.$pn)
        else
            expr_tmp = :(@mrparam $pn = $pv)
        end
        insert!(modExprs.args, 1, expr_tmp)
        lastline = i
    end
    modfn.args[2] = modExprs
    return modfn, lastline
end


function insertMain(modfn, mnames, mvals, pline; parse = true)
    modExprs = modfn.args[2]
    lastline = pline+1 # Rembember and return the last line of constant definitions because we want to insert @states after this.
    for (i, (mn, mv)) in enumerate(zip(reverse(mnames),reverse(mvals))) # Flip this so these are inserted in the same order as they are defined
        expr_tmp = :($mn = $mv)
        insert!(modExprs.args, pline+1, expr_tmp)
        lastline = lastline + 1
    end
    modfn.args[2] = modExprs
    return modfn, lastline
end

function insertStates(modfn, snames, svals, svec_sym, mline; parse = true)
    modExprs = modfn.args[2]
    lastline = mline # Rembember and return the last line of state definitions because we want to insert everything else after this. 
    for (i, (sn, sv)) in enumerate(zip(reverse(snames),reverse(svals)))
        if parse
            expr_tmp = :($sn = $svec_sym.$sn)
        else
            expr_tmp = :(@mrstate $sn = $sv)
        end
        insert!(modExprs.args, mline+1, expr_tmp)
        lastline = lastline + 1
    end
    modfn.args[2] = modExprs
    return modfn, lastline
end

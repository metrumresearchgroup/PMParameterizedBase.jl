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
        return_line = string(return_line, "$sn = $sn, ")
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
        return_line = string(return_line, "$pn = $pv, ")
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
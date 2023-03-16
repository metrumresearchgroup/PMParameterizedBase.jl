using PMxSim
using ComponentArrays
using Parameters: @unpack

function buildICs(header, pnames, cnames, snames, cvals, svals, pvec_symbol)

    fname = gensym("ICs")
    ICfcn = :(function $fname($psym, ) end) # Create a function expression to hold our stuff
    # Want to add kwargs if they exist
    for arg in header.args
        if typeof(arg)!=Symbol && arg.head == :parameters
            insert!(ICfcn.args[1].args, 2, arg)
        end
    end

    ICfcn = MacroTools.striplines(ICfcn)
    [ICfcn.args[i] = quote end for i in 2:lastindex(ICfcn.args)] # "Blank out" everything but the function call
    pvec = []
    cvec = []
    svec = []
    for pn in pnames
        push!(pvec, :($pn = $pvec_symbol.$pn))
    end

    for (cn,cv) in zip(cnames,cvals)
        push!(cvec), :($cn = $cv)
    end
    for (sn, sv) in zip(snames, svals)
        push!(svec, :($sn = $sv))
    end
    # Add the parameter, constant and state expression vectors to the ICfcn body
    push!(ICfcn.args[2].args, pvec...)
    push!(ICfcn.args[2].args, cvec...)
    push!(ICfcn.args[2].args, svec...)

    return_line = string("return ComponentArray(")
    for sn in snames
        return_line = string(return_line, "$sn = Float64($sn), ")
    end
    return_line = string(return_line, ")") # Add a closing parenthesis
    return_line = Meta.parse(return_line) # Parse this string to an expression
    ICfcn.args[2].args = vcat(ICfcn.args[2].args, [return_line])
    return ICfcn
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
    str_tmp = []
    for (i, (pn,pv)) in enumerate(zip(reverse(pnames),reverse(pvals))) # Flip this so these are inserted in the same order as they are defined
        if parse
            expr_tmp = :($pn = $pvec_sym.$pn)
            # push!(str_tmp, "$pn") # If you want to use a ComponentArray representation in parsed function
        else
            expr_tmp = :(@mrparam $pn = $pv)
            # insert!(modExprs.args, 1, expr_tmp)
        end
        insert!(modExprs.args, 1, expr_tmp) # OG
        lastline = i
    end
    # TODO: Consider switching over to a ComponentArray representation in parsed functions
    # if parse
    #     str_tmp = join(str_tmp,", ")
    #     str_tmp = string("@unpack ", str_tmp, " = $pvec_sym")
    #     insert!(modExprs.args, 1, Meta.parse(str_tmp))
    #     modExprs = Meta.parse(str_tmp)
    # end 
    modfn.args[2] = modExprs
    return modfn, lastline
end


function insertConstants(modfn, cnames, cvals, pline; parse = true)
    modExprs = modfn.args[2]
    lastline = pline+1 # Rembember and return the last line of constant definitions because we want to insert @states after this.
    for (i, (cn, cv)) in enumerate(zip(reverse(cnames),reverse(cvals))) # Flip this so these are inserted in the same order as they are defined
        expr_tmp = :($cn = $cv)
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


function buildObserved(modfn, onames, dusym)
    Obsfcn_name = gensym(:Obs)
    Obsfcn = :(function $Obsfcn_name() end)
    if modfn.args[1].head == :call
        push!(Obsfcn.args[1].args, modfn.args[1].args[2:end]...)
    elseif modfn.args[1].head == :tuple
        push!(Obsfcn.args[1].args, modfn.args[1].args...)
    end
    for ex in modfn.args[2].args
        if typeof(ex) == LineNumberNode
            push!(Obsfcn.args[2].args, ex)
        elseif typeof(ex.args[1]) == Symbol
            push!(Obsfcn.args[2].args, ex)
        elseif ex.args[1].args[1] == dusym
            continue
        else
            push!(Obsfcn.args[2].args,ex)
        end
    end
    return_line = string("return ComponentArray(")
    for on in onames
        return_line = string(return_line, "$on = Float64($on), ")
    end
    return_line = string(return_line, ")") # Add a closing parenthesis
    return_line = Meta.parse(return_line) # Parse this string to an expression
    Obsfcn.args[2].args = vcat(Obsfcn.args[2].args, [return_line])
    return Obsfcn
end





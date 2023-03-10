using PMxSim
using MacroTools

function parse_parameters(modfn)
    pnames = []
    pvals = []
    is_inplace = du_inplace(modfn)
    numArgs = 0
    pPos = 0
    if modfn.args[1].head == :call
        numArgs = length(modfn.args[1].args[2:end])
        pPos = 4
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        pPos = 3
    else
        error("Unknown argument error")
    end
    if !is_inplace
        pPos = pPos - 1
    end
    pvec_symbol = modfn.args[1].args[pPos]
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrparam")
                mrg_expr, pnam_ij, pval_ij = eval(arg_inner)
                pnames = vcat(pnames, pnam_ij)
                pvals = vcat(pvals, pval_ij)
                for ex in mrg_expr
                    push!(inner_args, ex)
                end
            else
                push!(inner_args, arg_inner)
            end
            j = j + 1
        end
        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
        i = i + 1
    end
    return modfn, pvec_symbol, pnames, pvals
end



function parse_states(modfn)
    snames = []
    svals = []
    is_inplace = du_inplace(modfn)
    numArgs = 0
    sPos = 0
    if modfn.args[1].head == :call
        numArgs = length(modfn.args[1].args[2:end])
        sPos = 3
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        sPos = 2
    else
        error("Unknown argument error")
    end
    if !is_inplace
        sPos = sPos - 1
    end
    svec_symbol = modfn.args[1].args[sPos]
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrstate")
                mrg_expr, snam_ij, sval_ij = eval(arg_inner)
                snames = vcat(snames, snam_ij)
                svals = vcat(svals, sval_ij)
                for ex in mrg_expr
                    push!(inner_args, ex)
                end
            else
                push!(inner_args, arg_inner)
            end
            j = j + 1
        end
        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
        i = i + 1
    end
    return modfn, svec_symbol, snames, svals
end

function parse_derivatives(modfn)
    dnames = []
    dvals = []
    is_inplace = du_inplace(modfn)
    numArgs = 0
    dPos = 0
    if modfn.args[1].head == :call
        numArgs = length(modfn.args[1].args[2:end])
        dPos = 2
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        dPos = 1
    else
        error("Unknown argument error")
    end
    dvec_symbol = modfn.args[1].args[dPos]
    if !is_inplace
        dvec_symbol = gensym(:du)
    end
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@ddt")
                mrg_expr, dnam_ij, dval_ij = eval(arg_inner)
                dnames = vcat(dnames, dnam_ij)
                dvals = vcat(dvals, dval_ij)
                for ex in mrg_expr
                    push!(inner_args, ex)
                end
            else
                push!(inner_args, arg_inner)
            end
            j = j + 1
        end
        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
        i = i + 1
    end
    return modfn, dvec_symbol, dnames, dvals
end

function gather_algebraic(modfn)
    vnames = []
    vvals = []
    i = 1
    algebraic = :(function($psym, ) end) # Create a function expression to hold our stuff
    algebraic = MacroTools.striplines(algebraic)
    # Want to collect only algebraic relationships. Parameter relationships and IC calculations will be added from previous parsing of parameters and states. Parameters will go first, states will go last, with algebraic expressions in between so things are calculated in the proper order. 
    for arg_outer in modfn.args
        if typeof(arg_outer) != LineNumberNode
            if arg_outer.head != :call && arg_outer.head != :tuple
                for arg_inner in arg_outer.args
                    if !contains(string(arg_inner), "@ddt") && !contains(string(arg_inner), "@mrparam") && !contains(string(arg_inner), "@mrstate")
                        push!(algebraic.args[2].args, arg_inner)
                    end
                end
            end
        else
            push!(algebraic.args, arg_inner)
        end
    end
    return algebraic
end









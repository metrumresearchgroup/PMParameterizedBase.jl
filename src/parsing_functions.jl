using PMxSim
using MacroTools

function parse_parameters(modfn)
    pnames = Vector{Symbol}[]
    pvals = Vector{Float64}[]
    is_inplace, numkwargs = du_inplace(modfn)
    numArgs = 0
    pPos = 0
    if modfn.args[1].head == :call
        numArgs = length(modfn.args[1].args[2:end])
        pPos = 4 + numkwargs
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        pPos = 3 + numkwargs
    else
        error("Unknown argument error")
    end
    if !is_inplace
        pPos = pPos - 1
    end
    pvec_symbol = modfn.args[1].args[pPos]
    for (i, arg_outer) in enumerate(modfn.args)
        inner_args = []
        for (j, arg_inner) in enumerate(arg_outer.args)
            if contains(string(arg_inner), "@mrparam")
                mrg_expr, pnam_ij, pval_ij = eval(arg_inner)
                pnames = vcat(pnames, pnam_ij)
                pvals = vcat(pvals, pval_ij)
                # We will rebuild the parameter assignments later.
                deleteat!(arg_outer.args,j)
            else
                push!(inner_args, arg_inner)
            end
        end

        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
    end
    return modfn, pvec_symbol, pnames, pvals
end



function parse_states(modfn)
    snames = []
    svals = []
    is_inplace, numkwargs = du_inplace(modfn)
    numArgs = 0
    sPos = 0
    if modfn.args[1].head == :call
        numArgs = length(modfn.args[1].args[2:end])
        sPos = 3 + numkwargs
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        sPos = 2 + numkwargs
    else
        error("Unknown argument error")
    end
    if !is_inplace
        sPos = sPos - 1
    end
    svec_symbol = modfn.args[1].args[sPos]
    for (i, arg_outer) in enumerate(modfn.args)
        inner_args = []
        for (j, arg_inner) in enumerate(arg_outer.args)
            if contains(string(arg_inner), "@mrstate")
                mrg_expr, snam_ij, sval_ij = eval(arg_inner)
                snames = vcat(snames, snam_ij)
                svals = vcat(svals, sval_ij)
                # We will rebuild the state assignments later
                deleteat!(arg_outer.args,j)
            else
                push!(inner_args, arg_inner)
            end
        end
        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
    end
    return modfn, svec_symbol, snames, svals
end

function parse_derivatives(modfn)
    dnames = []
    dvals = []
    is_inplace, numkwargs = du_inplace(modfn)
    numArgs = 0
    dPos = 0
    if modfn.args[1].head == :call
        numArgs = length(modfn.args[1].args[2:end])
        dPos = 2 + numkwargs
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        dPos = 1 + numkwargs
    else
        error("Unknown argument error")
    end
    dvec_symbol = modfn.args[1].args[dPos]
    if !is_inplace
        dvec_symbol = gensym(:du)
        insert!(modfn.args[2].args, 1, :($dusym = similar($usym)))
    end

    for (i, arg_outer) in enumerate(modfn.args)
        inner_args = []
        for (j, arg_inner) in enumerate(arg_outer.args)
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
        end
        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
    end
    return modfn, dvec_symbol, dnames, dvals
end

# TODO: Need to decide if constants should stay in model directly below parameters or should be extracted to parameter vector
function parse_constants(modfn)
    mnames = []
    mvals = []
    for (i, arg_outer) in enumerate(modfn.args)
        inner_args = []
        for (j, arg_inner) in enumerate(arg_outer.args)
            if contains(string(arg_inner), "@constant")
                mrg_expr, mnam_ij, mval_ij = eval(arg_inner)
                mnames = vcat(mnames, mnam_ij)
                mvals = vcat(mvals, mval_ij)
                # We will rebuild the constants later.
                deleteat!(arg_outer.args,j)
            else
                push!(inner_args, arg_inner)
            end
        end
        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
    end
    return modfn, mnames, mvals
end
            

function gather_algebraic(modfn)
    vnames = []
    vvals = []
    fname = gensym("ICs")
    algebraic = :(function $fname($psym, ) end) # Create a function expression to hold our stuff
    # Want to add kwargs if they exist
    header = modfn.args[1].args
    for arg in header
        if typeof(arg)!=Symbol && arg.head == :parameters
            insert!(algebraic.args[1].args, 2, arg)
        end
    end
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
    return algebraic, vnames, vvals
end









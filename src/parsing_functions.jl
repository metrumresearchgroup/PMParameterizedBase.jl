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
    cnames = []
    cvals = []
    for (i, arg_outer) in enumerate(modfn.args)
        inner_args = []
        for (j, arg_inner) in enumerate(arg_outer.args)
            if contains(string(arg_inner), "@constant")
                mrg_expr, cnam_ij, cval_ij = eval(arg_inner)
                cnames = vcat(cnames, cnam_ij)
                cvals = vcat(cvals, cval_ij)
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
    return modfn, cnames, cvals
end

function parse_constants2(modfn)
    return modfn
end


function parse_observed(modfn)
    onames = []
    ovals = []
    for (i, arg_outer) in enumerate(modfn.args)
        inner_args = []
        for(j, arg_inner) in enumerate(arg_outer.args)
            if contains(string(arg_inner), "@observed")
                mrg_expr, onam_ij, oval_ij = eval(arg_inner)
                onames = vcat(onames, onam_ij)
                ovals = vcat(ovals, oval_ij)
                # We will rebuild the observed expressions in the observed output function, later.
                deleteat!(arg_outer.args,j)
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
    return modfn, onames, ovals
end
            













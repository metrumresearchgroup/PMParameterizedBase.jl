using ComponentArrays
using Base

Base.@kwdef mutable struct MRGModel
    parameters::ComponentVector{Float64} = ComponentVector{Float64}()
    ICs::ComponentVector{Float64} = ComponentVector{Float64}()
    tspan::Tuple = (0.0, 1.0)
    model = missing
    model_raw = missing
end


macro mrparam(p)
    pnam = string(p.args[1])
    nm = p.args[1]
    if hasproperty(modmrg.parameters, p.args[1])
        pval = getproperty(p,p.args[1])
    else
        pval = p.args[2]
        tmpCA = ComponentArray(; zip([nm],[pval])...)
        modmrg.parameters = vcat(modmrg.parameters,tmpCA)
        # modmrg.parameters = eval(:(ComponentArray($(nm) = $(pval))))
        # setproperty!(modmrg.parameters,nm,pval)
    end
    pval = string(pval)
    return quote
        string($(esc(pnam))," = ", $(pvec),".",$(esc(pnam)))
    end

end


macro model(md)
    eval(:(modmrg = MRGModel()))
    modfn = md
    pvec_sym = string(modfn.args[1].args[4])
    eval(:(pvec = $pvec_sym))
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrparam")
                mrg_expr = eval(arg_inner)
                push!(inner_args,Meta.parse(mrg_expr))
            elseif startswith(string(arg_inner),"#=")
                mrg_expr_split = split(string(arg_inner),  r"(#=.*=#)")
                if mrg_expr_split[2] != ""
                    mrg_expr = strip(mrg_expr_split[2])
                    push!(inner_args,Meta.parse(mrg_expr))
                end
            end
            j = j + 1
        end

        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
        i = i + 1
    end
    modmrg.model = eval(modfn)
    modmrg.model_raw = modfn
    return modmrg
end

function params!(model::MRGModel, params::ComponentArray)
    for k in keys(params)
        if hasproperty(model.parameters, k)
            setproperty!(model.parameters, k, getproperty(params, k))
        else
            error("Parameter ", string(k), " not defined in the model")
        end
    end
end

function params(model::MRGModel, params::ComponentArray)
    mdl_copy = deepcopy(model)
    for k in keys(params)
        if hasproperty(mdl_copy.parameters, k)
            setproperty!(mdl_copy.parameters, k, getproperty(params, k))
        else
            error("Parameter ", string(k), " not defined in the model")
        end
    end
    return mdl_copy
end
            
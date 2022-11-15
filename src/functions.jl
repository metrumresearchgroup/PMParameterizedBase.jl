using ComponentArrays
using Base

Base.@kwdef mutable struct MRGModel
    parameters::ComponentVector{Float64} = ComponentVector{Float64}()
    ICs::ComponentVector{Float64} = ComponentVector{Float64}()
    tspan::Tuple = (0.0, 1.0)
    model = missing
    model_raw = missing
end

macro mrparam(pin)
    parray = []
    if pin.head == :block
        parray = pin.args
    elseif pin.head == :(=)
        parray = [pin]
    else
        error("Unrecognized parameter definition")
    end
    qts = quote
          end
    for p in parray
        if typeof(p) != LineNumberNode
            pnam = string(p.args[1])
            nm = p.args[1]
            if hasproperty(modmrg.parameters, p.args[1])
                pval = getproperty(p,p.args[1])
            else
                pval = p.args[2]
                tmpCA = ComponentArray(; zip([nm],[pval])...)
                modmrg.parameters = vcat(modmrg.parameters,tmpCA)
            end
            pval = string(pval)
            qt = quote
                    string($(esc(pnam))," = ", $(pvec),".",$(esc(pnam)))
                end
            push!(qts.args,qt)
        else
            push!(qts.args,p)
        end
    end
        return qts
end



macro model(md)
    eval(:(modmrg = MRGModel()))
    modfn = md
    # Grab parameter name checking for inline or not...
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
    pvec_sym = string(modfn.args[1].args[pPos])
    eval(:(pvec = $pvec_sym))
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrparam")
                mrg_expr = eval(arg_inner)
                push!(inner_args,Meta.parse(mrg_expr))
            else
                push!(inner_args,arg_inner)
            end
            j = j + 1
        end

        if length(inner_args)>0
            modfn.args[i].args = inner_args
        end
        i = i + 1
    end
    # Need this nonsense to create function in unique namespace. Probably a much better and safer way to do this, but it works for now.
    fn = eval(:(() ->  eval($modfn)))
    modmrg.model = eval(:($fn()))
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
            
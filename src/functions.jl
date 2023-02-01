using ComponentArrays
using Base
using PMxSim

Base.@kwdef mutable struct MRGModel
    parameters::ComponentVector{Float64} = ComponentVector{Float64}()
    states::ComponentVector{Float64} = ComponentVector{Float64}()
    tspan::Tuple = (0.0, 1.0)
    model::Function = () -> ()
    model_raw::Expr = quote end
end
include("checks.jl")
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
    qtsv = []
    for p in parray

        if typeof(p) != LineNumberNode
            pnam = p.args[1]
            if hasproperty(modmrg.parameters, p.args[1])
                pval = p.args[2]
                eval(:(modmrg.parameters.$pnam = $pval))
                @warn "Parameter(s) $pnam defined multiple times, using last value"
            else
                pval = p.args[2]
                tmpCA = ComponentArray(; zip([pnam],[pval])...)
                modmrg.parameters = vcat(modmrg.parameters,tmpCA)
                pval = string(pval)
                qt = :($pnam = $pmxsym.$pnam)
                push!(qtsv, qt)
            end
        else
            push!(qtsv, p)
        end
    end
        return qtsv
end


macro mrstate(sin)
    sarray = []
    if sin.head == :block
        sarray = sin.args
    elseif sin.head == :(=)
        sarray = [sin]
    else
        error("Unrecognized state definition")
    end
    qts = quote
          end
    qtsv = []
    for s in sarray
        if typeof(s) != LineNumberNode
            snam = s.args[1]

            if hasproperty(modmrg.states, s.args[1])
                sval = s.args[2]
                eval(:(modmrg.states.$snam = $sval))
                @warn "State(s) $snam defined multiple times, using last value for initial condition"
            else
                sval = s.args[2]
                tmpCA = ComponentArray(; zip([snam],[sval])...)
                modmrg.states = vcat(modmrg.states,tmpCA)
                pval = string(sval)
                qt = :($snam = $(pmxsyms).$snam)
                push!(qtsv, qt)
            end
        else
            push!(qtsv, s)
        end
    end
        return qtsv
end


function parse_parameters(modfn, modmrg)
    modmrg = modmrg
    # Grab parameter names checking for inline or not...
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
    pvec_sym_tmp = String(modfn.args[1].args[pPos])
    eval(:(pmxsym = Symbol($pvec_sym_tmp)))
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrparam")
                mrg_expr = eval(arg_inner)
                qts = quote
                end
                for ex in mrg_expr
                    push!(qts.args,ex)
                    push!(inner_args, ex)

                end
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
    return modfn
end

function parse_states(modfn, modmrg)
    modmrg = modmrg
    # Grab parameter names checking for inline or not...
    numArgs = 0
    sPos = 0
    if modfn.args[1].head == :call # Check if there is a function name or anonymous function and get position of "u"
        numArgs = length(modfn.args[1].args[2:end])
        sPos = 3
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        sPos = 2
    else
        error("Unknown argument error")
    end
    svec_sym_tmp = String(modfn.args[1].args[sPos]) # Grab "u" argument from determined "u" position
    eval(:(pmxsyms = Symbol($svec_sym_tmp)))
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrstate") # Check for code defining states
                mrg_expr = eval(arg_inner)
                qts = quote
                end
                for ex in mrg_expr
                    push!(qts.args,ex)
                    push!(inner_args, ex)

                end
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
    return modfn
end


macro model(md)
    eval(:(modmrg = MRGModel()))
    modfn = md
    
    modfn = parse_parameters(modfn, modmrg)
    modfn = parse_states(modfn, modmrg)


    # Need this nonsense to create function in unique namespace. Probably a much better and safer way to do this, but it works for now.
    fn = eval(:(() ->  eval($modfn)))
    modmrg.model = eval(:($fn()))
    modmrg.model_raw = modfn
    # rete = checkAll(modmrg)
    checkAll(modmrg)
    # if rete != ""
        # return :(throw(ErrorException($rete)))
    # else
        return modmrg
    # end
end

function params!(model::MRGModel, params::ComponentArray)
    for k in keys(params)
        if hasproperty(model.parameters, k)
            setproperty!(model.parameters, k, getproperty(params, k))
        else
            error("Parameter(s) ", string(k), " not defined in the model")
        end
    end
end

function params(model::MRGModel, params::ComponentArray)
    mdl_copy = deepcopy(model)
    for k in keys(params)
        if hasproperty(mdl_copy.parameters, k)
            setproperty!(mdl_copy.parameters, k, getproperty(params, k))
        else
            error("Parameter(s) ", string(k), " not defined in the model")
        end
    end
    return mdl_copy
end
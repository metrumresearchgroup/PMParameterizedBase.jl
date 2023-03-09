using ComponentArrays
using Base
using PMxSim
include("MRGModel.jl")
include("checks.jl")
include("interim_eval.jl")
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
                sval = eval(s.args[2])
                tmpCA = ComponentArray(; zip([snam],[sval])...)
                modmrg.states = vcat(modmrg.states,tmpCA)
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
    is_inplace = du_inplace(modfn)
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
    if !is_inplace
        pPos = pPos - 1
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
                for ex in mrg_expr
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
    is_inplace = du_inplace(modfn)
    # Grab parameter names checking for inline or not...
    numArgs = 0
    sPos = 0
    pPos = 0
    if modfn.args[1].head == :call # Check if there is a function name or anonymous function and get position of "u"
        numArgs = length(modfn.args[1].args[2:end])
        sPos = 3
        pPos = 4
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        sPos = 2
        pPos = 3
    else
        error("Unknown argument error")
    end
    if !is_inplace
        sPos = sPos - 1
        pPos = pPos - 1
    end

    svec_sym_tmp = String(modfn.args[1].args[sPos]) # Grab "u" argument from determined "u" position
    eval(:(pmxsyms = Symbol($svec_sym_tmp)))
    
    i = 1
    # Need to evalulate everything that is not a state or derivative definition so derived ICs can be calculated. 
    pvec_sym_tmp = String(modfn.args[1].args[pPos])
    eval(:(pmxsym = Symbol($pvec_sym_tmp)))
    algebraic_modfn = get_algebraic(modfn)
    algebraic_modfn = MacroTools.striplines(algebraic_modfn)
    esc(eval(:($pmxsym = modmrg.parameters)))
    for algebraic_expr in algebraic_modfn.args[1]
        eval(algebraic_expr)
    end
    IC_expressions = :()
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        for arg_inner in arg_outer.args
            if contains(string(arg_inner), "@mrstate") # Check for code defining states
                mrg_expr = eval(arg_inner)
                push!(IC_expressions.args, MacroTools.striplines(arg_inner.args[3]))
                for ex in mrg_expr
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
    return (modfn,IC_expressions,algebraic_modfn, pmxsym, pmxsyms)
end

function parse_derivatives(modfn, modmrg)
    eval(:(var"#_input" = ComponentArray()))
    modmrg = modmrg
    is_inplace = du_inplace(modfn)
    # Grab parameter names checking for inline or not...
    numArgs = 0
    duPos = 0
    if modfn.args[1].head == :call # Check if there is a function name or anonymous function and get position of "du"
        numArgs = length(modfn.args[1].args[2:end])
        duPos = 2
    elseif modfn.args[1].head == :tuple
        numArgs = length(modfn.args[1].args)
        duPos = 1
    else
        error("Unknown argument error")
    end

    if is_inplace
        duvec_sym_tmp = String(modfn.args[1].args[duPos]) # Grab "du" argument from determined "du" position
    else
        duvec_sym_tmp = String("D")
    end
    # duvec_sym_tmp = string(duvec_sym_tmp,".")
    duvec_sym_tmp = string(duvec_sym_tmp)

    eval(:(pmxsymd = Symbol($duvec_sym_tmp)))
    i = 1
    for arg_outer in modfn.args
        j = 1
        inner_args = []
        state = Symbol()
        if arg_outer.head != :call
            for arg_inner in arg_outer.args
                if contains(string(arg_inner), "@ddt") # Check for code defining derivatives
                    mrg_expr = eval(arg_inner)
                    state = mrg_expr.args[1]
                    for ex in mrg_expr
                        push!(inner_args, ex)
                    end
                elseif startswith(string(arg_inner), string(pmxsymd))
                    mrg_expr = arg_inner
                    deriv = string(mrg_expr.args[1])
                    state = Symbol(split(deriv,".")[2])
                    if mrg_expr.head != :(=)
                        error("No RHS provided for $deriv")
                    end
                    rhs = mrg_expr.args[2]
                    eval(:(var"#_input" = ComponentArray(var"#_input", $state = 0.0)))
                    rhs = Expr(:call, :+, rhs, :(var"#_input".$state))
                    lhs = string(pmxsymd,".",state)
                    expr_out = Meta.parse(string(lhs," = ",string(rhs)))
                    push!(inner_args,expr_out)
                else
                    push!(inner_args,arg_inner)
                end
                j = j + 1
            end

            if length(inner_args)>0
                modfn.args[i].args = inner_args
            end
        end
            i = i + 1
        end
    return modfn, pmxsymd
end


macro model(md)

    eval(:(modmrg = MRGModel()))
    modmrg.original = MacroTools.striplines(md)
    modfn = md
    modmrg.raw = md
    modfn = parse_parameters(modfn, modmrg)
    ICEXPR = :()
    ICMAIN = :()
    parameter_symbol = :params
    state_symbol = :u
    deriv_symbol = :du
    modfn, deriv_symbol = parse_derivatives(modfn, modmrg)
    modfn, ICEXPR, ICMAIN, parameter_symbol, state_symbol = parse_states(modfn, modmrg)

    # Need this nonsense to create function in unique namespace. Probably a much better and safer way to do this, but it works for now.
    fn = eval(:(() ->  eval($modfn)))
    ftmp = eval(:($fn()))
    modelrepr = MRGModelRepr(ftmp, ComponentArray(a = 2.0), Dict(:A => :B), true, ICEXPR, ICMAIN, parameter_symbol, state_symbol, deriv_symbol)
    modmrg.model = modelrepr
    checkAll(modmrg)
    return modmrg
end

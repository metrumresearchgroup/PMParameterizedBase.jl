using PMxSim
using Base
using ComponentArrays

Base.@kwdef struct MRGModelRepr
    f::Function = () -> ()
    continuousInputs::ComponentVector{Float64} = ComponentVector{Float64}()
    inplace::Bool = true
    ICfcn::Function = () -> ()
    __parameter_symbol::Symbol = Symbol()
    __state_symbol::Symbol = Symbol()
    __deriv_symbol::Symbol = Symbol()
    __input_symbol::Symbol = Symbol()
end

Base.@kwdef mutable struct MRGModel
    parameters::ComponentVector{Float64} = ComponentVector{Float64}()
    states::ComponentVector{Float64} = ComponentVector{Float64}()
    tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
    parsed::Expr = quote end
    original::Expr = quote end
    raw::Expr = quote end
end


macro model(md)
    modfn = copy(md)

    ## Parse Parameters
    modfn, pvec_symbol, pnames, pvals = parse_parameters(modfn)  
    parameter_repeat(pnames)
    parameter_vec_rename(pnames, pvec_symbol)
    modfn = MacroTools.postwalk(modfn) do ex 
        ex == psym ? pvec_symbol : ex
    end
    pCA = assembleParamArray(pnames, pvals)

    ## Parse States
    modfn, uvec_symbol, snames, svals = parse_states(modfn)
    variable_repeat(snames)

    variable_parameter_overlap(pnames, snames, pvec_symbol, uvec_symbol)


    ## Parse Derivatives
    modfn, dvec_symbol, dnames, dvals = parse_derivatives(modfn)

    # Replace internal symbol with model symbol for states and derivatives
    modfn = MacroTools.postwalk(modfn) do ex 
        ex == usym ? uvec_symbol : ex
    end
    modfn = MacroTools.postwalk(modfn) do ex
        ex == dusym ? dvec_symbol : ex
    end
    derivative_repeat(dnames)


    # Need to add input vector to default arguments.
    ## First build the component aray with default rates of 0.0
    inputCA = assembleInputs(snames)
    mod_inplace,numkwargs = du_inplace(modfn)
    # Now add it to the function arguments as a kw arg with a default value, so there are no inputs, by default.
    for i in 1:lastindex(modfn.args)
        if modfn.args[i].head == :call
            if typeof(modfn.args[i].args[2]) != Symbol && modfn.args[i].args[2].head == :parameters
                push!(modfn.args[i].args[2].args, :($(Expr(:kw, inputsym, inputCA))))
            else
                arg2 = :($(Expr(:parameters, :($(Expr(:kw, inputsym, inputCA))))))
                # modfn.args[i].args = [modfn.args[i].args[1], arg2, modfn.args[i].args[2:end]...]
                insert!(modfn.args[i].args, 2, arg2)
            end
        end
    end



 
    algebraic = gather_algebraic(md)
    algebraic = buildAlgebraic(algebraic, pnames, snames, svals, psym)
    algebraic = MacroTools.postwalk(algebraic) do ex
        ex == psym ? pvec_symbol : ex
    end



    psym_out = quote $(Expr(:quote, pvec_symbol)) end
    usym_out = quote $(Expr(:quote, uvec_symbol)) end
    dusym_out = quote $(Expr(:quote, dvec_symbol)) end
    isym_out = quote $(Expr(:quote, inputsym)) end
    mdl = :(MRGModelRepr($modfn, $inputCA, $mod_inplace, $algebraic, $psym_out, $usym_out, $dusym_out, $isym_out))


    modRaw = quote $(Expr(:quote, modfn)) end
    modExpr_stripped = MacroTools.striplines(modfn)
    modExpr = quote $(Expr(:quote, modExpr_stripped)) end
    modOrig = quote $(Expr(:quote, md)) end


    modmrg = :(MRGModel($pCA, $algebraic($pCA), (0.0, 1.0), $mdl, $modExpr, $modOrig, $modRaw))

    return modmrg
end

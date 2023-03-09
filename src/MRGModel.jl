using PMxSim
using Base
using ComponentArrays

Base.@kwdef struct MRGModelRepr
    f::Function = () -> ()
#     # state_inputs::ComponentVector{Float64} = ComponentVector{Float64}()
#     state_inputs = nothing
#     input_map::Dict{Symbol, Symbol} = Dict{Symbol, Symbol}()
#     inplace::Bool = true
    ICfcn::Function = () -> ()
#     __parameter_symbol::Symbol = Symbol()
#     __state_symbol::Symbol = Symbol()
#     __deriv_symbol::Symbol = Symbol()
end

Base.@kwdef mutable struct MRGModel
    parameters
    states
    tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
    # parsed::Expr = quote end
    # original::Expr = quote end
    # raw::Expr = quote end
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
    modfn = MacroTools.postwalk(modfn) do ex 
        ex == usym ? uvec_symbol : ex
    end
    variable_parameter_overlap(pnames, snames, pvec_symbol, uvec_symbol)


    ## Parse Derivatives
    modfn, dvec_symbol, dnames, dvals = parse_derivatives(modfn)
    modfn = MacroTools.postwalk(modfn) do ex
        ex == dusym ? dvec_symbol : ex
    end
    derivative_repeat(dnames)

 
    algebraic = gather_algebraic(md)
    algebraic = buildAlgebraic(algebraic, pnames, snames, svals, psym)

    algebraic = MacroTools.postwalk(algebraic) do ex
        ex == psym ? pvec_symbol : ex
    end
    # mdl = :(MRGModelRepr(()->(), ComponentVector(), Dict(:A => :B), true, $algebraic, $pvec_symbol, $uvec_symbol, $dvec_symbol))
    mdl = :(MRGModelRepr($modfn, $algebraic))
    modmrg = :(MRGModel($pCA, $algebraic($pCA), (0.0, 1.0), $mdl))


return modmrg
end

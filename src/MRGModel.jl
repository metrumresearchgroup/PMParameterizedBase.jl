using PMxSim
using Base
using ComponentArrays

Base.@kwdef struct MRGModelRepr
#     f::Function = () -> ()
#     continuousInputs::ComponentArray{Float64} = ComponentArray{Float64}()
#     inplace::Bool = true
      Pfcn::Function = () -> ()
#     ICfcn::Function = () -> ()
#     Obsfcn::Function = () -> ()
#     __ICheader::Expr = :()
#     __parameter_symbol::Symbol = Symbol()
#     __state_symbol::Symbol = Symbol()
#     __deriv_symbol::Symbol = Symbol()
#     __input_symbol::Symbol = Symbol()
end


CAorFcn = Union{ComponentArray{Float64}, Function}
Base.@kwdef mutable struct MRGModel
    parameters::ComponentArray{Float64} = ComponentArray{Float64}()
    # states::CAorFcn = ComponentArray{Float64}()
    # tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
    # parsed::Expr = quote end
    # original::Expr = quote end
    # raw::Expr = quote end
end


macro model(md)
    # Parse parametesr
    psym, pnames, pvals, pfcn = parseParameters(md)
    mdl = :(MRGModelRepr($pfcn))

    modmrg = :(MRGModel($pfcn(), mdl))
end


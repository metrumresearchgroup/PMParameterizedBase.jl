using PMxSim
using Base
using ComponentArrays


Base.@kwdef struct MRGModelRepr
    f::Function = () -> ()
    state_inputs::ComponentVector{Float64} = ComponentVector{Float64}()
    input_map::Dict{Symbol, Symbol} = Dict{Symbol, Symbol}()
    inplace::Bool = true
end

Base.@kwdef mutable struct MRGModel
    parameters::ComponentVector{Float64} = ComponentVector{Float64}()
    states::ComponentVector{Float64} = ComponentVector{Float64}()
    tspan::Tuple = (0.0, 1.0)
    model::MRGModelRepr = MRGModelRepr()
    parsed::Expr = quote end
    original::Expr = quote end
    raw::Expr = quote end
    _internals = nothing
end
module ParameterizedModels
using MacroTools

include("helpers.jl")
include("MRGModel.jl")
include("accessors.jl")
include("modelingTools.jl")
# include("ParseAlgebraic.jl")
# include("helpers.jl")


model_warnings = true

export @model
export getUnit
export getDescription
export getDefault
export getDefaultExpr
export getExpr
# using ModelingTookit.@variables

# function solve(model::MRGModel, alg::Union{DEAlgorithm,Nothing}=nothing; kwargs...)
    # odefunc = DifferentialEquations.ODEFunction(model; syms = keys(model.states))

# function solve(model::MRGModel, alg::Union{DEAlgorithm,Nothing}=nothing; kwargs...)
    # odefunc = DifferentialEquations.ODEFunction(model; syms = keys(model.states), indepsym = :t, paramsyms = keys(model.parameters))
#     problem = ODEProblem(odefunc, model.states, model.tspan, model.parameters)
#     sol = DifferentialEquations.solve(problem, alg; kwargs...)
#     return sol
# end




# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

## Submodules to Hold some sort of 


end

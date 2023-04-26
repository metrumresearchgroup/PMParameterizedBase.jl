module ParameterizedModels
using MacroTools
using ComponentArrays
using DifferentialEquations

# Write your package code here.

include("MRGModel.jl")
include("parseHeader.jl")
include("parseInit.jl")
include("parseBody.jl")
include("initParsingFunctions.jl")
include("bodyParsingFunctions.jl")
include("parsingFunctions.jl")
include("assemblyFunctions.jl")
include("defChecks.jl")
include("checkOverlap.jl")
include("accessors.jl")
include("checkBody.jl")
include("checks.jl")

macro parameter(min)
    return esc(min)
end

macro init(min)
    return esc(min)
end

macro IC(min)
    return esc(min)
end

macro ddt(min)
    return esc(min)
end

macro repeated(min)
    return esc(min)
end

macro constant(min)
    return esc(constant)
end

model_warnings = true

export @model
export @parameter
export @init
export @variable
export @repeated
export @IC
export @ddt
export ComponentArray

function solve(model::MRGModel, alg::Union{DEAlgorithm,Nothing}=nothing; kwargs...)
    odefunc = DifferentialEquations.ODEFunction(model; syms = keys(model.states), indepsym = :t, paramsyms = keys(model.parameters))
    problem = ODEProblem(odefunc, model.states, model.tspan, model.parameters)
    sol = DifferentialEquations.solve(problem, alg; kwargs...)
    return sol
end




# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

## Submodules to Hold some sort of 


end

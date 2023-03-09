module PMxSim

# Write your package code here.
export @model
export @mrparam
export @mrstate
export params!
export params
export show_parsed
include("MRGModel.jl")
include("parsing_functions.jl")
include("checks.jl")
include("parsing_macros.jl")
include("assembly_fcns.jl")

# include("accessors.jl")
# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

end

module PMxSim

# Write your package code here.
export @model
export @mrparam
# export params!
# export params
export get_origin
include("functions.jl")
include("accessors.jl")
Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model_raw),")")

end

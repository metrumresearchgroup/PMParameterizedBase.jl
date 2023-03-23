module PMxSim
using MacroTools
using ComponentArrays

# Write your package code here.

# export @mrstate
# export params!
# export params
# export show_parsed

# include("parseStatic.jl")
include("parseInit.jl")
include("MRGModel.jl")
include("parseHeader.jl")
include("checks.jl")
include("accessors.jl")

macro parameter(min)
    return esc(min)
end


export @model
export @parameter
export ComponentArray



# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

end

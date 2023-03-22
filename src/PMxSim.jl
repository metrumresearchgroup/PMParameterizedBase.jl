module PMxSim
using MacroTools
using ComponentArrays

# Write your package code here.

# export @mrstate
# export params!
# export params
# export show_parsed

include("parseParameters.jl")
include("MRGModel.jl")
include("parseHeader.jl")
include("checks.jl")
include("accessors.jl")
macro mrparam(min)
    return esc(min)
end

export @model
export @mrparam
export ComponentArray



# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

end

module PMxSim
using MacroTools

# Write your package code here.
export @model
export @mrparam
# export @mrstate
# export params!
# export params
# export show_parsed

include("parseParameters.jl")
include("MRGModel.jl")
macro mrparam(min)
    return min
end



# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

end

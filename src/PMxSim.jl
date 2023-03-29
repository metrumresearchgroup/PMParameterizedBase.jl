module PMxSim
using MacroTools
using ComponentArrays

# Write your package code here.

# export @mrstate
# export params!
# export params
# export show_parsed

# include("parseStatic.jl")
include("MRGModel.jl")
include("parseHeader.jl")
include("parseInit.jl")
include("parseBody.jl")
include("parsingFunctions.jl")
include("walkParams.jl")
include("walkVariables.jl")
include("assemblyFunctions.jl")
include("checks.jl")
include("accessors.jl")

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

macro dynamic(min)
    return esc(min)
end

macro repeated(min)
    return esc(min)
end



export @model
export @parameter
export @init
export @variable
export ComponentArray



# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

end

module PMxSim

# Write your package code here.
export @model
export @mrparam
export @mrstate
export params!
export params
export show_parsed


# Create a bunch of unique variable names within the module namespace to reference derivatives, states, parameters, and time
# These will later be replaced with the correct symbols from the code using MacroTools.postwalk
# As of right now, "tsym" for time is unused.
usym = gensym()
dusym = gensym()
psym = gensym()
tsym = gensym()

# Create a unique variable for continuous inputs
inputsym = gensym(:input)



include("MRGModel.jl")
include("parsing_functions.jl")
include("checks.jl")
include("parsing_macros.jl")
include("assembly_fcns.jl")
include("accessors.jl")





# Base.show(io::IO, mdl::MRGModel) = print(io, typeof(mdl), ", ", mdl.parameters, ", ", mdl.states, " ",  mdl.tspan, ", ", mdl.model, ", ", MacroTools.striplines(mdl.model),")")

end

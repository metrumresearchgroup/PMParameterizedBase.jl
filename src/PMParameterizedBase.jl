module PMParameterizedBase
using MacroTools
using SciMLBase: remake
abstract type AbstractPMSolution end # Create an abstract type to hold solutions in place
# Create a dummy solution subtype at some point.


include("PMModels.jl")

include("getproperties.jl")
include("setproperties.jl")
include("accessors.jl")
include("propertynames.jl")
include("helpers.jl")
include("setindices.jl")


model_warnings = true

export @model
export getUnit
export getDescription
export getDefault
export getDefaultExpr
export getExpr
export ModelingToolkit
export Symbolics
export values
export names




end

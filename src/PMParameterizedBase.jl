module PMParameterizedBase
using MacroTools
using SciMLBase: remake
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




end

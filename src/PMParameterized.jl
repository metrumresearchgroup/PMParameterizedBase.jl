module PMParameterized
using MacroTools

include("PMModels.jl")
include("modelingTools.jl")
include("getproperties.jl")
include("getindexes.jl")
include("setproperties.jl")
include("accessors.jl")
include("propertynames.jl")
include("helpers.jl")


model_warnings = true

export @model
export getUnit
export getDescription
export getDefault
export getDefaultExpr
export getExpr



end

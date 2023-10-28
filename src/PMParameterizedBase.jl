module PMParameterizedBase
using MacroTools
using SciMLBase: remake
using StaticArrays
import Base: values
import Base: names
using ModelingToolkit
using Symbolics
import Symbolics: VariableSource
import ModelingToolkit; getmetadata
import Unitful: @u_str
import Base: ImmutableDict

abstract type AbstractPMSolution end # Create an abstract type to hold solutions in place
# Create a dummy solution subtype at some point.


include("PMModels.jl")
ModelValues = Union{Parameters,Variables}

include("mapping.jl")
include("helpers.jl")
include("propertynames.jl")
include("getproperties.jl")
include("setproperties.jl")
include("accessors.jl")
include("setindices.jl")
include("getindices.jl")


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

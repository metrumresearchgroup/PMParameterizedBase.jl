module PMParameterizedBase
using MacroTools
import SciMLBase: remake
import SciMLBase: AbstractODESolution
using StaticArrays
import Base: values
import Base: names
using ModelingToolkit
using Symbolics
import Symbolics: VariableSource
import ModelingToolkit; getmetadata
import Unitful: @u_str
import Base: ImmutableDict

abstract type PMEvent end # Create an abstract array type for events
abstract type AbstractPMSolution end # Create an abstract type to hold solutions in place



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
export getModelIndex




end

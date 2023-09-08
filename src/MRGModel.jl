using ParameterizedModels
using ModelingToolkit
using Symbolics
using Unitful
import Unitful.@u_str



# Add location metadata type to variables
## This will let us specify a file to look in for variable/parameter values
struct VariableLoc end
Symbolics.option_to_metadata_type(::Val{:location}) = VariableLoc


Base.@kwdef mutable struct MRGModel
    parameters#::Vector{Num}
    states#::Vector{Num}
    independent_variables#::Vector{Num}
    ICs#::Vector{Pair{Num, Float64}}
    tspan::Tuple = (0.0, 1.0)
    model::ModelingToolkit.AbstractSystem
end


Base.@kwdef mutable struct MdlBlock
    names::Vector{Symbol} = Vector{Symbol}()
    Block::Expr = Expr(:block)
    LNN::LineNumberNode = LineNumberNode(0)
    LNNVector::Vector{LineNumberNode} = Vector{LineNumberNode}()
    type::Symbol = Symbol()
end


Base.@kwdef mutable struct WarnBlock
    LNN::LineNumberNode = LineNumberNode(0)
    LNNVector::Vector{LineNumberNode} = Vector{LineNumberNode}()
    defTypeDict::Dict{String,String} = Dict{String, String}()
    prev::Union{String,Nothing} = ""
end



macro model(Name, MdlEx)#, DerivativeSymbol, DefaultIndependentVariable, MdlEx, AdditionalIndepVars... = nothing)
    outexpr = quote # Create a quote to return our output expression
    # Create an empty array to hold all parameters
    pars = Vector{Num}(undef, 0)
    # Create an empty array to hold all variables 
    # vars = Vector{Num}(undef, 0)
    vars = []
    # Create an empty array to hold the independent variables
    ivs = Vector{Num}(undef, 0)
    # Create an empty array to hold boundary conditions for PDESystems
    bcs = Vector{Num}(undef, 0)
    # Create an empty array to hold domains for PDESystems
    domain = Vector{Num}(undef, 0)
    # Create an empty MRGModel object to hold our parameters, states, IVs, etc. 
    ModelingToolkit.@parameters t
    mdl = MRGModel(
        # parameters = Vector{Num}(undef, 0),
        parameters = [],
        # states = Vector{Num}(undef, 0),
        states = [],
        # ICs = Vector{Pair{Num, Float64}}(undef, 0),
        ICs = [],
        independent_variables = Vector{Num}(undef,0),
        tspan = (0.0, 1.0),
        model = @named $Name = ODESystem([],t)
    )

    eqs = Vector{Equation}(undef, 0)
    # Grab everything within the @model block and run it to populate mdl block, expand other macros etc. 
    $MdlEx


    if length(ivs) == 1
        @named $Name = ODESystem(eqs, ivs[1], vars, pars, tspan=(0.0, 1.0))
    else
        # if length($bcs) == 0
            # error("Need to define boundary conditions for PDEs")
        # end
        # if length($domain) == 0
            # error("Need to define variable domain(s) for PDEs")
        # end
        @named $Name = PDESystem(eqs, [], [], ivs, vars, pars)
    end

    mdl.model = $Name # Return the model 
    mdl
    end

    return outexpr
end

"""
Macro to define independent variables
# Examples
```jldoctest
julia> @IVs x y z
3-element Vector{Num}:
 x
 y
 z
```
"""
macro IVs(ivs_in...)
    ptmp = Symbolics._parse_vars(:parameters,
        Real,
        ivs_in,
        ModelingToolkit.toparam) |> esc
    quote
        append!(mdl.independent_variables, $ptmp)
        append!(ivs, $ptmp)
    end
end

macro parameters(ps...)
    out = Symbolics._parse_vars(:parameters,
    Real,
    ps,
    ModelingToolkit.toparam) |> esc
    quote 
        append!(mdl.parameters, $out)
        append!(pars, $out)
    end
end

macro variables(xs...)
    out = esc(ModelingToolkit._parse_vars(:variables, Real, xs))
    quote
        append!(mdl.states, $out)
        append!(vars, $out)
    end
end

macro eq(formula)
    quote
    push!(eqs, $formula)
    end
end
    



 



using ParameterizedModels
using ModelingToolkit
using Symbolics




Base.@kwdef mutable struct MRGModel
    parameters::Vector{Num}
    states::Vector{Num}
    independent_variables::Vector{Num}
    ICs::Vector{Pair{Num, Float64}}
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
    vars = Vector{Num}(undef, 0)
    # Create an empty array to hold the independent variables
    ivs = Vector{Num}(undef, 0)
    # Create an empty array to hold boundary conditions for PDESystems
    bcs = Vector{Num}(undef, 0)
    # Create an empty array to hold domains for PDESystems
    domain = Vector{Num}(undef, 0)
    # Create an empty MRGModel object to hold our parameters, states, IVs, etc. 
    ModelingToolkit.@parameters t
    mdl = MRGModel(
        parameters = Vector{Num}(undef, 0),
        states = Vector{Num}(undef, 0),
        ICs = Vector{Pair{Num, Float64}}(undef, 0),
        independent_variables = Vector{Num}(undef,0),
        tspan = (0.0, 1.0),
        model = @named $Name = ODESystem([],t)
    )

    eqs = Vector{Equation}(undef, 0)
    # Grab everything within the @model block and run it to populate mdl block, expand other macros etc. 
    $MdlEx

    # if length($ivs) == 1

    @named $Name = ODESystem(eqs, ivs[1], vars, pars, tspan=(0.0, 1.0))
    # else
        # if length($bcs) == 0
            # error("Need to define boundary conditions for PDEs")
        # end
        # if length($domain) == 0
            # error("Need to define variable domain(s) for PDEs")
        # end
        # @named $Name = PDESystem($eqs, $bcs, $domain, $ivs, $dvs, $pars)
    # end

    mdl.model = $Name # Return the model 
    mdl
    end

    return outexpr
end

"""
Macro to define additional independent variables
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


indeptupletype = Tuple{Real,Vararg{Num}} # Create a Tuple type for independent variables
indeptype = Union{Num, indeptupletype} # Create a union of Numeric and indeptupletype for the derivative macro
# macro D(indepvars::indeptype, formula)
macro D(indepvars, formula)
    type = :odesys
    if typeof(indepvars) == Symbol
        indepvars = [indepvars]
        type = :odesys
    elseif indepvars.head != :tuple
        error("Error in @D. Indepvariables must take the form of a parameter or tuple of parameters")
    elseif indepvars.head == :tuple
        type = :pdesys
    else
        error("Unknown error")
    end

    outex = if type == :odesys quote
            # Loop over variables and check to see if any derivative variables are in parameters instead of IVs
            for iv in $indepvars
                if Symbol(iv) in Symbol.(mdl.parameters)
                    error("Trying to differentiate with respect to parameter $iv. Please differentiate with respect to @IVs")
                elseif Symbol(iv) in Symbol.(mdl.states)
                    error("Trying to differentiate with respect to state $iv. Please differentiate with respect to @IVs")
                end
            end
            lhs = $formula.lhs
            rhs = $formula.rhs
            Doperator = Differential($(esc(indepvars[1])))
            push!(eqs, Doperator(lhs) ~ rhs)
            end
        elseif type == :pdesys quote
        # Loop over variables and check to see if any derivative variables are in parameters instead of IVs
        for iv in $indepvars
            if Symbol(iv) in Symbol.(mdl.parameters)
                error("Trying to differentiate with respect to parameter $iv. Please differentiate with respect to @IVs")
            elseif Symbol(iv) in Symbol.(mdl.states)
                error("Trying to differentiate with respect to state $iv. Please differentiate with respect to @IVs")
            end
        end
        lhs = $formula.lhs
        rhs = $formula.rhs
        Doperator = prod(Differential.($(esc(indepvars))))
        push!(eqs, Doperator(lhs) ~ rhs)
        end
    end
end



 



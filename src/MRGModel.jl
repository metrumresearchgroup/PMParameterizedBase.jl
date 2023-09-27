using ParameterizedModels
using ModelingToolkit
using Symbolics
# using DynamicQuantities
using ComponentArrays
import Unitful.@u_str
using Unitful



# Add location metadata type to variables
## This will let us specify a file to look in for variable/parameter values
struct VariableLoc end
Symbolics.option_to_metadata_type(::Val{:location}) = VariableLoc


Base.@kwdef mutable struct MRGModel
    # parameters#::MRGParamTuple
    states#::Vector{Num}
    independent_variables#::Vector{Num}
    ICs#::Vector{Pair{Num, Float64}}
    tspan::Tuple = (0.0, 1.0)
    parameters
    odeproblem
    observed
    observedNames
    model::ModelingToolkit.AbstractSystem
end

Base.@kwdef struct MRGVal
    name::Symbol
    value::Num
end

Base.@kwdef struct MRGParamList
    list::NamedTuple
    names
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
        # pars = Vector{Num}(undef, 0)
        # pars = [ComponentVector{Float64}()]
        pars = []
        mrgpars = MRGVal[]
    
        
        # Create an empty array to hold all variables 
        # vars = Vector{Num}(undef, 0)
        vars = []
        mrgvars = MRGVal[]

        # Create an empty array to hold all constants
        cons = []
        mrgcons = MRGVal[]

        # Create an empty array to hold all observed
        obs = []
        obsnames = []



        # Create an empty array to hold the independent variables
        ivs = Vector{Num}(undef, 0)
        # Create an empty array to hold boundary conditions for PDESystems
        bcs = Vector{Num}(undef, 0)
        # Create an empty array to hold domains for PDESystems
        domain = Vector{Num}(undef, 0)
        # Create an empty MRGModel object to hold our parameters, states, IVs, etc. 
        ModelingToolkit.@parameters t # NEED TO REMOVE THIS LATER

        mdl = MRGModel(
            # parameters = Vector{Num}(undef, 0),
            # parameters = [],
            # states = Vector{Num}(undef, 0),
            states = [],
            # ICs = Vector{Pair{Num, Float64}}(undef, 0),
            ICs = [],
            independent_variables = Vector{Num}(undef,0),
            tspan = (0.0, 1.0),
            parameters = NamedTuple{tuple(pars...)}(mrgpars),
            odeproblem = 2.0,
            observed = 2.0,
            observedNames = Symbol[],
            model = @named $Name = ODESystem([],t)
        )
        # println(mdl.pstruct.names)
        eqs = Vector{Equation}(undef, 0)

        # Grab everything within the @model block and run it to populate mdl block, expand other macros etc. 
        $MdlEx




        if length(ivs) == 1
            conspairs = [Pair(cons[i], mrgcons[i].value) for i in 1:lastindex(cons)]
            parpairs = [Pair(pars[i], mrgpars[i].value) for i in 1:lastindex(pars)]

            @named $Name = ODESystem(eqs, ivs[1], vars, vcat(pars, cons), tspan=(0.0, 1.0))
            prob = ODEProblem($Name,[], (0.0, 1.0), vcat(parpairs,conspairs))
            mdl.odeproblem = prob
            # [mg_to_g => 1E-3,
            # mol_to_nmol => 1E9,
            # ug_to_g => 1E-6,
            # mL_to_L => 1E-3,
            # um_to_cm => 1E-4,
            # day_to_h => 24,
            # cm3_to_mm3 => 1E3,
            # mm3_to_L => 1E-6])
        else
            # if length($bcs) == 0
                # error("Need to define boundary conditions for PDEs")
            # end
            # if length($domain) == 0
                # error("Need to define variable domain(s) for PDEs")
            # end
            conspairs = [Pair(cons[i], consvals[i]) for i in 1:lastindex(cons)]
            @named $Name = PDESystem(eqs, [], [], ivs, vars, vcat(pars,conspairs))
        end
        mdl.parameters = NamedTuple{tuple(Symbol.(pars)...)}(mrgpars)
        # mdl.observed = convert.(Num, obs)
        mdl.observedNames = obsnames


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
    out = esc(Symbolics._parse_vars(:parameters,
    Real,
    ps,
    ModelingToolkit.toparam))

    q_out = quote 
        for param in $out
            if !(ModelingToolkit.hasdefault(param))
                error("Parameter $param must have a default value")
            else
                ptmp = MRGVal(Symbol(param), ModelingToolkit.getdefault(param))
                push!(mrgpars, ptmp)
            end
        end
        append!(pars, $out)

    end
    return q_out
end

macro variables(xs...)
    out = esc(ModelingToolkit._parse_vars(:variables, Real, xs))
    q_out = quote
        for var in $out
            if !(ModelingToolkit.hasdefault(var))
                error("State $var must have an initial value")
            else
                vtmp = MRGVal(Symbol(var), ModelingToolkit.getdefault(var))
                push!(mrgvars, vtmp)
            end
        end
        append!(vars, $out)

    end
    return q_out
end

macro constants(cs...)
    out = Symbolics._parse_vars(:parameters,
                    Real,
                    cs,
                    ModelingToolkit.toparam) |> esc
    # out = esc(ModelingToolkit._parse_vars(:constants, Real, cs))
    q_out = quote
        for con in $out
            if !(ModelingToolkit.hasdefault(con))
                error("Constant $con must have a value")
            else
                ctmp = MRGVal(Symbol(con), ModelingToolkit.getdefault(con))
                push!(mrgcons, ctmp)
            end
        end
        append!(cons, $out)
    end
    return q_out
end


macro eq(formula)
    quote
        push!(eqs, $formula)
    end
end


function getObsName(ex)
    (@capture(ex, a_ = b_) || @capture(ex, a_ .= b_) || @capture(ex, @__dot__ a_ = b_))
    # println(Symbol(a))
    return Symbol(a)
end


macro observed(obsin)
    out = Symbolics._parse_vars(:parameters,
                    Real,
                    [obsin]) |> esc

    q_out = quote
        for observ in $out
                # otmp = MRGVal(Symbol(con), ModelingToolkit.getdefault(con))
                push!(obsnames, observ)
        end
        @observed2 $obsin
    end
    return q_out
end

macro observed2(obsin)
    # for expr in obsin
        MacroTools.postwalk(x -> (@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)) ? (x; quote $x; push!(obs, $a) end) : x, esc(obsin))
    # end
end
# # MacroTools.postwalk(x -> (@capture(x, a_ = b_) || @capture(x, a_ .= b_) || @capture(x, @__dot__ a_ = b_)) ? (quote push!(obsnames, @text_str $a); $x; push!(obs, $a) end) : x, esc(obsin))




    



 



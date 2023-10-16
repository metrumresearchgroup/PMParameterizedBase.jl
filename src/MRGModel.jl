using ParameterizedModels
using ModelingToolkit
using Symbolics
# using DynamicQuantities
using ComponentArrays
import Unitful.@u_str
using Unitful
using SciMLBase


# Add location metadata type to variables
## This will let us specify a file to look in for variable/parameter values
struct VariableLoc end
Symbolics.option_to_metadata_type(::Val{:location}) = VariableLoc


Base.@kwdef mutable struct NumValue <: Number
    name::Symbol
    value::Num
    _valmap::Dict{Num, Num}
    _uvalues::Dict{Num, Real}
    _defaultExpr::Num
end

Base.@kwdef mutable struct ModelValues <: Number
    names::Vector{Symbol}
    _values::Dict{Symbol, NumValue}
    _valmap::Dict{Num, Num}
    _uvalues::Dict{Num, Real}
    # _defaultExprs::Dict{Num, Num}
    # _puvalues::Dict{Num, Real}
    # _suvalues::Dict{Num, Real}
end


# Base.@kwdef mutable struct MRGStates <: Number

Base.@kwdef mutable struct MRGModel
    # parameters#::MRGParamTuple
    states::ModelValues
    independent_variables#::Vector{Num}
    ICs#::Vector{Pair{Num, Float64}}
    tspan::Tuple = (0.0, 1.0)
    parameters::ModelValues
    odeproblem
    observed
    observedNames
    # _puvalues::Dict{Num, Real}
    # _suvalues::Dict{Num, Real}
    _uvalues::Dict{Num, Real}
    model::ModelingToolkit.AbstractSystem

    # _valmap::Union{Dict{Num, Union{SymbolicUtils.BasicSymbolic{Real}, Number}}, Nothing} = nothing
end




Base.@kwdef mutable struct MRGConst
    name::Symbol
    value::Num
    # _val::Num
end


macro model(Name, MdlEx)#, DerivativeSymbol, DefaultIndependentVariable, MdlEx, AdditionalIndepVars... = nothing)
    outexpr = quote # Create a quote to return our output expression

        # Create an empty array to hold all parameters
        # pars = Vector{Num}(undef, 0)
        # pars = [ComponentVector{Float64}()]
        pars = NumValue[]
        # parvalues = Num[]
        # mrgpars = MRGVal[]
    
        
        # Create an empty array to hold all variables 
        # vars = Vector{Num}(undef, 0)
        vars = NumValue[]
        # varvalues = Num[]

        # Create an empty array to hold all constants
        cons = Num[]
        # consvalues = Real[]
        # mrgcons = MRGConst[]

        # Create an empty array to hold all observed
        obs = []
        obsnames = []



        # Create an empty array to hold the independent variables
        ivs = Num[]
        # Create an empty array to hold boundary conditions for PDESystems
        bcs = Num[]
        # Create an empty array to hold domains for PDESystems
        domain = Num[]
        # Create an empty MRGModel object to hold our parameters, states, IVs, etc.
        
        

        ModelingToolkit.@parameters t 
        mdl = MRGModel(
            states = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            ICs = [],
            independent_variables = Vector{Num}(undef,0),
            tspan = (0.0, 1.0),
            parameters = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            odeproblem = 2.0,
            observed = 2.0,
            observedNames = Symbol[],
            # _puvalues = Dict{Num, Real}(),
            # _suvalues = Dict{Num, Real}(),
            _uvalues = Dict{Num, Real}(),
            model = @named $Name = ODESystem([],t)
        )
        # println(mdl.pstruct.names)
        eqs = Vector{Equation}(undef, 0)

        # Grab everything within the @model block and run it to populate mdl block, expand other macros etc. 
        $MdlEx




        if length(ivs) == 1
            conspairs = [Pair(cons[i], 
                            ModelingToolkit.getdefault(cons[i])) for i in 1:lastindex(cons)]
            parpairs = [Pair(pars[i].value, 
                            ModelingToolkit.getdefault(pars[i].value)) for i in 1:lastindex(pars)]
            consparpairs = vcat(conspairs, parpairs)

            varspairs = [Pair(vars[i].value, ModelingToolkit.getdefault(vars[i].value)) for i in 1:lastindex(vars)]
            consin = [cons[i].val for i in 1:lastindex(cons)]
            parsin = [pars[i].value for i in 1:lastindex(pars)]
            varsin = [vars[i].value for i in 1:lastindex(vars)]
            @named $Name = ODESystem(eqs, ivs[1], varsin, vcat(parsin, consin), tspan=(0.0, 1.0))
            prob = ODEProblem($Name,[], (0.0, 1.0), consparpairs)
            mdl.odeproblem = prob
            mdl.parameters = ModelValues(names = [x.name for x in pars],
                                    _values = Dict(x.name => x for x in pars),
                                    _valmap = Dict(consparpairs),
                                    _uvalues = mdl._uvalues)

            mdl.states = ModelValues(names = [x.value.val.metadata[ModelingToolkit.VariableSource][2] for x in vars],
                                _values = Dict(x.name => x for x in vars),
                                _valmap = Dict(vcat(conspairs,parpairs,varspairs)),
                                _uvalues = mdl._uvalues)
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

        # mdl.parameters = NamedTuple{tuple(Symbol.(pars)...)}(mrgpars)
        # mdl.states = NamedTuple{tuple([var.val.metadata[ModelingToolkit.VariableSource][2] for var in vars]...)}(mrgvars)
        for pkey in keys(mdl.parameters._values)
            p = mdl.parameters._values[pkey]
            p._valmap = mdl.parameters._valmap
            p._uvalues = mdl._uvalues
            p._defaultExpr = mdl.parameters._values[pkey].value
        end
        for skey in keys(mdl.states._values)
            s = mdl.states._values[skey]
            s._valmap = mdl.states._valmap
            s._uvalues = mdl._uvalues
            s._defaultExpr = mdl.states._values[skey].value
        end
        mdl.observed = convert.(Num, obs)
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
                # ptmp = MRGVal(name = Symbol(param), value = param, _valmap = nothing)#, _val = param)
                ptmp = NumValue(name = Symbol(param), value = param, _valmap = Dict{Symbol, Num}(), _uvalues = Dict{Symbol, Real}(),_defaultExpr = Num(nothing))
                push!(pars, ptmp)
            end
        end
        # append!(pars, nameof.($out))

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
                # vtmp = MRGVal(name = var.val.metadata[ModelingToolkit.VariableSource][2], value = var, _valmap = nothing)#, _val = var)
                vtmp = NumValue(name = var.val.metadata[ModelingToolkit.VariableSource][2], value = var, _valmap = Dict{Symbol, Num}(), _uvalues = Dict{Symbol, Real}(),_defaultExpr = Num(nothing))
                push!(vars, vtmp)
            end
            # push!(vars, var.val.metadata[ModelingToolkit.VariableSource][2])
        end
        # append!(vars, [x.val.metadata[ModelingToolkit.VariableSource][2] for x in $out])

    end
    return q_out
end

macro constants(cs...)
    out = Symbolics._parse_vars(:parameters,
                    Real,
                    cs,
                    ModelingToolkit.toparam) |> esc
    q_out = quote
        for con in $out
            if !(ModelingToolkit.hasdefault(con))
                error("Constant $con must have a value")
            else
                # ctmp = MRGConst(name = Symbol(con), value = con)#, _val = con)
                push!(cons, con)
            end
        end
        # append!(cons, nameof.($out))
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
    out = ModelingToolkit._parse_vars(:parameters,
                    Real,
                    [obsin],
                    ModelingToolkit.toparam) |> esc

    q_out = quote
        for observ in $out
                push!(obsnames, observ)
                push!(obs, ModelingToolkit.getdefault(observ))
        end
        $obsin
    end
    return q_out
end




    
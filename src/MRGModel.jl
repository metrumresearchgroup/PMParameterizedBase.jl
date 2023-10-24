using PMParameterized
using ModelingToolkit
using Symbolics
import Unitful.@u_str
using Unitful
using SciMLBase


# Add location metadata type to variables
## This will let us specify a file to look in for variable/parameter values
struct VariableLoc end
struct IVDomain end
Symbolics.option_to_metadata_type(::Val{:location}) = VariableLoc
Symbolics.option_to_metadata_type(::Val{:domain}) = IVDomain
Symbolics.option_to_metadata_type(::Val{:tspan}) = IVDomain
Base.@kwdef mutable struct NumValue <: Number
    name::Symbol
    value::Num
    _valmap::Dict{Num, Num}
    _uvalues::Dict{Num, Number}
    _defaultExpr::Num
    _constant::Bool = false
end

Base.@kwdef mutable struct ModelValues <: Number
    names::Vector{Symbol}
    _values::Dict{Symbol, NumValue}
    _valmap::Dict{Num, Num}
    _uvalues::Dict{Num, Number}
end


Base.@kwdef struct MRGSolution
    _solution::ODESolution
    _states::ModelValues
    _parameters::ModelValues
    _constants::ModelValues
    _observed::ModelValues
    _names::Vector{Symbol}
end


Base.@kwdef mutable struct PMModel
    states::ModelValues
    independent_variables#::Vector{Num}
    ICs#::Vector{Pair{Num, Float64}}
    tspan::Tuple = (0.0, 1.0)
    parameters::ModelValues
    _sys::Union{ODESystem, PDESystem, Nothing}
    _odeproblem::ODEProblem
    observed::ModelValues
    _uvalues::Dict{Num, Number}
    _solution::Union{MRGSolution,Nothing}
    _constants::ModelValues
    _inputs::ModelValues
    model::ModelingToolkit.AbstractSystem
end




# Base.@kwdef mutable struct MRGConst
#     name::Symbol
#     value::Num
#     # _val::Num
# end




macro model(Name, MdlEx)#, DerivativeSymbol, DefaultIndependentVariable, MdlEx, AdditionalIndepVars... = nothing)
    Namegen = gensym(Name)
    outexpr = quote # Create a quote to return our output expression
        # Create an empty array to hold all parameters
        pars = NumValue[]
    
        # Create an empty array to hold all inputs
        iputs = NumValue[]

        # Create an empty array to hold all variables 
        vars = NumValue[]

        # Create an empty array to hold all constants
        cons = NumValue[]


        # Create an empty array to hold all observed
        obs = NumValue[]



        # Create an empty array to hold the independent variables
        ivs = Num[]
        # Create an empty array to hold boundary conditions for PDESystems
        bcs = Num[]
        # Create an empty array to hold domains for PDESystems
        domain = Num[]
        # Create an empty PMModel object to hold our parameters, states, IVs, etc.
        
        

        ModelingToolkit.@parameters t 
        mdl = PMModel(
            states = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            ICs = [],
            independent_variables = Vector{Num}(undef,0),
            tspan = (0.0, 1.0),
            parameters = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            _sys = nothing,
            _odeproblem = ODEProblem((du,u,p,t)->(nothing),(),(0.0,1.0),()),
            observed = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            _uvalues = Dict{Num, Real}(),
            _solution = nothing,
            _constants = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            _inputs = ModelValues(names = Symbol[], _values = Dict{Symbol,NumValue}(), _valmap = Dict{Num, Num}(), _uvalues = Dict{Num, Real}()),
            model = @named $Namegen = ODESystem([],t)
        )
        # Create an empty vector to hold equations
        eqs = Vector{Equation}(undef, 0)
        # Create another empty vector to hold the original equations (i.e no inputs)
        eqs_orig = Vector{Equation}(undef, 0)

        # Grab everything within the @model block and run it to populate mdl block, expand other macros etc. 
        $MdlEx




        if length(ivs) == 1
            conspairs = length(cons)>0 ? [Pair(cons[i].value, 
                            ModelingToolkit.getdefault(cons[i].value)) for i in 1:lastindex(cons)] : Pair{Symbolics.Num}[]
            parpairs = length(pars)> 0 ? [Pair(pars[i].value, 
                            ModelingToolkit.getdefault(pars[i].value)) for i in 1:lastindex(pars)] : Pair{Symbolics.Num}[]
            iputpairs = length(iputs)>0 ? [Pair(iputs[i].value, 
                            ModelingToolkit.getdefault(iputs[i].value)) for i in 1:lastindex(iputs)] : Pair{Symbolics.Num}[]
            consparpairs = vcat(conspairs, parpairs, iputpairs)

            varspairs = length(vars)>0 ? [Pair(vars[i].value, ModelingToolkit.getdefault(vars[i].value)) for i in 1:lastindex(vars)] : Pair{Symbolics.Num}[]
            obspairs = length(obs) > 0 ? [Pair(obs[i].value, ModelingToolkit.getdefault(obs[i].value)) for i in 1:lastindex(obs)] : Pair{Symbolics.Num}[]
            consin = [cons[i].value for i in 1:lastindex(cons)]
            parsin = [pars[i].value for i in 1:lastindex(pars)]
            varsin = [vars[i].value for i in 1:lastindex(vars)]
            iputsin = [iputs[i].value for i in 1:lastindex(iputs)]

            @named $Namegen = ODESystem(eqs, ivs[1], varsin, vcat(parsin, consin, iputsin), tspan=getmetadata(ivs[1],IVDomain))
            prob = ODEProblem($Namegen,[], getmetadata(ivs[1],IVDomain), consparpairs)
            mdl._odeproblem = prob
            mdl._sys = $Namegen
            mdl.parameters = ModelValues(names = [x.name for x in pars],
                                    _values = Dict(x.name => x for x in pars),
                                    _valmap = Dict(consparpairs),
                                    _uvalues = mdl._uvalues)
            mdl._constants = ModelValues(names = [x.name for x in cons],
                                        _values = Dict(x.name => x for x in cons),
                                        _valmap = Dict(conspairs),
                                        _uvalues = mdl._uvalues)

            mdl.states = ModelValues(names = [x.value.val.metadata[ModelingToolkit.VariableSource][2] for x in vars],
                                _values = Dict(x.name => x for x in vars),
                                _valmap = Dict(vcat(conspairs,parpairs,varspairs)),
                                _uvalues = mdl._uvalues)
            mdl.observed = ModelValues(names = [x.name for x in obs],
                                       _values = Dict(x.name => x for x in obs),
                                       _valmap = Dict(obspairs),
                                       _uvalues = mdl._uvalues)
            mdl._inputs = ModelValues(names = [x.name for x in iputs],
                                      _values = Dict(x.name => x for x in iputs),
                                      _valmap = Dict(iputpairs),
                                      _uvalues = mdl._uvalues)
            # println(getmetadata(ivs[1],IVDomain))
            mdl.tspan = getmetadata(ivs[1],IVDomain)

        else
            nothing
            # if length($bcs) == 0
                # error("Need to define boundary conditions for PDEs")
            # end
            # if length($domain) == 0
                # error("Need to define variable domain(s) for PDEs")
            # end
            # conspairs = [Pair(cons[i], consvals[i]) for i in 1:lastindex(cons)]
            # @named $Name = PDESystem(eqs, [], [], ivs, vars, vcat(pars,cons))
        end

        
        for ckey in keys(mdl._constants._values)
            c = mdl._constants._values[ckey]
            c._valmap = mdl._constants._valmap
            c._uvalues = mdl._uvalues
            c._defaultExpr = mdl._constants._values[ckey].value
            c._constant = true
        end
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
        for okey in keys(mdl.observed._values)
            o = mdl.observed._values[okey]
            o._valmap = mdl.observed._valmap
            o._uvalues = mdl._uvalues
            o._defaultExpr = mdl.observed._values[okey].value
        end
        for ikey in keys(mdl._inputs._values)
            i = mdl._inputs._values[ikey]
            i._valmap = mdl._inputs._valmap
            i._uvalues = mdl._uvalues
            i._defaultExpr = mdl._inputs._values[ikey].value
        end

        mdl.model = $Namegen # Return the model 
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
    ivs = Symbolics._parse_vars(:parameters,
        Real,
        ivs_in,
        ModelingToolkit.toparam)
    q_out = quote
        for ptmp in $ivs
            if !hasmetadata(ptmp, IVDomain)
                error("Timespan or domain must be provided for independent variable $ptmp")
            elseif typeof(getmetadata(ptmp, IVDomain)) != Tuple{Float64, Float64}
                error("Timespan or domain for independent variable $ptmp must be of type Tuple{Float64, Float64}")
            end
            push!(ivs, ptmp)
        end
        append!(mdl.independent_variables, $ivs)
    end
    return q_out
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

macro inputs(ins...)
    out = esc(Symbolics._parse_vars(:parameters,
    Real,
    ins,
    ModelingToolkit.toparam))

    q_out = quote 
        for input in $out
            if (ModelingToolkit.hasdefault(input))
                error("Input $input should not hve a default value")
            else
                input = ModelingToolkit.setdefault(input, 0.0)
                itmp = NumValue(name = Symbol(input), value = input, _valmap = Dict{Symbol, Num}(), _uvalues = Dict{Symbol, Real}(),_defaultExpr = Num(nothing))
                push!(iputs, itmp)
            end
        end
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
                ctmp = NumValue(name = Symbol(con), value = con, _valmap = Dict{Symbol, Num}(), _uvalues = Dict{Symbol, Real}(),_defaultExpr = Num(nothing))
                push!(cons, ctmp)
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
    return Symbol(a)
end


macro observed(obsin)
    out = ModelingToolkit._parse_vars(:parameters,
                    Real,
                    [obsin],
                    ModelingToolkit.toparam) |> esc

    q_out = quote
        for observ in $out
                # push!(obsnames, observ)

                obstmp = NumValue(name = Symbol(observ), value = observ, _valmap = Dict{Symbol, Num}(), _uvalues = Dict{Symbol, Real}(),_defaultExpr = Num(nothing))
                push!(obs, obstmp)
        end
        $obsin
    end
    return q_out
end




    
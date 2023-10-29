




struct IVDomain end
Symbolics.option_to_metadata_type(::Val{:location}) = VariableLoc
Symbolics.option_to_metadata_type(::Val{:domain}) = IVDomain
Symbolics.option_to_metadata_type(::Val{:tspan}) = IVDomain


vecpairReal = Union{Vector{Pair{Symbolics.Num,T1}} where {T1<:Real}, Vector{Pair{Symbolics.Num}}}
vecpairNum = Union{Vector{Pair{Symbolics.Num,T1}} where {T1<:Number},Vector{Pair{Symbolics.Num}}}

svecNumNumber = AbstractVector{Pair{Symbolics.Num, T}} where {T<:Number}

Base.@kwdef struct Constants

    values::Vector{Pair{Num, Union{Number,Num}}}
    sym_to_val::Base.ImmutableDict{Symbol, Int64}
    names::Tuple
end

Base.@kwdef struct Parameters{T1<:Vector{Pair{Num}},T2<:Base.ImmutableDict{Symbol, Int64},T3<:Tuple,T4<:AbstractVector{Pair{Symbolics.Num, Symbolics.Num}},T5<:Constants}
    values::T1
    sym_to_val::T2
    names::T3
    defaults::T4
    constants::T5
end

Base.@kwdef struct Inputs
    values::Vector{Pair{Num, Union{Number,Num}}}
    sym_to_val::Base.ImmutableDict{Symbol, Int64}
    names::Tuple
end


Base.@kwdef struct Variables{T1<:vecpairNum, T2<:Base.ImmutableDict{Symbol, Int64}, T3<:Tuple, T4<:svecNumNumber, T5<:Constants, T6<:Parameters}
    values::T1
    sym_to_val::T2
    names::T3
    defaults::T4
    constants::T5
    parameters::T6
end


Base.@kwdef struct Observed{T1<:vecpairNum,T2<:Base.ImmutableDict{Symbol, Int64},T3<:Tuple,T4<:Constants, T5<:Parameters}
    values::T1#MVector{Pair{Num, Union{Number,Num}}}
    sym_to_val::T2#Base.ImmutableDict{Symbol, Int64}
    names::T3#Tuple
    constants::T4
    parameters::T5
end

Base.@kwdef mutable struct PMModel
    const states::Variables
    const independent_variables::Vector{Num}
    tspan::Tuple{Float64, Float64} = (0.0, 1.0)
    const parameters::Parameters
    const equations::Vector{Equation}
    const _odeproblem::ODEProblem
    const _inputs::Inputs
    const observed::Observed
    const model::ModelingToolkit.AbstractSystem
end




macro model(Name, MdlEx)#, DerivativeSymbol, DefaultIndependentVariable, MdlEx, AdditionalIndepVars... = nothing)
    Namegen = gensym(Name)
    outexpr = quote # Create a quote to return our output expression
        # Create an empty array to hold all parameters
        pars = Num[]
        parsSymToNum = Dict{Symbol, Int64}()
        # Create an empty array to hold all variables 
        vars = Num[]
        varsSymToNum = Dict{Symbol, Int64}()
        # Create an empty array to hold all constants
        cons = Num[]
        consSymToNum = Dict{Symbol, Int64}()
        # Create an empty array to hold all observed
        obs = Num[]
        obsSymToNum = Dict{Symbol, Int64}()
        # Create an empty array to hold all inputs
        inputs = Num[]
        inputsSymToNum = Dict{Symbol, Int64}()


        # Create an empty array to hold the independent variables
        ivs = Num[]
        # Create an empty array to hold boundary conditions for PDESystems
        bcs = Num[]
        # Create an empty array to hold domains for PDESystems
        domain = Num[]
        # Create an empty PMModel object to hold our parameters, states, IVs, etc.
        
    

        # Create an empty vector to hold equations
        eqs = Vector{Equation}(undef, 0)

        # Create an empty vector to hold possible equation names
        eqnames = Vector{Union{Tuple{Expr}, Tuple{}}}(undef, 0)

        # Grab everything within the @model block and run it to populate mdl block, expand other macros etc. 
        $MdlEx

        eqsOrig = copy(eqs)
        eqinputmap = Dict{Symbol, Symbol}()

        # Generate hidden input variables for all equations/stats
        for (i, eq) in enumerate(eqs)
            lhs = eq.lhs
            extra_args = eqnames[i]
            if length(ModelingToolkit.arguments(lhs)) == 1
                eqname = getSymbolicName(ModelingToolkit.arguments(lhs)[1])
            elseif length(ModelingToolkit.arguments(lhs)) > 1
                if length(extra_args)==0
                    error("Cannot determine equation/state name automatically for $lhs. Please provide name using 'name = var' ")
                elseif !Meta.isexpr(extra_args[1],:(=))
                    earg = extra_args[1]
                    error("Do not recognize extra @eq argument $earg. Please provide name using 'name = var' ")
                elseif extra_args[1].args[1] != :name
                    earg = extra_args[1]
                    error("Do not recognize extra @eq argument $earg. Please provide name using 'name = var' ")
                elseif !isa(extra_args[1].args[2], Symbol)
                    println(typeof(extra_args[1].args[2]))
                    earg = extra_args[1]
                    error("Do not recognize extra @eq argument $earg. Please provide name using 'name = var' ")
                elseif length(extra_args) > 1
                    eargs = extra_args[2:end]
                    error("Additional kwargs, $eargs, not recognized")
                else
                    eqname = extra_args[1].args[2]
                end
            end
            symname = gensym("input_$eqname")

            unit = ModelingToolkit.get_unit(eq.lhs)
            symnameSymbol = Symbol(symname)

            ipvar_in = (:($symnameSymbol), :([unit = $unit]))
            ipvar = eval(Symbolics._parse_vars(:parameters,
                    Real,
                    ipvar_in,
                    ModelingToolkit.toparam))[1]
            push!(inputs, ipvar)
            # inputsSymToNum[getmetadata(ipvar,VariableSource)[2]] = length(inputs)
            inputsSymToNum[eqname] = length(inputs)
            eqinputmap[eqname] = symname
            eqs[i] = eq.lhs ~ eq.rhs + ipvar
        end


        # Build ModelConstants for constants
        if length(cons) > 0
            constantsMV = Constants(values = [Pair(con_i, con_i.val.metadata[Symbolics.VariableDefaultValue]) for con_i in cons],
                                    sym_to_val = Base.ImmutableDict([Pair(nm, consSymToNum[nm]) for nm in keys(consSymToNum)]...),
                                    names = tuple(collect(getSymbolicName(nm) for nm in cons)...))
        else
            constantsMV = Constants(values = Pair{Num,Number}[], sym_to_val = ImmutableDict{Symbol, Int64}(),  names = ())
        end

        # Build ModelValues for parameters
        if length(pars) > 0
            # println(Base.ImmutableDict([Pair(par_i, par_i.val.metadata[Symbolics.VariableDefaultValue]) for par_i in pars]...))
            # println(Base.ImmutableDict([Pair(par_i, par_i.val.metadata[Symbolics.VariableDefaultValue]) for par_i in pars]...))
            parametersMV = Parameters(values = [Pair(par_i, par_i.val.metadata[Symbolics.VariableDefaultValue]) for par_i in pars],
                                    sym_to_val = Base.ImmutableDict([Pair(nm, parsSymToNum[nm]) for nm in keys(parsSymToNum)]...),
                                    names = tuple(collect(getSymbolicName(nm) for nm in pars)...), constants = constantsMV,
                                    defaults = SVector([Pair(par_i, par_i.val.metadata[Symbolics.VariableDefaultValue]) for par_i in pars]...))
        else
            parametersMV = Parameters(values = Pair{Num,Number}[], sym_to_val = ImmutableDict{Symbol, Int64}(),  names = (), defaults = nothing)
        end


        ## SETUP Variables
        # Build ModelValue for inputs
        if length(inputs) == 0
            error("Must provide equations for all variables")
        end
        inputsMV = Inputs(values = [Pair(input_i, 0.0) for input_i in inputs],
                                    sym_to_val = Base.ImmutableDict([Pair(nm, inputsSymToNum[nm]) for nm in keys(inputsSymToNum)]...),
                                    names = tuple(collect(getSymbolicName(nm) for nm in inputs)...))
        variablesMV = Variables(values = [Pair(var_i, var_i.val.metadata[Symbolics.VariableDefaultValue]) for var_i in vars],
                                    sym_to_val = Base.ImmutableDict([Pair(nm, varsSymToNum[nm]) for nm in keys(varsSymToNum)]...),
                                    names = tuple(collect(getSymbolicName(nm) for nm in vars)...),
                                    defaults = SVector([Pair(var_i, var_i.val.metadata[Symbolics.VariableDefaultValue]) for var_i in vars]...),
                                    constants = constantsMV,
                                    parameters = parametersMV)


        # Get observed Variables
        if length(obs) > 0
            observedMV = Observed(values = [Pair(obs_i, obs_i.val.metadata[Symbolics.VariableDefaultValue]) for obs_i in obs],
                                            sym_to_val = Base.ImmutableDict([Pair(nm, obsSymToNum[nm]) for nm in keys(obsSymToNum)]...),
                                            names = tuple(collect(getSymbolicName(nm) for nm in obs)...),
                                            constants = constantsMV,
                                            parameters = parametersMV)
        else
            emptyParams = Parameters(values = Pair{Num,Number}[], sym_to_val = ImmutableDict{Symbol, Int64}(),  names = (), defaults = nothing)
            emptyConstants = Constants(values = Pair{Num,Number}[], sym_to_val = ImmutableDict{Symbol, Int64}(),  names = ())
            observedMV = Observed(values = Pair{Num,Number}[], sym_to_val = ImmutableDict{Symbol, Int64}(),  names = (), constants = emptyConstants, parameters = emptyParams)
        end

        ###############
        # BUILD SYSTEM
        ##############

        tspan = getmetadata(ivs[1],IVDomain)
        if length(ivs) == 1
            vin = [v.first for v in variablesMV.values]
            pin = [p.first for p in parametersMV.values]
            cin = [p.first for p in constantsMV.values]
            iin = [i.first for i in inputsMV.values]
            @named $Namegen = ODESystem(eqs, ivs[1], vin, vcat(pin, cin, iin), tspan=tspan)
            prob = ODEProblem(structural_simplify($Namegen),variablesMV.values, tspan, vcat(parametersMV.values, constantsMV.values, inputsMV.values))
        end

    mdl = PMModel(
        states = variablesMV,
        independent_variables = Vector{Num}(undef,0),
        tspan = tspan,
        parameters = parametersMV,
        equations = Equation[],
        _odeproblem = prob,
        _inputs =  inputsMV,
        observed =  observedMV,
        model = $Namegen
    )

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
    ivs = esc(Symbolics._parse_vars(:parameters,
        Real,
        ivs_in,
        ModelingToolkit.toparam))
    q_out = quote
        for ptmp in $ivs
            if !hasmetadata(ptmp, IVDomain)
                error("Timespan or domain must be provided for independent variable $ptmp")
            elseif typeof(getmetadata(ptmp, IVDomain)) != Tuple{Float64, Float64}
                error("Timespan or domain for independent variable $ptmp must be of type Tuple{Float64, Float64}")
            end
            push!(ivs, ptmp)
        end
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
        
                # ptmp = NumValue(name = Symbol(param), value = param, _valmap = Dict{Symbol, Num}(), _uvalues = Dict{Symbol, Real}(),_defaultExpr = Num(nothing))
                push!(pars, param)
                parsSymToNum[getmetadata(param,VariableSource)[2]] = length(pars)
            end
        end
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
                push!(cons, con)
                consSymToNum[getmetadata(con,VariableSource)[2]] = length(cons)
            end
        end
    end
    return q_out
end


macro eq(formula, extra...)
    quote
        push!(eqnames, $extra)
        push!(eqs, $formula)
    end
end


macro variables(xs...)
    out = esc(ModelingToolkit._parse_vars(:variables, Real, xs))
    q_out = quote
        for var in $out
            if !(ModelingToolkit.hasdefault(var))
                error("State $var must have an initial value")
            else
                push!(vars, var)
                varsSymToNum[getmetadata(var,VariableSource)[2]] = length(var)
            end
        end

    end
    return q_out
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
                push!(obs, observ)
                obsSymToNum[getmetadata(observ,VariableSource)[2]] = length(obs)
        end
        $obsin
    end
    return q_out
end



    
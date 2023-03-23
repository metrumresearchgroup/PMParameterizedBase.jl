using PMxSim
using OrdinaryDiffEq: ODEProblem, isinplace

function nonunique(x::AbstractArray{T}) where T
    xs = sort(x)
    duplicatedvector = T[]
    for i = 2:lastindex(xs)
        if (isequal(xs[i],xs[i-1]) && (length(duplicatedvector)==0 || !isequal(duplicatedvector[end], xs[i])))
            push!(duplicatedvector,xs[i])
        end
    end
    duplicatedvector
end

function variable_parameter_overlap(pnames, snames, pvec_symbol, svec_symbol)
    if pvec_symbol == svec_symbol
        error("Parameter and state vectors cannot share a name")
    end
    if !isempty(intersect(pnames, snames))
        overlap = (intersect(pnames, snames))
        # rete = string.("There are both parameters and states named: ", join(overlap,", "))
        error(string.("There are both parameters and states named ", join(overlap,", ", " and ")))
    end
end

function constant_parameter_overlap(mnames, pnames)
    if !isempty(intersect(mnames, pnames))
        overlap = intersect(pnames, mnames)
        @warn string.("Parameter(s) ", join(overlap,", ", " and ")," over-written by constants")
    end
end

function constant_state_overlap(mnames, snames)
    if !isempty(intersect(mnames, snames))
        overlap = intersect(mnames, snames)
        error(string.("There are both states and constants named ", join(overlap,", "," and ")))
    end
end

function variable_repeat(snames)
    repeated = join(nonunique(snames),", ", " and ")
    if length(repeated) > 0
        error("State(s) $repeated defined multiple times")
    end
end

function parameter_repeat(pnames)
    repeated = join(nonunique(pnames),", ", " and ")
    if length(repeated) > 0 
        error("Parameter(s) $repeated defined multiple times")
    end
end

function derivative_repeat(dnames)
    repeated = join(nonunique(dnames),", ", " and ")
    if length(repeated) > 0
        error("Derivative(s) $repeated defined multiple times")
    end
end

function derivative_exists(dnames, snames)
    missingD = Vector{Symbol}()
    missingS = Vector{Symbol}()
    for dn in dnames
        if dn ∉ snames
            push!(missingD, dn)
        end
    end
    missingDJoined = join(missingD,", ", " and ")
    if length(missingD) > 0
        error("Derivative(s) $missingDJoined do not correspond to defined states")
    end

    for sn in snames
        if sn ∉ dnames
            push!(missingS, sn)
        end
    end
    missingSJoined = join(missingS,", ", " and ")
    if length(missingS) > 0
        error("No derivative provided for states(s) $missingSJoined")
    end
end

    


function parameter_vec_rename(pnames, pvec_symbol)
    if any(pnames .== pvec_symbol)
        overlap = findall(pnames .== pvec_symbol)
        overlap = join(overlap,", ", " and ")
        error("Parameter $overlap shares a name with the input parameter vector")
    end
end

function checkArgs(args,kwargs)
    if (length(args)) < 4
        if length(args)>0
            error(string.("Missing arguments. Function call should include (du, u, p, t; kwargs), only. Current arguments: ", join(args, ", "," and")))
        else
            error("No arguments provided. Function call should be (du, u, p, t)")
        end
    elseif (length(args)) > 4
        error(string.("Too many arguments. Function call should include (du, u, p, t), only. Current arguments: ", join(args, ", "," and"), ". Please separate kwargs with a ';'"))
    end
end

function removeDefs(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@init")
        return nothing
    else
        return x
    end
end

function checkDefs(x)
    if isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@parameter")
        error("@parameter definiton outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@variable")
        error("@variable definition outside of @init")
    elseif isexpr(x) && x.head == :macrocall && x.args[1] == Symbol("@constant")
        error("@constant definition outside of @init")
    end
    return x
end

        
function walkDefs(modfn)
    out = MacroTools.postwalk(x -> removeDefs(x), modfn)
    println(out)
    MacroTools.postwalk(x -> checkDefs(x), out)
end


